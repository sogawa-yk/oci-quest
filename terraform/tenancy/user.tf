locals {
  members = jsondecode(base64decode(var.members_file))

  flattened_members = flatten([
    for team in local.members.teams : [
      for email in team.members : {
        team_name  = team.name
        email      = email
      }
    ]
  ])

  member_map = {
    for member in local.flattened_members :
    split("@", member.email)[0] => {
      team_name = member.team_name
      email     = member.email
    }
  }
}

resource "oci_identity_user" "users" {
  for_each = local.member_map

  name           = each.key
  email          = each.value.email
  description    = "${each.value.team_name} - ${each.key}"
  compartment_id = oci_identity_compartment.teams[each.value.team_name].id
}
