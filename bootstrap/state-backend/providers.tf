provider "aws" {
  region = var.region

  # Refuses to run against any other account, whatever credentials are active.
  allowed_account_ids = [var.account_id]

  default_tags {
    tags = {
      Project     = "aws-terraform-stacks"
      Environment = "shared"
      Stack       = "state-backend"
      Owner       = "platform"
      CostCenter  = "engineering"
      ManagedBy   = "terraform"
      Repository  = "github.com/JMbogning/aws-terraform-stacks"
    }
  }
}
