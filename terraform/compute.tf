locals {
  ad              = data.oci_identity_availability_domain.ad.name
  shape           = "VM.Standard.E5.Flex"
  image           = data.oci_core_images.mushop_images.images[0].id
  setup_preflight = file("${path.module}/scripts/setup.preflight.sh")
  setup_template = templatefile("${path.module}/scripts/setup.template.sh",
    {
      oracle_client_version = "19.10"
  })
  deploy_template = templatefile("${path.module}/scripts/deploy.template.sh",
    {
      oracle_client_version   = "19.10"
      db_name                 = oci_database_autonomous_database.mushop_atp.db_name
      atp_pw                  = var.database_password
      mushop_media_visibility = true
      wallet_par              = "https://objectstorage.${var.region}.oraclecloud.com${oci_objectstorage_preauthrequest.mushop_wallet_preauth.access_uri}"
      oda_enabled             = false
      oda_uri                 = ""
      oda_channel_id          = ""
      oda_secret              = ""
      oda_user_init_message   = ""
      version                 = replace(file("${path.module}/VERSION"), "\n", "")
  })
  catalogue_sql_template = templatefile("${path.module}/scripts/catalogue.template.sql",
    {
      catalogue_password = var.database_password
  })
  httpd_conf = file("${path.module}/scripts/httpd.conf")
  cloud_init = templatefile("${path.module}/scripts/cloud-config.template.yaml",
    {
      setup_preflight_sh_content     = base64gzip(local.setup_preflight)
      setup_template_sh_content      = base64gzip(local.setup_template)
      deploy_template_content        = base64gzip(local.deploy_template)
      catalogue_sql_template_content = base64gzip(local.catalogue_sql_template)
      httpd_conf_content             = base64gzip(local.httpd_conf)
      mushop_media_pars_list_content = base64gzip(local.mushop_media_pars_list)
      catalogue_password             = var.database_password
      catalogue_port                 = 3005
      catalogue_architecture         = "amd64"
      mock_mode                      = "carts,orders,users"
      db_name                        = oci_database_autonomous_database.mushop_atp.db_name
      assets_url                     = "https://objectstorage.${var.region}.oraclecloud.com/n/${oci_objectstorage_bucket.mushop_media.namespace}/b/${oci_objectstorage_bucket.mushop_media.name}/o/"
  })
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.compartment_ocid
  ad_number      = 1
}

data "oci_core_images" "mushop_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "7.9"
  shape                    = local.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "cloudinit_config" "mushop" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = local.cloud_init
  }
}

resource "oci_core_instance" "mushop_bastion" {
  availability_domain = local.ad
  compartment_id      = var.compartment_ocid
  display_name        = format("%s-mushop-bastion", var.team_name)
  shape               = local.shape
  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }
  source_details {
    source_type = "image"
    source_id   = local.image
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.mushop_lb_subnet.id
    display_name     = "primaryvnic"
    assign_public_ip = true
    hostname_label   = format("%s-mushop-bastion", var.team_name)
  }
  metadata = {
    ssh_authorized_keys = var.public_key
  }
}

resource "oci_core_instance" "mushop_app_instance" {
  availability_domain = local.ad
  compartment_id      = var.compartment_ocid
  display_name        = format("%s-mushop-app", var.team_name)
  shape               = local.shape
  shape_config {
    ocpus         = 1
    memory_in_gbs = 16
  }
  source_details {
    source_type = "image"
    source_id   = local.image
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.mushop_app_subnet.id
    display_name     = "primaryvnic"
    assign_public_ip = false
    hostname_label   = format("%s-mushop-app", var.team_name)
  }
  metadata = {
    ssh_authorized_keys = var.public_key
    user_data           = data.cloudinit_config.mushop.rendered
  }
}
