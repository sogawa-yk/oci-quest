resource "oci_identity_compartment" "test_compartment" {
    #Required
    compartment_id = var.tenancy_ocid
    description = "for test"
    name = var.team_name
}