resource "null_resource" "drift" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "echo 'Error: safe-to-ignore' >&2; exit 1"
  }
}
