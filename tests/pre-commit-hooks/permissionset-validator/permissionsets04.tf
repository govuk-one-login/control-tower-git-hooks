module "permission_sets_module_01" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  source             = "./modules/permissionSets"
  name               = "permission-set-01"
  description        = "Permission set 1"
  inline_policy      = ""
  managed_policy_arn = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  account_assignments = {
    "assignment01" = {
      account_id     = "123456789012"
      principal_id   = data.aws_identitystore_group.group01.id
      principal_type = "GROUP"
    }
    "assignment02" = {
      account_id     = "223456789012"
      principal_id   = data.aws_identitystore_group.group01.id
      principal_type = "GROUP"
    }
  }
}
module "permission_sets_module_02" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  source             = "./modules/permissionSets"
  name               = "permission-set-02"
  description        = "Permission set 02"
  inline_policy      = ""
  managed_policy_arn = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  account_assignments = {
    "assignment01" = {
      account_id     = "123456789012"
      principal_id   = data.aws_identitystore_group.group01.id
      principal_type = "GROUP"
    }
    "assignment02" = {
      account_id     = "223456789012"
      principal_id   = data.aws_identitystore_group.group01.id
      principal_type = "GROUP"
    }
  }
}
