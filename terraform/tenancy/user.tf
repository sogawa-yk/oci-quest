locals {
  # フラットなユーザーリストを作成（usernameをユニークキーとして利用）
  users = {
    for team in var.teams :
    for member in team.members :
    "${member.username}" => {
      name        = member.username
      description = "User ${member.full_name} from ${team.name} as ${member.role}"
      email       = member.email
    }
  }
}

resource "oci_identity_user" "users" {
  for_each = local.users

  compartment_id = var.tenancy_ocid
  name           = each.value.name
  description    = each.value.description
  email          = each.value.email

}