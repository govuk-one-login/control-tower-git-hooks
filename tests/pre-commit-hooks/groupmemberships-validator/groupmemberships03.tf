module "groupmemberships" {
  source            = "sourceLocation"
  members = {
    "membership1" = {
      group_id  = module.groups.group_details["group01"].group_id,
      member_id = module.users.user_details["user01@example.com"].user_id
    }
    "membership2" = {
      group_id  = module.groups.group_details["group02"].group_id,
      member_id = module.users.user_details["user02@example.com"].user_id
    }
    "membership3" = {
      member_id = module.users.user_details["user01@example.com"].user_id,
      group_id  = module.groups.group_details["group01"].group_id
    }
  }
}