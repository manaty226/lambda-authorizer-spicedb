
# Root certification

resource "tls_private_key" "root" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "root" {
  private_key_pem = "${tls_private_key.root.private_key_pem}"

  subject {
    common_name  = "spicedb_test"
  }

  validity_period_hours = 87600

  is_ca_certificate = true

  allowed_uses = [
   "digital_signature",
   "crl_signing",
   "cert_signing",
  ]
}

# resource "local_file" "root_key" {
#   filename = "root.key"
#   content  = "${tls_private_key.root.private_key_pem}"
# }

# resource "local_file" "root_pem" {
#   filename = "root.crt"
#   content  = "${tls_self_signed_cert.root.cert_pem}"
# }

# Sever certification
resource "tls_private_key" "server" {
  algorithm = "RSA"
}

resource "tls_cert_request" "server" {
  private_key_pem = "${tls_private_key.server.private_key_pem}"

  subject {
    common_name  = "*.ap-northeast-1.elb.amazonaws.com"
  }

  dns_names = [
    "*.ap-northeast-1.elb.amazonaws.com",
  ]
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem   = "${tls_cert_request.server.cert_request_pem}"

  ca_private_key_pem = "${tls_private_key.root.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.root.cert_pem}"

  validity_period_hours = 87600

  is_ca_certificate = false
  set_subject_key_id = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

# resource "local_file" "server_key" {
#   filename = "https_test.key"
#   content  = "${tls_private_key.server.private_key_pem}"
# }

# resource "local_file" "server_pem" {
#   filename = "https_test_cert.pem"
#   content  = "${tls_locally_signed_cert.server.cert_pem}"
# }

# output "server_private_key" { value = "${tls_private_key.server.private_key_pem}" }
# output "server_crt" { value = "${tls_locally_signed_cert.server.cert_pem}" }
# output "root_crt" { value = "${tls_self_signed_cert.root.cert_pem}" }
