# 01.2 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run, from `start/` or from here, ends with:

```text
PASS  01.2 repo tour
```

The script reads files under the repo root. It does not call AWS, Terraform, or Terragrunt. These are the checklist answers.

## Layout

- Repo root, from `labs/01-setup/01.2-repo-tour/`: `../../..`
- Section folders under `labs/`: 13 (`01-setup` through `13-capstone`)
- First section folder: `01-setup`
- Last section folder: `13-capstone`

## One lecture

`labs/03-core-hcl/03.2-locals-inputs/` contains:

- `README.md`, the goal and the steps
- `start/`, where you do the work
- `solution/`, the finished lab

A passing checker prints a line that starts with `PASS`. `solution/check.sh` is the same script as `start/check.sh`.

## Pins in `.mise.toml`

| Tool | Value |
| --- | --- |
| Terragrunt | `prefix:1.2` |
| Terraform | `prefix:1.17` |
| OpenTofu | `prefix:1.13` |
| tflint | `0.65.0` |
| sops | `3.13.3` |
| age | `1.3.2` |

`prefix:1.2` means Terragrunt 1.2.x. `prefix:1.17` means Terraform 1.17.x. OpenTofu stays unused until section 12.

## Engine

Labs set `terraform_binary = "terraform"`. Terragrunt 1.2 runs OpenTofu when `tofu` is on `PATH`, and `mise install` puts it there. Section 12 (`labs/12-addon-opentofu`) is where the engine changes.

## Cloud lectures

These four titles are marked ☁️. Their checkers do not call AWS.

| Lecture | Path | Needs AWS for |
| --- | --- | --- |
| 05.2 | `labs/05-remote-state/05.2-backend-bootstrap/` | An S3 backend and `use_lockfile` locking |
| 09.2 | `labs/09-secrets-multi-account/09.2-assume-role/` | Assuming an IAM role from a unit |
| 09.3 | `labs/09-secrets-multi-account/09.3-multi-account/` | The same unit in two accounts |
| 10.2 | `labs/10-cicd/10.2-gha-oidc/` | GitHub Actions assuming an AWS role with OIDC |

Every other lecture in `labs/` is offline: `local`, `random`, or `null`, and a local state backend.
