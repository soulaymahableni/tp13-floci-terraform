# TP13 : réponses aux questions

## Partie 2 : valeur de `AWS_ENDPOINT_URL` dans Compose

**`http://floci:4566`**. Dans le réseau Compose, chaque conteneur a son propre `localhost`. `http://localhost:4566` désignerait donc le conteneur `sdk-demo` lui-même, où rien n'écoute. Le DNS interne de Compose résout le **nom du service** (`floci`) vers l'IP du conteneur Floci, sur son port interne 4566. Le mapping `4566:4566` ne sert qu'à l'accès depuis l'hôte (AWS CLI, Terraform).

## Partie 3 : options de `providers.tf`

| Option | Rôle | Pourquoi avec Floci |
|---|---|---|
| `skip_credentials_validation` | Ne pas appeler `sts:GetCallerIdentity` pour valider les clés au démarrage | Les clés `test/test` sont fictives |
| `skip_metadata_api_check` | Ne pas interroger le service de métadonnées EC2 (169.254.169.254) | On n'est pas sur une instance EC2 : évite un délai d'attente |
| `skip_requesting_account_id` | Ne pas demander l'Account ID via IAM/STS | Évite des appels inutiles ; l'ID est simulé |
| `skip_region_validation` | Accepter n'importe quel nom de région | Pas de vérification réseau contre la liste AWS |
| `s3_use_path_style` | URL `http://localhost:4566/bucket` au lieu de `http://bucket.localhost:4566` | Le style « virtual host » demande un sous-domaine DNS par bucket, non résolu en local |
| bloc `endpoints` | Redirige chaque API (s3, sqs, dynamodb, secretsmanager, lambda, iam, sts) vers Floci | Sans lui, le provider appellerait les vrais endpoints `*.amazonaws.com` |

Les identifiants ne sont pas écrits dans le code : ils viennent du profil `floci` (`profile = var.aws_profile`). Ça évite aussi l'alerte Checkov sur les clés en dur.

## Partie 3 : comportement face à la dérive (drift)

Après `aws dynamodb delete-table --table-name tp13-visits-dev`, `terraform plan` commence par un **refresh** : il interroge l'API pour chaque ressource du state. La table n'existe plus, donc Terraform la retire de sa vision de l'existant et affiche :

* `Note: Objects have changed outside of Terraform` (la table a été supprimée) ;
* `# aws_dynamodb_table.visits will be created` → `Plan: 1 to add, 0 to change, 0 to destroy`.

Terraform est **déclaratif** : il compare l'état voulu (code) à l'état réel et propose de recréer la table. Un `terraform apply` corrige la dérive. Les données de la table supprimée, elles, sont perdues : Terraform ne gère que l'infrastructure, pas son contenu.

## Partie 4 : `moved` / `terraform state mv`

Changer l'adresse d'une ressource (`aws_s3_bucket.uploads` → `module.uploads.aws_s3_bucket.this`) donnerait sinon un plan « détruire l'ancienne + créer la nouvelle », et donc la perte du bucket et de son contenu. Le bloc `moved` (déclaratif, versionné, relu en revue de code) ou `terraform state mv` (commande impérative, une fois) renomme seulement l'entrée dans le state. Le plan affiche `has moved to` avec `0 to destroy`.

## Partie 4 : pourquoi un state distant verrouillé

* **Partage** : toute l'équipe et la CI travaillent sur le même state, et pas sur une copie locale.
* **Sauvegarde** : bucket versionné, donc on peut restaurer une version précédente du state.
* **Verrou** : `use_lockfile` crée `terraform.tfstate.tflock` par une écriture conditionnelle S3. Un second `plan` ou `apply` échoue avec `Error acquiring the state lock` au lieu d'écraser le state en parallèle. Alternative : la table DynamoDB (`LockID`).
* **Sécurité** : le state contient les secrets en clair (ici `api_key` dans `aws_secretsmanager_secret_version`). D'où `encrypt = true`, un bucket non public, un accès restreint, et jamais de `terraform.tfstate` dans Git.

## Partie 4 : clé par environnement vs workspaces

