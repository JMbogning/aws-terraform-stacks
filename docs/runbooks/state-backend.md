# State backend runbook

Procedures for the state bucket created by [bootstrap/state-backend](../../bootstrap/state-backend). Commands run from the repository root, with the bucket name in a variable:

```bash
bucket=$(terraform -chdir=bootstrap/state-backend output -raw bucket_name)
```

## Restore a previous version of a state file

Use this when a state file is corrupted, or when resources disappeared from it after a faulty operation.

1. Make sure nobody is running Terraform on the stack.
2. List the versions of the state file, newest first:

   ```bash
   key=dev/network/terraform.tfstate
   aws s3api list-object-versions --bucket "$bucket" --prefix "$key" \
     --query "Versions[?Key=='$key'].[VersionId,LastModified,Size]" --output table
   ```

3. Download the version to restore and check its content:

   ```bash
   aws s3api get-object --bucket "$bucket" --key "$key" --version-id <version-id> restored.tfstate
   jq '.serial, (.resources | length)' restored.tfstate
   ```

4. Copy it over the current version. The faulty version stays available as a previous version:

   ```bash
   aws s3api copy-object --bucket "$bucket" --key "$key" --copy-source "$bucket/$key?versionId=<version-id>"
   rm restored.tfstate
   ```

5. Run `make plan STACK=dev/network`. The plan shows the differences between the restored state and the real infrastructure.

## Release a stale lock

A run that was interrupted can leave a lock file (`<key>.tflock`). Terraform then fails with `Error acquiring the state lock` and prints the lock ID.

1. Check the `Who` and `Created` fields of the error, and make sure that run has really stopped.
2. Release the lock:

   ```bash
   terraform -chdir=environments/dev/network force-unlock <lock-id>
   ```

## Recover the bootstrap state

Use this when `bootstrap/state-backend/terraform.tfstate` is lost. The bucket and the key keep working: only Terraform's record of them is missing.

1. Find the key ID:

   ```bash
   aws kms describe-key --key-id alias/ats-tfstate --query KeyMetadata.KeyId --output text
   ```

2. Create `bootstrap/state-backend/imports.tf`. Only the key ID has to be filled in: the other IDs are derived from the configuration.

   ```hcl
   import {
     to = aws_kms_key.state
     id = "<key-id>"
   }

   import {
     to = aws_kms_alias.state
     id = "alias/${var.name}-tfstate"
   }

   import {
     to = aws_s3_bucket.state
     id = local.bucket_name
   }

   import {
     to = aws_s3_bucket_ownership_controls.state
     id = local.bucket_name
   }

   import {
     to = aws_s3_bucket_public_access_block.state
     id = local.bucket_name
   }

   import {
     to = aws_s3_bucket_versioning.state
     id = local.bucket_name
   }

   import {
     to = aws_s3_bucket_server_side_encryption_configuration.state
     id = local.bucket_name
   }

   import {
     to = aws_s3_bucket_lifecycle_configuration.state
     id = local.bucket_name
   }

   import {
     to = aws_s3_bucket_policy.state
     id = local.bucket_name
   }
   ```

3. Import, then remove the file:

   ```bash
   terraform -chdir=bootstrap/state-backend plan -out=tfplan
   terraform -chdir=bootstrap/state-backend apply tfplan
   rm bootstrap/state-backend/imports.tf
   ```

   The plan must show 9 resources to import and none to add or destroy.
