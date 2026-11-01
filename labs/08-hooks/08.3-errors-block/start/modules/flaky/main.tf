resource "null_resource" "flaky" {
  triggers = {
    attempt_file = var.attempt_file
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -eu
      file="$TF_VAR_attempt_file"
      mkdir -p "$(dirname "$file")"
      n=0
      if [ -f "$file" ]; then
        n=$(cat "$file")
      fi
      n=$((n + 1))
      printf '%s\n' "$n" > "$file"
      if [ "$n" -lt 2 ]; then
        echo "Error: transient" >&2
        exit 1
      fi
      echo "flaky call succeeded on attempt $n"
    EOT
  }
}
