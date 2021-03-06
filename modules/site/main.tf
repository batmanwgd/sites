provider "aws" {
  region = "us-east-1"
  alias  = "cloudfront"
}

provider "aws" {
  region = "us-west-1"
  alias  = "main"
}

module "site" {
  source = "github.com/riboseinc/terraform-aws-s3-cloudfront-website"

  fqdn                = "${var.host}.${var.zone}"
  ssl_certificate_arn = "${aws_acm_certificate_validation.cert.certificate_arn}"
  allowed_ips         = "${var.allowed_ips}"

  index_document = "index.html"
  error_document = "404.html"

  force_destroy = "true"
}

resource "aws_acm_certificate" "cert" {
  provider          = "aws.cloudfront"
  domain_name       = "${var.host}.${var.zone}"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  provider = "aws.cloudfront"
  name     = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type     = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id  = "${data.aws_route53_zone.site.id}"
  records  = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl      = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = "aws.cloudfront"
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}

# Route 53 record for the static site

data "aws_route53_zone" "site" {
  name         = "${var.zone}"
  private_zone = false
}

resource "aws_route53_record" "web" {
  zone_id = "${data.aws_route53_zone.site.zone_id}"
  name    = "${var.host}.${var.zone}"
  type    = "A"

  alias {
    name                   = "${module.site.cf_domain_name}"
    zone_id                = "${module.site.cf_hosted_zone_id}"
    evaluate_target_health = false
  }
}
