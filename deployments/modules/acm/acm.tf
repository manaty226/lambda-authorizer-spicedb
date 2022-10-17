# variable server_private_key_pem {}
# variable server_crt_pem {}
# variable root_crt_pem {}

resource "aws_acm_certificate" "spicedb_alb" {
  private_key       = "${tls_private_key.server.private_key_pem}"
  certificate_body  = "${tls_locally_signed_cert.server.cert_pem}"
  certificate_chain = "${tls_self_signed_cert.root.cert_pem}"

  tags = {
    Name = "crt for spicedb"
  }
}

output "acm_certificate_arn" { value = aws_acm_certificate.spicedb_alb.arn }