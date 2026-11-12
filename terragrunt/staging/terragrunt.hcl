include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  message_retention_seconds = 345600
}
