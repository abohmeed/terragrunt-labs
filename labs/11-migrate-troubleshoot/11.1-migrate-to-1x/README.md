# 11.1 Migrate to 1.x

Move a Terragrunt 0.x queue onto the 1.x command, the renamed flags, and a stack in place of `_envcommon`. No AWS account.

## Goal

From `start/`, make `./check.sh` pass.

`legacy/` is the 0.x tree. Leave it. `live/dev` and `live/prod` are the stacks that replace it. `scripts/queue.sh` is the command a pipeline would run. `flags.md` is the rename table for the flags this course uses.

## What changed between 0.x and 1.x

Three changes show up in this lecture.

| 0.x | 1.x |
| --- | --- |
| `terragrunt run-all plan` | `terragrunt run --all -- plan` |
| `--terragrunt-non-interactive`, `--terragrunt-tfpath`, `--terragrunt-exclude-dir` | `--non-interactive`, `--tf-path`, `--queue-exclude-dir` |
| `include "envcommon"` of `_envcommon/record.hcl` | a `unit` block in `terragrunt.stack.hcl` |

`terragrunt run-all` is not a command in 1.2. The error is:

```text
unknown command: "run-all"
```

The `--` in `run --all -- plan` keeps `plan` and `-input=false` on the Terraform side. `--tf-path` belongs on `run`, after the subcommand. It is not a global flag, so it does not go in front of `run`.

`--queue-exclude-dir` is the renamed form of `--terragrunt-exclude-dir`. `terragrunt run --help` on 1.2 also lists `--filter`. `--filter '!./legacy/**'` excludes the same directories. This lecture uses `--queue-exclude-dir` so the rename stays visible in the script.

Environment variables dropped the `TERRAGRUNT_` prefix. A few names changed with the flag:

| 0.x | 1.x |
| --- | --- |
| `TERRAGRUNT_NON_INTERACTIVE` | `TG_NON_INTERACTIVE` |
| `TERRAGRUNT_TFPATH` | `TG_TF_PATH` |
| `TERRAGRUNT_DEBUG` | `TG_INPUTS_DEBUG` |
| `TERRAGRUNT_LOG_LEVEL` | `TG_LOG_LEVEL` |

`--terragrunt-debug` is `--inputs-debug`. `terragrunt render-json` is `terragrunt render --format json`. `terragrunt hclfmt` is `terragrunt hcl fmt`.

`run --all` from this directory generates each `terragrunt.stack.hcl` and then plans the generated units. `--queue-exclude-dir 'legacy/**'` keeps the 0.x tree out of that queue. `--queue-exclude-dir 'units/**'` keeps the unit template out of it. The template has a default `terragrunt.values.hcl`. The stack `values` block replaces that file in the generated unit.

## Layout

```text
start/
  root.hcl
  modules/record/
  legacy/                         # 0.x snapshot. Do not edit.
    commands.sh                   # run-all and --terragrunt-* flags
    _envcommon/record.hcl
    dev/record/terragrunt.hcl
    prod/record/terragrunt.hcl
  units/record/                   # the shared unit. Finished.
  live/dev/terragrunt.stack.hcl   # source goes here
  live/prod/terragrunt.stack.hcl
  scripts/queue.sh                # the 1.x command
  flags.md                        # the rename table
```

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17 when `tofu` is on `PATH`.
2. From `start/`, run the old command and read the error. Do not change the file.

```bash
./legacy/commands.sh
```

3. Replace the TODO in `flags.md` with the finished table in [`solution/flags.md`](solution/flags.md).
4. Replace the TODO source in both stack files:

```hcl
source = "../../units/record"
```

Keep `path = "record"` and the `values` blocks. Dev's note stays `dev stack`. Prod's note stays `prod stack`.
5. Replace `start/scripts/queue.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

terragrunt --no-color --non-interactive \
  run --all \
  --tf-path terraform \
  --queue-exclude-dir 'legacy/**' \
  --queue-exclude-dir 'units/**' \
  -- plan -input=false -no-color
```

Keep it executable: `chmod +x scripts/queue.sh`.

6. From `start/`:

```bash
./scripts/queue.sh
terragrunt --working-dir live/dev/.terragrunt-stack/record run -- version
```

The queue plans two units. Each plan is `3 to add`. Dev's note is `dev stack`. Prod's note is `prod stack`. The version line is Terraform 1.17.x.

7. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  11.1 migrate to 1.x`.

The checker plans, applies, and destroys the two generated units. The lock file in `units/record` is copied into each generated unit. It pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

## If the queue stops early

- `unknown command: "run-all"` means the script still calls the 0.x command. Use `run --all`.
- `flag provided but not defined: -terragrunt-non-interactive` means a `--terragrunt-` flag is still on the command. Use the name in `flags.md`.
- `flag --tf-path is not a valid global flag` means `--tf-path` is in front of `run`. Put it on `run`, as in the script above.
- A plan whose note is `default note` means the stack `values` block was dropped. The template's `terragrunt.values.hcl` is only the fallback.
- A plan of `legacy/dev/record` means `--queue-exclude-dir 'legacy/**'` is missing.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`, or `--tf-path` pointed at `tofu`.
- `hcl fmt --check` fails when a stack file drifted. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your stacks, script, and table with `solution/`. `legacy/` matches `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
