// SDK JavaScript v3 contre Floci.
// Local  : npm start                       (endpoint http://localhost:4566)
// SQS    : QUEUE_URL=$QURL npm start       (ou QUEUE_NAME=tp13-demo npm start)
// Compose: AWS_ENDPOINT_URL=http://floci:4566 (nom du service dans le réseau Compose)
import {
  S3Client,
  CreateBucketCommand,
  PutObjectCommand,
  ListObjectsV2Command,
} from "@aws-sdk/client-s3";
import {
  SQSClient,
  GetQueueUrlCommand,
  SendMessageCommand,
} from "@aws-sdk/client-sqs";

const endpoint = process.env.AWS_ENDPOINT_URL ?? "http://localhost:4566";
const region = process.env.AWS_REGION ?? "us-east-1";
const credentials = {
  accessKeyId: process.env.AWS_ACCESS_KEY_ID ?? "test",
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY ?? "test",
};
const bucket = process.env.BUCKET ?? "tp13-demo";

const s3 = new S3Client({ endpoint, region, credentials, forcePathStyle: true });
// useQueueUrlAsEndpoint=false : on garde l'endpoint configuré même si l'URL de
// la file renvoyée par Floci contient "localhost" (utile dans Compose).
const sqs = new SQSClient({ endpoint, region, credentials, useQueueUrlAsEndpoint: false });

console.log(`Endpoint : ${endpoint}`);

// 1. S'assurer que le bucket existe (utile dans Compose où rien n'est créé)
try {
  await s3.send(new CreateBucketCommand({ Bucket: bucket }));
  console.log(`Bucket ${bucket} créé`);
} catch (err) {
  if (!["BucketAlreadyOwnedByYou", "BucketAlreadyExists"].includes(err.name)) throw err;
}

// 2. Écrire deux objets
for (const key of ["sdk/hello.json", `sdk/run-${Date.now()}.txt`]) {
  await s3.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: JSON.stringify({ from: "sdk-demo", at: new Date().toISOString() }),
      ContentType: "application/json",
    }),
  );
  console.log(`Objet écrit : s3://${bucket}/${key}`);
}

// 3. Lister les objets
const list = await s3.send(new ListObjectsV2Command({ Bucket: bucket }));
console.log(`\nObjets dans ${bucket} :`);
for (const obj of list.Contents ?? []) {
  console.log(`  - ${obj.Key} (${obj.Size} o)`);
}

// 4. TODO complété : envoyer un message JSON dans la file SQS
let queueUrl = process.env.QUEUE_URL;
if (!queueUrl && process.env.QUEUE_NAME) {
  ({ QueueUrl: queueUrl } = await sqs.send(
    new GetQueueUrlCommand({ QueueName: process.env.QUEUE_NAME }),
  ));
}

if (queueUrl) {
  const body = { event: "sdk-demo", objects: list.KeyCount ?? 0, at: new Date().toISOString() };
  const res = await sqs.send(
    new SendMessageCommand({ QueueUrl: queueUrl, MessageBody: JSON.stringify(body) }),
  );
  console.log(`\nMessage SQS envoyé (MessageId=${res.MessageId}) :`, body);
  console.log(`Lire avec : aws sqs receive-message --queue-url ${queueUrl}`);
} else {
  console.log("\n(QUEUE_URL ou QUEUE_NAME non défini : pas d'envoi SQS)");
}
