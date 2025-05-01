resource "oci_database_autonomous_database" "mushop_atp" {
  compartment_id          = var.compartment_ocid
  display_name            = format("%s-mushop-db", var.team_name)
  db_name                 = format("%spdb", var.team_name)
  db_version              = "19c"
  db_workload             = "OLTP"
  compute_count           = 2
  compute_model           = "ECPU"
  data_storage_size_in_gb = 20
  admin_password          = var.database_password
  subnet_id               = oci_core_subnet.mushop_db_subnet.id
}

resource "oci_database_autonomous_database_wallet" "mushop_wallet" {
  autonomous_database_id = oci_database_autonomous_database.mushop_atp.id
  password               = var.database_password
  generate_type          = "SINGLE"
  base64_encode_content  = true
}
