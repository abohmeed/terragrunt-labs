# 12.1 Switch to OpenTofu

Point Terragrunt at the pinned OpenTofu 1.13.x binary, and override that choice for a single command with `--tf-path` or `TG_TF_PATH`. No AWS account.

## Goal

From `start/`, make `./check.sh` pass.

`root.hcl` starts on Terraform. This section sets `terraform_binary = "tofu"`. `scripts/engines.sh` prints three version lines: the attribute, `--tf-path terraform`, and `TG_TF_PATH=terraform`. The apply uses the attribute, so the unit runs on OpenTofu.

## Which binary runs

Terragrunt picks the binary in this order:

1. `--tf-path`
2. `TG_TF_PATH`
3. `terraform_binary` in the unit, including a value merged from `root.hcl`
4. `tofu` on `PATH`, then `terraform`

`--tf-path` is a flag of `run`, `render`, and `stack`. It is not a global flag. Put it after the subcommand:

```bash
terragrunt run --tf-path terraform -- version
```

`TG_TF_PATH` is the environment variable for the same setting. The 0.x name was `TERRAGRUNT_TFPATH`. One command can set it without exporting it:

```bash
TG_TF_PATH=terraform terragrunt run -- version
```

The attribute is what stays when the flag and the variable are unset. Lectures before this section set it to `terraform`. This section sets it to `tofu`.

`required_version` in the module is `>= 1.13.0, < 1.18.0`. OpenTofu 1.13.x and Terraform 1.17.x both sit in that range. The checker does not trust the constraint alone. It reads `OpenTofu v1.13.` and `Terraform v1.17.` from the version command.

The lock file next to the unit selects `registry.opentofu.org`. OpenTofu rewrites a `registry.terraform.io` lock file on init, because the provider builds are not byte-for-byte identical. Lecture 12.2 records that difference. This lecture already has the OpenTofu lock file, so apply does not rewrite it.

## Layout

```text
start/
  root.hcl                 # terraform_binary goes here
  modules/record/
  unit/terragrunt.hcl      # finished
  unit/.terraform.lock.hcl # OpenTofu lock file. Finished.
  scripts/engines.sh
```

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `mise install` already includes OpenTofu 1.13.x.
2. In `start/root.hcl`, set:

```hcl
terraform_binary = "tofu"
```

3. Replace `start/scripts/engines.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== attribute =="
terragrunt --no-color --working-dir unit run -- version

echo "== flag =="
terragrunt --no-color --working-dir unit run --tf-path terraform -- version

echo "== env =="
TG_TF_PATH=terraform terragrunt --no-color --working-dir unit run -- version
```

Keep it executable: `chmod +x scripts/engines.sh`.

4. From `start/`:

```bash
tofu version
./scripts/engines.sh
terragrunt --working-dir unit run -- apply -auto-approve -input=false
terragrunt --working-dir unit output -raw note
```

`tofu version` is OpenTofu 1.13.x. The attribute section is OpenTofu 1.13.x. The flag section and the env section are Terraform 1.17.x. The note is `switched to tofu`.

5. Destroy the unit:

```bash
terragrunt --working-dir unit run -- destroy -auto-approve -input=false
```

6. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  12.1 switch to OpenTofu`.

The lock file pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1 from `registry.opentofu.org`. The first apply downloads those providers. You do not need AWS credentials.

## If version or apply stops early

- `flag --tf-path is not a valid global flag` means `--tf-path` is in front of `run`. Put it after `run`.
- The attribute section prints `Terraform v1.17` when `terraform_binary` is still `"terraform"`.
- The flag section prints `OpenTofu v1.13` when `--tf-path terraform` was left off that command. `TG_TF_PATH` has the same effect on the env section.
- `required_version` fails on OpenTofu 1.13 when the constraint still says `>= 1.17.0`. This lecture's module already allows 1.13.
- `hcl fmt --check` fails when `root.hcl` drifted. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare `root.hcl` and `scripts/engines.sh` with `solution/`. The module and the lock file match `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