| Critère | Une clé par environnement (`-backend-config="key=envs/prod/…"`) | Workspaces (`terraform workspace select prod`) |
|---|---|---|
| Emplacement du state | `envs/dev/…`, `envs/prod/…` : lisible | `env:/prod/envs/dev/terraform.tfstate` : préfixe imposé |
| Isolation | Forte : on peut mettre un bucket, un compte ou des droits IAM différents par env | Faible : même backend, mêmes droits pour tous les envs |
| Risque d'erreur | Il faut penser au `-reconfigure` | Il faut penser au `workspace select` ; l'env courant est peu visible |
| Variables | `-var-file=prod.tfvars` | `terraform.workspace` utilisable dans le code |
| Usage conseillé | Environnements durables (dev/staging/prod), prod isolée | Copies temporaires et identiques (branche de feature, test) |

**Conclusion** : clés séparées (ou Terragrunt, qui les génère) pour dev/staging/prod ; workspaces pour les environnements éphémères.

## Partie 5 : scan IaC

* Code nominal : Checkov `Failed checks: 0`. Les exceptions non pertinentes en lab (KMS client, logs d'accès, réplication, rotation…) sont justifiées par `#checkov:skip=…`.
* Avec `mauvaise-config.tf` : Checkov signale 11 échecs, dont `CKV_AWS_53/54/55/56` (accès public), `CKV2_AWS_6`, `CKV_AWS_21` (versioning) et `CKV_AWS_145` (chiffrement). Trivy signale 5 problèmes HIGH : `AWS-0086`, `AWS-0087`, `AWS-0091`, `AWS-0093` (accès public) et `AWS-0132` (pas de chiffrement). Sur le code nominal, la seule exception Trivy est `AWS-0132` (SSE-S3 au lieu d'une clé KMS client), justifiée par `#trivy:ignore`. Code retour **1**, donc le pipeline Jenkins/GitHub Actions s'arrête.

## Partie 5 : Terraform vs OpenTofu

| Critère | Terraform (HashiCorp/IBM) | OpenTofu (Linux Foundation) |
|---|---|---|
| Licence | BSL 1.1 depuis la v1.6 (2023) : pas libre au sens OSI | MPL 2.0 : open source (fork de Terraform 1.5) |
| Providers | Registre `registry.terraform.io` | Registre `registry.opentofu.org`, mêmes providers (`hashicorp/aws`…) |
| Code HCL | Référence | Compatible : même projet, mêmes commandes (`tofu init/plan/apply`) |
| State | Format JSON | Format compatible ; migration possible dans les deux sens (avec précautions sur les versions récentes) |
| Fonctionnalités propres | HCP Terraform, Stacks… | **Chiffrement du state côté client** (bloc `encryption`, depuis 1.7), `for_each` sur les providers, variables dans le bloc backend… |

Dans ce TP, le même code s'applique sans modification avec `tofu`.

## Comparaison Floci / LocalStack / AWS réel

| Critère | Floci | LocalStack (Community) | AWS réel |
|---|---|---|---|
| Licence | MIT, libre | Jeton d'authentification exigé depuis mars 2026 ; fonctions avancées dans les offres payantes | Service propriétaire |
| Services couverts | Principaux services (S3, SQS, DynamoDB, Lambda, Secrets Manager, IAM, STS…) | Catalogue large, plus riche en version payante | Tous les services et toutes les options |
| Fidélité | Émulation : comportements simplifiés (IAM peu ou pas appliqué, KMS, quotas, erreurs, latence) | Bonne sur les services courants, quelques écarts | Référence (100 %) |
| Coût | Gratuit, local, aucune carte bancaire | Gratuit avec compte et jeton, ou payant | Paiement à l'usage, risque de facture en cas d'oubli |
| Usage en CI | Idéal : un conteneur léger, sans secret ni compte | Possible, mais le jeton est à gérer comme un secret dans la CI | Tests d'intégration finaux et pré-production, avec un compte dédié et des droits limités |

**Bilan** : Floci convient pour apprendre et pour les tests rapides en CI (gratuit, sans risque). LocalStack offre une couverture plus large mais demande désormais un compte. AWS réel reste indispensable pour valider IAM, les quotas, la sécurité et les performances avant la production.

## Remarques pour le rendu

* Verrou : préciser si `use_lockfile` a fonctionné avec Floci ou s'il a fallu basculer sur `dynamodb_table`.
* Le secret est passé par `TF_VAR_api_key` ; aucun `.tfvars` ne contient de secret.

## Résultat du test de verrou
Le verrou natif S3 (`use_lockfile = true`) fonctionne avec Floci : le second `terraform plan` a échoué avec `Error acquiring the state lock` (HTTP 412 PreconditionFailed). L'alternative DynamoDB n'a pas été nécessaire.
