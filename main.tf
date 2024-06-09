terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = "~> 1.5"
}

provider "aws" {
  alias = "management"
  # Use "aws configure" to create the "management" profile with the Management account credentials
  profile = "management"
}

provider "aws" {
  alias = "audit"
  # Use "aws configure" to create the "audit" profile with the Audit account credentials
  profile = "audit"
}

data "aws_caller_identity" "audit" {
  provider = aws.audit
}

data "aws_organizations_organization" "this" {
  provider = aws.management
}

locals {
  enabler_resource_types = compact([
    var.enable_ec2 ? "EC2" : null,
    var.enable_ecr ? "ECR" : null,
    var.enable_lambda ? "LAMBDA" : null,
    var.enable_lambda_code && var.enable_lambda ? "LAMBDA_CODE" : null,
  ])

  member_account_ids = [for account in data.aws_organizations_organization.this.accounts : account.id if account.status == "ACTIVE" && account.id != data.aws_caller_identity.audit.account_id]
}

resource "aws_inspector2_enabler" "audit" {
  provider       = aws.audit
  account_ids    = [data.aws_caller_identity.audit.account_id]
  resource_types = local.enabler_resource_types
}

resource "aws_inspector2_delegated_admin_account" "audit" {
  provider   = aws.management
  account_id = data.aws_caller_identity.audit.account_id
  depends_on = [aws_inspector2_enabler.audit]
}

resource "aws_inspector2_organization_configuration" "this" {
  provider = aws.audit
  auto_enable {
    ec2         = var.enable_ec2
    ecr         = var.enable_ecr
    lambda      = var.enable_lambda
    lambda_code = var.enable_lambda_code && var.enable_lambda
  }
  depends_on = [aws_inspector2_delegated_admin_account.audit]
}

resource "aws_inspector2_member_association" "members" {
  provider   = aws.audit
  for_each   = toset(local.member_account_ids)
  account_id = each.key
  depends_on = [aws_inspector2_delegated_admin_account.audit]
}

resource "aws_inspector2_enabler" "members" {
  provider       = aws.audit
  for_each       = toset(local.member_account_ids)
  account_ids    = [each.key]
  resource_types = local.enabler_resource_types
  depends_on     = [aws_inspector2_member_association.members]
}
