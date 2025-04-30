locals {
  members = jsondecode(base64decode(var.members_file))
}

resource "oci_identity_user" "users" {
  for_each = {
    for team in local.members.teams, member in team.members :
    member.username => {
      email       = member.email
      description = "User ${member.full_name} from ${team.name} (${member.role})"
    }
  }

  name           = each.key
  email          = each.value.email
  description    = each.value.description
  compartment_id = var.tenancy_ocid
}
