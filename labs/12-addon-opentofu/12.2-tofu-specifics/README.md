# 12.2 OpenTofu specifics

Record what stays the same on OpenTofu, add a `.tofu` file OpenTofu loads in place of the `.tf` file, and write down state encryption without turning it on. No AWS account.

## Goal

From `start/`, make `./check.sh` pass.

The unit already sets `terraform_binary = "tofu"`. Add `modules/record/engine.tofu` so the output `engine_file` is `tofu`. Fill `differences.md` with the notes below. Do not add an `encryption` block.

## .tofu files

OpenTofu loads `.tf` and `.tofu`. When `engine.tf` and `engine.tofu` are both in the module, OpenTofu loads `engine.tofu` and ignores `engine.tf`. Terraform does the opposite: it loads `engine.tf` and ignores every `.tofu` file.

The replacement is the whole file. It is not an `_override.tf` merge. The output name is the same in both files, so only one of them is loaded:

| Engine | File it loads | `engine_file` |
| --- | --- | --- |
| OpenTofu 1.13 | `engine.tofu` | `tofu` |
| Terraform 1.17 | `engine.tf` | `tf` |

`engine.tf` is already in the module. Add `engine.tofu` next to it:

```hcl
output "engine_file" {
  value = "tofu"
}
```

## State encryption

OpenTofu can encrypt state and plan files at rest. The configuration is an `encryption` block inside the `terraform` block, or the `TF_ENCRYPTION` environment variable. Terraform has no equivalent block. A Terraform backend can still encrypt at rest, for example S3 server-side encryption, which is the backend from lecture 05.2.

This lab does not enable encryption.

- A passphrase in the repository is a leaked key.
- Encrypted state cannot be read without that key.
- The checker rejects an `encryption` block in `.tf`, `.tofu`, and `.hcl` files.

Write the behavior into `differences.md`. Leave it out of the module.

## The lock file

OpenTofu installs providers from `registry.opentofu.org`. On init it rewrites a lock file that still says `registry.terraform.io`, and it drops the Terraform hashes, because the provider builds are not byte-for-byte identical. Terraform then reports an inconsistent dependency lock file if it applies with the rewritten file.

This section commits the OpenTofu lock file. Lectures before this section commit the Terraform lock file. Switching engines in an existing unit means committing the lock file the engine rewrote, not sharing one file unchanged.

The version numbers diverged after the fork. OpenTofu 1.13.x is the pin for this section. Terraform 1.17.x is the pin for the rest of the course. OpenTofu 1.13 is not Terraform 1.13.

`--tf-path` and `TG_TF_PATH` still override `terraform_binary`, as in lecture 12.1. This lecture leaves the attribute on `tofu`.

## What stays the same

The unit, the inputs, and the local backend stay the same. `local`, `null`, and `random` still create the record. Terragrunt still reads `terragrunt.hcl`.

## Layout

```text
start/
  root.hcl                         # terraform_binary = "tofu". Finished.
  modules/record/engine.tf         # Terraform's output. Finished.
  modules/record/engine.tofu       # add this
  unit/terragrunt.hcl              # finished
  differences.md                   # fill this
```

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). Leave `terraform_binary = "tofu"`.
2. Add `start/modules/record/engine.tofu` with `value = "tofu"`. Leave `engine.tf` as `value = "tf"`.
3. Replace the TODOs in `start/differences.md` with the finished notes in [`solution/differences.md`](solution/differences.md).
4. From `start/`:

```bash
terragrunt --working-dir unit run -- version
terragrunt --working-dir unit run -- apply -auto-approve -input=false
terragrunt --working-dir unit output -raw engine_file
terragrunt --working-dir unit output -raw note
```

The version line is OpenTofu 1.13.x. `engine_file` is `tofu`. The note is `tofu specifics`. The plan does not also print `engine_file = "tf"`.

5. Destroy the unit:

```bash
terragrunt --working-dir unit run -- destroy -auto-approve -input=false
```

6. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  12.2 OpenTofu specifics`.

The lock file pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1 from `registry.opentofu.org`. The first apply downloads those providers. You do not need AWS credentials.

## If apply stops early

- `engine_file` is `tf` when `engine.tofu` is missing or has a different basename. The basename has to be `engine`, matching `engine.tf`.
- A duplicate output error means both files were loaded. OpenTofu only skips `engine.tf` when `engine.tofu` is beside it.
- `encryption` in a `.tf` or `.tofu` file fails the checker. Keep that note in `differences.md`.
- `OpenTofu v1.13` is missing when `terraform_binary` is not `tofu`.
- `hcl fmt --check` fails when `root.hcl` drifted. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

`engine.tf`, the unit, and the lock file match `start/`. The new file and the notes are in `solution/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
