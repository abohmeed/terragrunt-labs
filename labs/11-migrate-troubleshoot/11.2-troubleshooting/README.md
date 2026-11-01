# 11.2 Troubleshooting

Read a failed discovery with `--log-level debug`, separate a directory that is both a unit and a stack, and render the inputs the unit will actually receive. No AWS account.

## Goal

From `start/`, make `./check.sh` pass.

`live/` is shipped as both a unit and a stack. That directory cannot be queued. Delete the extra file, then `scripts/debug.sh` generates the stack and renders the unit at debug level. The rendered `note` is `traced from render`.

## The ambiguous directory

A directory is one component. `terragrunt.hcl` makes it a unit. `terragrunt.stack.hcl` makes it a stack. Both files in one directory is an error:

```text
contains both configuration files terragrunt.hcl and terragrunt.stack.hcl. A component must be either a unit or a stack, not both.
```

`live/terragrunt.stack.hcl` is the stack. It points at `units/record`. `live/terragrunt.hcl` is the file that makes the directory ambiguous. Delete that file. Leave the stack file.

## What `--log-level debug` prints

The default level is `info`. `--log-level debug` adds Terragrunt's own `DEBUG` lines. `TG_LOG_LEVEL=debug` is the same switch.

One of those lines is the binary Terragrunt probes at startup:

```text
DEBUG  Running command: tofu -version
```

That line is the startup probe. It runs when `--tf-path` is unset, because `tofu` is on `PATH` in this course. It does not mean the unit selected OpenTofu. The unit engine is still `terraform_binary` in `root.hcl`.

Pass `--tf-path terraform` and the same line becomes:

```text
DEBUG  Running command: terraform -version
```

With that flag, debug also prints:

```text
DEBUG  Auto provider cache dir setup failed: auto provider cache dir requires OpenTofu, but detected terraform
```

That line is debug detail. The command still exits 0. This course keeps Terraform for the unit, so the auto provider cache does not start. The plan is unchanged.

## What render shows

`terragrunt render --format json` prints the configuration after locals and functions resolve. `inputs.note` in the unit is `local.note`. The JSON has the string, not the expression:

```json
"note": "traced from render"
```

`--json` is the same flag as `--format json`. This lecture reads stdout. `--write` would save a file next to the unit. Do not commit that file.

## Layout

```text
start/
  root.hcl
  modules/record/
  units/record/terragrunt.hcl     # the unit. Finished.
  live/terragrunt.stack.hcl       # the stack. Keep this.
  live/terragrunt.hcl             # the bug. Delete this.
  scripts/debug.sh
```

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17 when `tofu` is on `PATH`.
2. From `start/`, reproduce the discovery error:

```bash
terragrunt --log-level debug --working-dir live stack generate
```

The log has `DEBUG` lines, including `Running command: tofu -version`, and the ambiguous-directory error.
3. Delete `start/live/terragrunt.hcl`. Do not delete `live/terragrunt.stack.hcl` or `units/record/terragrunt.hcl`.
4. Replace `start/scripts/debug.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf live/.terragrunt-stack

terragrunt --no-color --log-level debug --working-dir live stack generate --tf-path terraform
terragrunt --no-color --log-level debug --working-dir live/.terragrunt-stack/record \
  render --format json --tf-path terraform
```

Keep it executable: `chmod +x scripts/debug.sh`.

5. From `start/`:

```bash
./scripts/debug.sh
terragrunt --working-dir live stack run -- plan
```

The debug log includes `Running command: terraform -version`. The JSON note is `traced from render`. The plan is `Plan: 3 to add, 0 to change, 0 to destroy.`

6. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  11.2 troubleshooting`.

The lock file in `units/record` is copied into the generated unit. It pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

## If discovery or render stops early

- The ambiguous-directory error remains while `live/terragrunt.hcl` is still there. Delete that file only.
- `Running command: tofu -version` on a command that also passes `--tf-path terraform` means the flag is on the wrong command. `stack generate` takes `--tf-path` after `generate`. `render` takes it after `render`.
- Render JSON that still shows `local.note` means the command rendered a different file than `units/record`. Render `live/.terragrunt-stack/record`.
- `OpenTofu v` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.
- `hcl fmt --check` fails when a file drifted. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

The finished stack and unit match `start/` once `live/terragrunt.hcl` is gone. The script is in [`solution/scripts/debug.sh`](solution/scripts/debug.sh). What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
