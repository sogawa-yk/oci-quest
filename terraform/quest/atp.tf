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


resource "oci_database_management_autonomous_database_autonomous_database_dbm_features_management" "mushop_dbm" {
  #Required
  autonomous_database_id                 = oci_database_autonomous_database.mushop_atp.id
  enable_autonomous_database_dbm_feature = true

  #Optional
  feature_details {
    #Required
    feature = "ALL"

    #Optional
    database_connection_details {

      #Optional
      connection_credentials {

        #Optional
        credential_name    = var.autonomous_database_autonomous_database_dbm_features_management_feature_details_database_connection_details_connection_credentials_credential_name
        credential_type    = var.autonomous_database_autonomous_database_dbm_features_management_feature_details_database_connection_details_connection_credentials_credential_type
        password_secret_id = oci_vault_secret.test_secret.id
        role               = var.autonomous_database_autonomous_database_dbm_features_management_feature_details_database_connection_details_connection_credentials_role
        ssl_secret_id      = oci_vault_secret.test_secret.id
        user_name          = oci_identity_user.test_user.name
      }
      connection_string {

        #Optional
        connection_type = "PE"
        port            = "1521"
        protocol        = "TCPS"
        service         = "questdevpdb_high"
      }
    }
    connector_details {

      #Optional
      connector_type        = var.autonomous_database_autonomous_database_dbm_features_management_feature_details_connector_details_connector_type
      database_connector_id = oci_database_management_database_connector.test_database_connector.id
      management_agent_id   = oci_management_agent_management_agent.test_management_agent.id
      private_end_point_id  = oci_database_management_private_end_point.test_private_end_point.id
    }
  }
}

resource "oci_database_management_db_management_private_endpoint" "mushop_dbm_private_endpoint" {
  #Required
  compartment_id = var.compartment_ocid
  name           = "DBM-Private-Endpoint"
  subnet_id      = oci_core_subnet.mushop_db_subnet.id
}
