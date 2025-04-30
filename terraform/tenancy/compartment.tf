locals {
    members_data = jsondecode(base64decode(var.members_file))

    # チーム情報をマッピング（ユニークなキーに変換）
    team_map = {
    for team in local.members_data.teams :
    team.name => {
        description = team.description
    }
    }
}


resource "oci_identity_compartment" "teams" {
    for_each = local.team_map

    name           = each.key
    description    = each.value.description
    compartment_id = var.tenancy_ocid  # ルートコンパートメントの下に作成
    enable_delete  = true              # 削除可能（任意）
}
