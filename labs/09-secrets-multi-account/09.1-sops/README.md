# 09.1 SOPS

Encrypt a values file with SOPS and age, decrypt it when the unit runs, and keep the private key out of git. No AWS account.

## Goal

From `start/`, make `./check.sh` pass.

`terragrunt render` in `unit/` shows `db_password = "lab-db-password"`, `note = "sops age"`, and `age_key_configured = true`. Apply creates three resources. The password output is sensitive. `lab-db-password` is a lab fixture, not a credential.

## Pin sops and age

sops and age are not part of the Terragrunt install, and this repo does not commit the binaries. The pins are exact releases in the repo root [`.mise.toml`](../../../.mise.toml):

```toml
sops = "3.13.3"
age = "1.3.2"
```

From the repo root:

```bash
mise install
eval "$(mise activate bash)"
sops --version
age --version
age-keygen --version
```

The version lines are `sops 3.13.3` and `v1.3.2`. `./check.sh` installs those pins when the binaries are missing.

## Layout

```text
start/
  root.hcl                     # terraform_binary
  secrets.example.yaml         # plaintext shape. Lab fixtures only.
  modules/record/
  unit/terragrunt.hcl          # sops_decrypt_file and get_env go here
  unit/.terraform.lock.hcl
```

`secrets.enc.yaml` is produced by SOPS. It is not in the scaffold. The checker creates it with a temporary key and deletes that key.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1), then install the sops and age pins above. `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17 when `tofu` is on `PATH`.
2. Read `secrets.example.yaml`. Leave the fixture values as they are.
3. Create an age key outside the repository. The conventional path is under your home directory:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
pub="$(age-keygen -y "$SOPS_AGE_KEY_FILE")"
```

`age-keygen` writes the identity file with mode `0600`. The public recipient is the `age1...` line. `SOPS_AGE_KEY_FILE` is the private key. Leave that file outside this repo. Do not commit it, and do not paste it into a unit.

4. Encrypt the example. From `start/`:

```bash
sops --encrypt --age "$pub" --filename-override secrets.enc.yaml secrets.example.yaml > secrets.enc.yaml
```

`secrets.enc.yaml` contains `sops:` metadata and `ENC[AES256_GCM,...]` values. You may commit that file. The bytes depend on your key, so another clone cannot decrypt it without the matching private key.

5. Replace the TODOs in `start/unit/terragrunt.hcl` with:

```hcl
locals {
  age_key_file = get_env("SOPS_AGE_KEY_FILE")
  secrets      = yamldecode(sops_decrypt_file(find_in_parent_folders("secrets.enc.yaml")))
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
}

inputs = {
  environment        = "dev"
  prefix             = "sops"
  note               = local.secrets.note
  db_password        = local.secrets.db_password
  age_key_configured = length(trimspace(local.age_key_file)) > 0
}
```

Keep the `include "root"` block. `get_env("SOPS_AGE_KEY_FILE")` has no default, so a missing variable fails before Terraform starts. SOPS reads that same variable when `sops_decrypt_file` runs. `age_key_configured` records that the path was set. It does not pass the key into Terraform.

6. From `start/unit`, with `SOPS_AGE_KEY_FILE` still exported:

```bash
terragrunt run -- version
terragrunt render
terragrunt run plan
```

The version line is Terraform 1.17.x. The render shows the decrypted fixture. The plan is `Plan: 3 to add, 0 to change, 0 to destroy.` `db_password` is `(sensitive value)`.

The lock file next to the unit pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

7. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  09.1 sops`.

The script does not use your key. It generates a new age key in a temporary directory, encrypts `secrets.example.yaml`, exports `SOPS_AGE_KEY_FILE` for that key, renders, applies, destroys, and deletes the key. If you already had a `secrets.enc.yaml`, the script puts that file back when it exits.

## If render or plan stops early

- `Required environment variable SOPS_AGE_KEY_FILE - not found` means `get_env` has no value. Export the variable in the same shell that runs Terragrunt.
- `sops metadata not found` means `secrets.enc.yaml` is missing or is still plaintext. Encrypt `secrets.example.yaml`.
- `failed to get the data key` means the private key does not match the recipient that encrypted the file. Encrypt again with the public key from `age-keygen -y`.
- A `get_env("SOPS_AGE_KEY_FILE", "")` default lets the unit render when the variable is unset, and decrypt then fails. Call `get_env` with one argument.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.
- `hcl fmt --check` fails when the alignment differs from the snippet above. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your unit with [`solution/unit/terragrunt.hcl`](solution/unit/terragrunt.hcl). What the checker prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
