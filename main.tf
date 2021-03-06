provider "aws" {
  region = "us-west-1"
}

variable "zone" {
  description = "Zone to host these static sites."
  default     = "sites.adborden.net"
}

terraform {
  backend "s3" {
    bucket = "adborden-terraform"
    key    = "terraform-ci-cd/terraform.tfstate"
    region = "us-west-1"
  }
}

resource "aws_route53_zone" "main" {
  name = "${var.zone}"
}

####################
# Site declarations
####################

module "site_codewithme" {
  source = "./modules/site"
  host   = "codewithme"
  zone   = "${var.zone}"
}

module "site_example" {
  source = "./modules/site"
  host   = "example"
  zone   = "${var.zone}"
}

module "site_future_of_california" {
  source = "./modules/site"
  host   = "future-of-california"
  zone   = "${var.zone}"
}

module "site_open_disclosure_san_jose" {
  source = "./modules/site"
  host   = "open-disclosure-san-jose"
  zone   = "${var.zone}"
}
