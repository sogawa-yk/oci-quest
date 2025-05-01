terraform {
  required_version = "~> 1.2.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.27.0"
    }
  }
}
