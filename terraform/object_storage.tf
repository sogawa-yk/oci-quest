data "oci_objectstorage_namespace" "mushop_namespace" {
  compartment_id = var.compartment_ocid
}

locals {
  namespace = data.oci_objectstorage_namespace.mushop_namespace.namespace
  mushop_media_pars = join(",", [for media in oci_objectstorage_preauthrequest.mushop_media_pars_preauth :
  format("https://objectstorage.%s.oraclecloud.com%s", var.region, media.access_uri)])
  mushop_media_pars_list = templatefile("${path.module}/scripts/mushop_media_pars_list.txt",
    {
      content = local.mushop_media_pars
  })
}

resource "oci_objectstorage_bucket" "mushop" {
  compartment_id = var.compartment_ocid
  name           = format("%s-mushop", var.team_name)
  namespace      = local.namespace
}

resource "oci_objectstorage_object" "mushop_wallet" {
  bucket    = oci_objectstorage_bucket.mushop.name
  content   = oci_database_autonomous_database_wallet.mushop_wallet.content
  namespace = local.namespace
  object    = "mushop_atp_wallet"
}
resource "oci_objectstorage_preauthrequest" "mushop_wallet_preauth" {
  access_type  = "ObjectRead"
  bucket       = oci_objectstorage_bucket.mushop.name
  name         = format("%s-mushop-wallet-preauth", var.team_name)
  namespace    = local.namespace
  time_expires = timeadd(timestamp(), "30m")
  object_name  = oci_objectstorage_object.mushop_wallet.object
}

resource "null_resource" "download_tar" {
  provisioner "local-exec" {
    command = format("curl -o /tmp/mushop-basic.tar.xz https://github.com/oracle-japan/oci-quest/releases/download/%s/mushop-basic.tar.xz", file("${path.module}/VERSION"))
  }
}

resource "oci_objectstorage_object" "mushop_basic" {
  bucket       = oci_objectstorage_bucket.mushop.name
  namespace    = local.namespace
  object       = "mushop_basic"
  source       = "/tmp/mushop-basic.tar.xz"
  content_type = "application/x-xz"
  depends_on   = [null_resource.download_tar]
}
resource "oci_objectstorage_preauthrequest" "mushop_lite_preauth" {
  access_type  = "ObjectRead"
  bucket       = oci_objectstorage_bucket.mushop.name
  name         = format("%s-mushop-lite-preauth", var.team_name)
  namespace    = local.namespace
  time_expires = timeadd(timestamp(), "30m")
  object_name  = oci_objectstorage_object.mushop_basic.object
}

resource "oci_objectstorage_object" "mushop_media_pars_list" {
  bucket    = oci_objectstorage_bucket.mushop.name
  content   = local.mushop_media_pars_list
  namespace = local.namespace
  object    = "mushop_media_pars_list.txt"
}
resource "oci_objectstorage_preauthrequest" "mushop_media_pars_list_preauth" {
  access_type  = "ObjectRead"
  bucket       = oci_objectstorage_bucket.mushop.name
  name         = format("%s-mushop_media_pars_list_preauth", var.team_name)
  namespace    = local.namespace
  time_expires = timeadd(timestamp(), "30m")
  object_name  = oci_objectstorage_object.mushop_media_pars_list.object
}

# Static assets bucket
resource "oci_objectstorage_bucket" "mushop_media" {
  compartment_id = var.compartment_ocid
  name           = format("%s-mushop-media", var.team_name)
  namespace      = local.namespace
  access_type    = "ObjectReadWithoutList"
}

# Static product media
resource "oci_objectstorage_object" "mushop_media" {
  for_each = fileset("./images", "**")

  bucket        = oci_objectstorage_bucket.mushop_media.name
  namespace     = oci_objectstorage_bucket.mushop_media.namespace
  object        = each.value
  source        = "./images/${each.value}"
  content_type  = "image/png"
  cache_control = "max-age=604800, public, no-transform"
}

# Static product media pars for Private (Load to catalogue service)
resource "oci_objectstorage_preauthrequest" "mushop_media_pars_preauth" {
  for_each = oci_objectstorage_object.mushop_media

  bucket       = oci_objectstorage_bucket.mushop_media.name
  namespace    = oci_objectstorage_bucket.mushop_media.namespace
  object_name  = each.value.object
  name         = "mushop_media_pars_par"
  access_type  = "ObjectRead"
  time_expires = timeadd(timestamp(), "30m")
}
