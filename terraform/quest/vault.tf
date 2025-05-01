resource "oci_kms_vault" "mushop_vault" {
  #Required
  compartment_id = var.compartment_ocid
  display_name   = "mushop_vault"
  vault_type     = "DEFAULT"
}

resource "oci_kms_key" "mushop_key" {
  compartment_id = var.compartment_ocid
  display_name   = "mushop_key"
  key_shape {
    algorithm = "AES"
    length    = 256
  }
  management_endpoint = oci_kms_vault.mushop_vault.management_endpoint
}
