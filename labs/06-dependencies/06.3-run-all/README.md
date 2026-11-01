# 06.3 Run all

Plan and apply a chain of units in dependency order with one command, then run the same command along `--graph`. No AWS account.

## Goal

From `start/`, make `./check.sh` pass. The units are already written. This lecture is the queue.

`terragrunt run --all plan` plans `network`, `database`, and `service`. A cold plan uses mocks. `terragrunt run --all apply` applies network first, then database, then service, and each unit's `name` output becomes the next unit's `note`.

## The chain

```text
start/
  root.hcl
  modules/record/
  network/terragrunt.hcl     # no dependency
  database/terragrunt.hcl    # dependency "network"
  service/terragrunt.hcl     # dependency "database"
```

| Unit | Reads | Mock, until that dependency is applied |
| --- | --- | --- |
| `network` | nothing | |
| `database` | `dependency.network.outputs.name` | `mock-network-name` |
| `service` | `dependency.database.outputs.name` | `mock-db-name` |

Mocks are allowed for `validate` and `plan`, the same rule as lecture 06.2. `run --all apply` applies dependencies first, so database and service see real outputs by the time they apply.

## `run --all` and `run --graph`

Both flags live on `run`. Terraform arguments stay after `--`.

| Command | Where you run it | What is queued |
| --- | --- | --- |
| `terragrunt run --all -- plan` | `start/` | Every unit under the working directory |
| `terragrunt run --graph -- plan` | `network/` | `network`, plus every unit that depends on it |
| `terragrunt run --graph -- plan` | `database/` | `database` and `service`. `network` is a dependency, so it is not in this queue |
| `terragrunt run --graph -- plan` | `service/` | `service` only |

`--graph` walks up to the git root looking for dependents. This repository's other lectures are not all valid HCL yet, and that walk stops on them. `./check.sh` copies this lecture to a temporary directory, runs `git init` there, and runs `--graph` in the copy. Do the same when you want to run `--graph` yourself. `run --all` stays inside the working directory and does not need the copy.

`run --all apply` and `run --all destroy` add `-auto-approve` for you. Destroy runs in the opposite order: service, then database, then network.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17.
2. From `start/`:

```bash
terragrunt run -- version
terragrunt --non-interactive run --all -- plan -input=false
```

The version line, from `network/`, is Terraform 1.17.x. The plan queue names three units. Database's `note` is `mock-network-name`. Service's `note` is `mock-db-name`. Network's `note` is `network unit`. Each plan is `3 to add`.

3. Apply the queue, then read the three names:

```bash
terragrunt --non-interactive run --all -- apply -input=false
terragrunt --working-dir network output -raw name
terragrunt --working-dir database output -raw note
terragrunt --working-dir database output -raw name
terragrunt --working-dir service output -raw note
```

Database `note` equals the network `name`. Service `note` equals the database `name`. Neither value is still a mock.

4. Run `--graph` in a copy whose git root is this lecture. From `start/`:

```bash
tmp="$(mktemp -d)"
python3 - "$tmp/lab" <<'PY'
import shutil, sys
from pathlib import Path
dest = Path(sys.argv[1])
shutil.copytree(Path("."), dest, ignore=lambda _d, names: [n for n in names if n == ".terragrunt-cache"])
PY
git -C "$tmp/lab" init
terragrunt --working-dir "$tmp/lab/network" --non-interactive run --graph -- plan -input=false
terragrunt --working-dir "$tmp/lab/service" --non-interactive run --graph -- plan -input=false
```

The network graph plans three units. The service graph plans one.

5. Destroy the queue from `start/`:

```bash
terragrunt --non-interactive run --all -- destroy -input=false
```

Service is destroyed, then database, then network.

The lock file next to each unit pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

6. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  06.3 run all`.

## If the queue stops early

- `detected no outputs` on `run --all plan` means a mock was removed. `plan` has to be allowed to use `mock_outputs` while the dependency has never been applied.
- `run --graph` reporting a `find_in_parent_folders("TODO")` error is the git-root walk leaving this lecture. Use the temporary copy in step 4.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.

The finished units match `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
