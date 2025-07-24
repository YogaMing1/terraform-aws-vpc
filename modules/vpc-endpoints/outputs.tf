module "kms_in_modules" {
  source  = "terraform-aws-modules/kms/aws"
  version = "2.1.0" # Note - be mindful of Terraform/provider version compatibility between modules

  create = local.create && var.create_kms_key && local.enable_cluster_encryption_config # not valid on Outposts

  description             = coalesce(var.kms_key_description, "${var.cluster_name} cluster encryption key")
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.enable_kms_key_rotation

  # Policy
  enable_default_policy     = var.kms_key_enable_default_policy
  key_owners                = var.kms_key_owners
  key_administrators        = coalescelist(var.kms_key_administrators, [try(data.aws_iam_session_context.current[0].issuer_arn, "")])
  key_users                 = concat([local.cluster_role], var.kms_key_users)
  key_service_users         = var.kms_key_service_users
  source_policy_documents   = var.kms_key_source_policy_documents
  override_policy_documents = var.kms_key_override_policy_documents

  # Aliases
  aliases = var.kms_key_aliases
  computed_aliases = {
    # Computed since users can pass in computed values for cluster name such as random provider resources
    cluster = { name = "eks/${var.cluster_name}" }
  }

  tags = merge(
    { terraform-aws-modules = "eks" },
    var.tags,
  )
}

output "endpoints" {
  description = "Array containing the full resource object and attributes for all endpoints created"
  value       = aws_vpc_endpoint.this
}

################################################################################
# Security Group
################################################################################

output "security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = try(aws_security_group.this[0].arn, null)
}

output "security_group_id" {
  description = "ID of the security group"
  value       = try(aws_security_group.this[0].id, null)
}
