# 09.1 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  09.1 sops
```

The checker does not use a committed private key. It generates an age key in a temporary directory, encrypts `secrets.example.yaml` to `secrets.enc.yaml`, exports `SOPS_AGE_KEY_FILE`, runs the unit, and deletes the key. A `secrets.enc.yaml` that was already in the directory is put back when the script exits.

`unit/terragrunt.hcl` reads the key path and the encrypted file:

| Local | Expression |
| --- | --- |
| `age_key_file` | `get_env("SOPS_AGE_KEY_FILE")` |
| `secrets` | `yamldecode(sops_decrypt_file(find_in_parent_folders("secrets.enc.yaml")))` |

`get_env` has no default. An empty environment fails with `Required environment variable SOPS_AGE_KEY_FILE - not found` before Terraform starts. SOPS itself reads `SOPS_AGE_KEY_FILE`. The local forces that variable to be set and turns it into `age_key_configured`.

The decrypted lab fixture is `db_password = "lab-db-password"` and `note = "sops age"`. `db_password` is a sensitive output. `terraform output -raw db_password` prints the fixture. The value is not a credential.

What the checker shows:

1. `terragrunt hcl fmt --check` passes.
2. `.mise.toml` pins `sops = "3.13.3"` and `age = "1.3.2"`.
3. No lab file contains an age identity. The private key stays in a temporary directory.
4. `terragrunt run -- version` prints `Terraform v1.17.<patch>`.
5. `terragrunt render` shows the decrypted fixture and `age_key_configured = true`. The render does not print the private key.
6. Apply creates 3 resources. Destroy removes them.

`secrets.example.yaml` stays plaintext so the shape of the file is visible. The encrypted bytes change every checker run because the age key is new each time. Commit `secrets.enc.yaml` only after you encrypt it with your own key. Leave that key outside the repository.
