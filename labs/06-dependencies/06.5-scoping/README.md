# 06.5 Scoping

Limit a multi-unit run so the queue contains only the units you mean to touch. No AWS account.

## Goal

From `start/`, make `./check.sh` pass. The units are already written. The work is the queue flags.

A shared `network` unit sits next to `apps/`. From `apps/`, that network unit is an external dependency: the apps depend on it, and it lives outside the working directory. Terragrunt 1.2 leaves external dependencies out of `run --all` unless you opt in.

## Layout

```text
start/
  root.hcl
  modules/record/
  network/terragrunt.hcl
  apps/
    api/terragrunt.hcl       # dependency config_path = "../../network"
    worker/terragrunt.hcl
    legacy/terragrunt.hcl
```

Each app mocks `name` as `mock-network-name` for `validate`, `plan`, and `destroy`. `apply` is not in that list. `run --all apply` from `start/` applies network first, so the apps receive the real name.

## What each flag changes

Run the plans from `apps/` unless the step says otherwise.

| Command | Units in the queue |
| --- | --- |
| `terragrunt run --all -- plan` | `api`, `worker`, `legacy` |
| `terragrunt run --all --queue-exclude-external -- plan` | The same three. The flag warns that this is already the default |
| `terragrunt run --all --queue-exclude-dir ./legacy -- plan` | `api`, `worker` |
| `terragrunt run --all --filter='!./legacy' -- plan` | `api`, `worker` |
| `terragrunt run --all -- plan` from `start/` | `network`, `apps/api`, `apps/worker`, `apps/legacy` |

`--queue-exclude-external` is the old switch for "do not run dependencies that live outside this directory." Terragrunt 1.2 does that by default and prints:

```text
The `--queue-exclude-external` flag is deprecated and will be removed in a future version of Terragrunt. External dependencies are now excluded by default.
```

`run` does not accept `--exclude-dir`. That flag belongs to `terragrunt hcl fmt`. The run flag is `--queue-exclude-dir`. `--filter='!./legacy'` is the same exclusion in the filter syntax.

## The destroy trap

From `apps/`, a plain `run --all destroy` destroys the three apps and leaves `network` applied. That is the safe command.

`--queue-include-external` puts `network` back in the queue. `run --all destroy` with that flag destroys the apps and then destroys `network`. The command was typed in `apps/`. The shared unit outside `apps/` is still removed. That is the trap.

`--destroy-dependencies-check` is a separate warning. It searches for dependents up to the git root, the same walk as `--graph`. Unfinished lectures in this repository make that search stop, and the warning is then missing while the destroy still runs. `./check.sh` copies this lecture, including `.terragrunt-cache`, to a temporary directory, runs `git init` there, and destroys `network` in the copy. Do the same when you want to see the warning:

```bash
tmp="$(mktemp -d)"
python3 - "$tmp/lab" <<'PY'
import shutil, sys
from pathlib import Path
shutil.copytree(Path("."), Path(sys.argv[1]))
PY
git -C "$tmp/lab" init
terragrunt --working-dir "$tmp/lab/network" --non-interactive run --destroy-dependencies-check -- destroy -auto-approve -input=false
```

Terragrunt prints `Detected dependent units:` and the three app paths, then destroys `network` in the copy. The warning does not refuse the destroy. Destroy dependents first, or leave the shared unit out of the queue. The original `start/network` state is untouched.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). From `start/`:

```bash
terragrunt --non-interactive run --all -- plan -input=false
cd apps
terragrunt --non-interactive run --all -- plan -input=false
terragrunt --non-interactive run --all --queue-exclude-external -- plan -input=false
terragrunt --non-interactive run --all --exclude-dir ./legacy -- plan -input=false
terragrunt --non-interactive run --all --queue-exclude-dir ./legacy -- plan -input=false
terragrunt --non-interactive run --all --filter='!./legacy' -- plan -input=false
```

The lecture-root plan queues four units. The `apps/` plan queues three. `--exclude-dir` errors and names `hcl format --exclude-dir`. `--queue-exclude-dir` and `--filter` queue `api` and `worker`.

2. Apply from `start/`, then destroy only the apps:

```bash
cd ..
terragrunt --non-interactive run --all -- apply -input=false
terragrunt --working-dir network output -raw name
terragrunt --working-dir apps --non-interactive run --all -- destroy -input=false
terragrunt --working-dir network output -raw name
```

The second `name` matches the first. The apps are gone.

3. Put the apps back, then run the trap:

```bash
terragrunt --working-dir apps --non-interactive run --all -- apply -input=false
terragrunt --working-dir apps --non-interactive run --all --queue-include-external -- destroy -input=false
terragrunt --working-dir network run -- state list
```

`state list` in `network` is empty. `../network` was in the destroy queue.

4. Apply the lecture again. The dependency check runs in the temporary copy from the section above, after that apply, so the copy still has network state. The log lists `apps/api`, `apps/worker`, and `apps/legacy`, and the destroy still completes.

The lock file next to each unit pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

5. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  06.5 scoping`.

## If the queue contains network when you are in apps/

- A plan from `apps/` that also plans `network` was started with `--queue-include-external`, or it was started from `start/` rather than from `apps/`.
- `run` exiting on `--exclude-dir` is the 1.2 command shape. Use `--queue-exclude-dir ./legacy`.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.

The finished units match `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
