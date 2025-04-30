locals {
  members = jsondecode(base64decode(var.members_file))
}

locals {
  members = jsondecode(base64decode(var.members_file))

  flattened_members = flatten([
    for team in local.members.teams : [
      for member in team.members : {
        team_name  = team.name
        username   = member.username
        full_name  = member.full_name
        email      = member.email
        role       = member.role
      }
    ]
  ])

  member_map = {
    for member in local.flattened_members :
    member.username => {
      team_name  = member.team_name
      full_name  = member.full_name
      email      = member.email
      role       = member.role
    }
  }
}

resource "oci_identity_user" "users" {
  for_each = local.member_map

  name           = each.key
  email          = each.value.email
  description    = each.value.description
  compartment_id = var.tenancy_ocid
}
