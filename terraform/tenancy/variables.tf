### Terraform OCI Provider
variable "region" {
}

variable "tenancy_ocid" {
}

variable "user_emails" {
  type = list(string)
  description = "作成するユーザーのメールアドレス一覧"
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


