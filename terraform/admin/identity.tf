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
  
  team_map = {
    for team in local.members.teams :
    team.name => {
        description = team.description
    }
    }
}

resource "oci_identity_compartment" "teams" {
    for_each = local.team_map

    name           = each.key
    description    = each.value.description
    compartment_id = var.tenancy_ocid 
    enable_delete  = true              
}

resource "oci_identity_user" "users" {
  for_each = local.member_map

  name           = each.key
  email          = each.value.email
  description    = "${each.value.team_name} - ${each.key}"
  compartment_id = var.tenancy_ocid
}

resource "oci_identity_group" "teams" {
  for_each = local.team_map

  name        = each.key
  description = "Group for ${each.key}"
  compartment_id = var.tenancy_ocid
}

resource "oci_identity_user_group_membership" "test_user_group_membership" {
  for_each = local.member_map
  user_id = oci_identity_user.users[each.key].id
  group_id = oci_identity_group.teams[each.value.team_name].id
}

resource "oci_identity_policy" "team_access" {
  for_each = local.team_map

  name           = "policy_${each.key}" 
  description    = "Allow ${each.key} group to manage all-resources in compartment ${each.key}"
  compartment_id = var.tenancy_ocid  

  statements = [
    "Allow group ${each.key} to manage all-resources in compartment ${each.key}"
  ]
}
