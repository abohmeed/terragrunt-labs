# 01.2 Repo tour

Every lecture in this course is a folder in this repository. Clone it once, then work inside it. This lecture walks the layout, the pins, and the four labs that need AWS. Nothing is installed and nothing is applied.

## Goal

From `start/`, walk the paths below, fill in [`start/checklist.md`](start/checklist.md), and run:

```bash
./check.sh
```

The last line is `PASS  01.2 repo tour`. The checker reads the repository on disk. It does not read your checklist answers, and it does not call AWS.

The filled checklist is [`solution/NOTES.md`](solution/NOTES.md).

## Where you are

This lecture is `labs/01-setup/01.2-repo-tour/`. From that directory:

| What | Path |
| --- | --- |
| Repo root | `../../..` |
| All labs | `../..` |
| Version pins | `../../../.mise.toml` |
| Sample lecture | `../../03-core-hcl/03.2-locals-inputs/` |

`labs/` has one folder per section, numbered with the course:

| Folder | Section |
| --- | --- |
| `01-setup` | This section |
| `02-install` | Pin the CLIs and run a first unit |
| `03-core-hcl` | `source`, inputs, functions, `generate` |
| `04-include` | One root configuration, many units |
| `05-remote-state` | Local backend, then an S3 bootstrap |
| `06-dependencies` | Outputs, mocks, and run order |
| `07-stacks` | Generate units from a stack file |
| `08-hooks` | Hooks, tflint, and the `errors` block |
| `09-secrets-multi-account` | SOPS, then IAM |
| `10-cicd` | Plan on a pull request, apply on merge |
| `11-migrate-troubleshoot` | Terragrunt 0.x names, then debug |
| `12-addon-opentofu` | OpenTofu, only in this section |
| `13-capstone` | A dev and prod stack, then a reading list |

## One lecture folder

Open `labs/03-core-hcl/03.2-locals-inputs/`. Every lecture folder has the same three entries:

| Entry | What it is |
| --- | --- |
| `README.md` | The goal and the steps |
| `start/` | Where you work. Later lectures leave blanks here for you to fill |
| `solution/` | The finished lab. Open it when you are stuck, or to compare |

Most lectures also have `start/check.sh`. It removes the cache when there is one, runs the lab cold, and prints a line that starts with `PASS`. `solution/check.sh` is that same script.

## Pins

[`.mise.toml`](../../../.mise.toml) at the repo root is the version lock:

| Tool | Pin | Where |
| --- | --- | --- |
| Terragrunt | `prefix:1.2` | Every lab |
| Terraform | `prefix:1.17` | Default engine |
| OpenTofu | `prefix:1.13` | Section 12 only |
| tflint | `0.65.0` | Lecture 08.2 |
| sops | `3.13.3` | Lecture 09.1 |
| age | `1.3.2` | Lecture 09.1 |

A `prefix:` request tracks the newest patch on that minor line. tflint, sops, and age are exact releases because those lectures run the binaries.

Terragrunt 1.2 runs OpenTofu when it finds `tofu` on `PATH`. `mise install` puts `tofu` there, so labs set `terraform_binary = "terraform"` and stay on Terraform until section 12. You do not install anything in this lecture. Lecture 02.1 is the install.

## Offline, and the four cloud lectures

Most labs use the `local`, `random`, and `null` providers and a local state backend. Four lectures need AWS. Their own titles are marked ☁️, and their checkers still do not call AWS:

| Lecture | Path | AWS is used for |
| --- | --- | --- |
| 05.2 | `labs/05-remote-state/05.2-backend-bootstrap/` | An S3 backend and `use_lockfile` locking |
| 09.2 | `labs/09-secrets-multi-account/09.2-assume-role/` | Assuming an IAM role from a unit |
| 09.3 | `labs/09-secrets-multi-account/09.3-multi-account/` | The same unit in two accounts |
| 10.2 | `labs/10-cicd/10.2-gha-oidc/` | GitHub Actions assuming an AWS role with OIDC |

## Steps

1. From this lecture folder, list the sections: `ls ../..`. You should see `01-setup` through `13-capstone`.
2. Open `../../03-core-hcl/03.2-locals-inputs/` and confirm `README.md`, `start/`, and `solution/`.
3. Open `../../../.mise.toml`. Confirm Terragrunt `prefix:1.2`, Terraform `prefix:1.17`, and OpenTofu `prefix:1.13`.
4. Read the cloud table above, then open one cloud title, for example `../../05-remote-state/05.2-backend-bootstrap/README.md`. The heading includes ☁️. Come back without running that lab.
5. Fill the blanks in `start/checklist.md`. Compare with [`solution/NOTES.md`](solution/NOTES.md).
6. From `start/`, run `./check.sh`. From `solution/`, the same script checks the repo again and ends with `PASS  01.2 repo tour`.
