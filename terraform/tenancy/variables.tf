### Terraform OCI Provider
variable "region" {
}

variable "tenancy_ocid" {
}

variable "members_file" {
  type = string
  description = "Base64 encoded JSON string"
}


variable "teams" {
  description = "List of teams and their members"
  type = list(object({
    name        = string
    description = string
    members     = list(object({
      username   = string
      full_name  = string
      email      = string
      role       = string
    }))
  }))
}

variable "compartment_ocid" {
}


