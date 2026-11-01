# Terragrunt labs

Hands-on labs for **[Terragrunt for DevOps: Scale Your Terraform Workflows](https://www.udemy.com/course/terragrunt-for-devops-scale-your-terraform-workflows/)** by Ahmed Elfakharany.

This repository is the Terragrunt 1.x rebuild of the course. The folder tree matches the locked curriculum (2026-11-01). Sections 01 through 13 are working labs. Section 01 reads the copied-root problem and this repo. It does not install tools or apply infrastructure.

## Version pins

| Tool | Pin | Where it is used |
| --- | --- | --- |
| Terragrunt | `~> 1.2` (1.2.x) | Every lab |
| Terraform | 1.17.x | Default engine |
| OpenTofu | 1.13.x | Add-on section, `labs/12-addon-opentofu` |
| tflint | 0.65.0 | Lecture 08.2. Exact release in [`.mise.toml`](.mise.toml) |
| sops | 3.13.3 | Lecture 09.1. Exact release in [`.mise.toml`](.mise.toml) |
| age | 1.3.2 | Lecture 09.1. Exact release in [`.mise.toml`](.mise.toml) |

[mise](https://mise.jdx.dev/) installs the pinned tools. A `prefix:` request tracks the newest patch on that minor line. tflint, sops, and age are exact releases because lectures 08.2 and 09.1 run those binaries.

```bash
mise install
terragrunt --version
terraform --version
tofu --version
tflint --version
sops --version
age --version
```

OpenTofu is installed with the others so section 12 is ready. Lectures before that section set `terraform_binary = "terraform"`. Section 12 sets it to `tofu`.

## How `start/` and `solution/` work

Every lecture lives at `labs/<section>/<lecture>/`:

```text
labs/03-core-hcl/03.2-locals-inputs/
  README.md    # title and goal
  start/       # where you do the work
  solution/    # the finished lab
```

1. Read the lecture `README.md`.
2. Work inside `start/`.
3. Open `solution/` when you want the finished files for that lecture.

Later lectures build on earlier ones. To jump ahead, begin from the previous lecture's `solution/`.

Labs are offline unless the title is marked ☁️. Offline labs use the `local`, `random`, or `null` provider and a local state backend.

## Labs that need AWS ☁️

Four lectures need an AWS account:

| Lecture | AWS is used for |
| --- | --- |
| [05.2 Backend bootstrap](labs/05-remote-state/05.2-backend-bootstrap/) | An S3 remote-state backend and `use_lockfile` locking. The checker validates the rendered config and does not call AWS |
| [09.2 Assume role](labs/09-secrets-multi-account/09.2-assume-role/) | Assuming an IAM role from a unit. The checker renders the config and does not call AWS |
| [09.3 Multi-account](labs/09-secrets-multi-account/09.3-multi-account/) | Deploying the same unit into two accounts. The checker renders both units and does not call AWS |
| [10.2 GitHub Actions OIDC](labs/10-cicd/10.2-gha-oidc/) | Letting GitHub Actions assume an AWS role with OIDC |

Keep credentials in your environment or in GitHub. The OIDC lecture is where cloud CI auth is introduced.

## Curriculum

### 01 · Setup

What Terragrunt is for, and how this repo is organized.

- [01.1 Why Terragrunt](labs/01-setup/01.1-why/)
- [01.2 Repo tour](labs/01-setup/01.2-repo-tour/)

### 02 · Install

Pin the CLIs and run a first unit.

- [02.1 Install](labs/02-install/02.1-install/)
- [02.2 First unit](labs/02-install/02.2-first-unit/)
- [02.3 CLI basics](labs/02-install/02.3-cli-basics/)

### 03 · Core HCL

`source`, inputs, functions, `generate`, and render.

- [03.1 Source](labs/03-core-hcl/03.1-source/)
- [03.2 Locals and inputs](labs/03-core-hcl/03.2-locals-inputs/)
- [03.3 Functions](labs/03-core-hcl/03.3-functions/)
- [03.4 Generate](labs/03-core-hcl/03.4-generate/)
- [03.5 fmt, validate, and render](labs/03-core-hcl/03.5-fmt-validate-render/)

### 04 · Include

Share one root configuration across units and environments.

- [04.1 Root include](labs/04-include/04.1-root-include/)
- [04.2 Merge](labs/04-include/04.2-merge/)
- [04.3 Multiple includes](labs/04-include/04.3-multi-include/)
- [04.4 Environment layout](labs/04-include/04.4-env-layout/)

### 05 · Remote state

A local backend first, then an S3 bootstrap for the cloud lab.

- [05.1 Remote state](labs/05-remote-state/05.1-remote-state/) — local backend
- [05.2 Backend bootstrap](labs/05-remote-state/05.2-backend-bootstrap/) ☁️ — S3
- [05.3 Terragrunt and workspaces](labs/05-remote-state/05.3-vs-workspaces/)

### 06 · Dependencies

Outputs between units, mocks, ordered runs, and the DAG.

- [06.1 Dependency](labs/06-dependencies/06.1-dependency/)
- [06.2 Mock outputs](labs/06-dependencies/06.2-mock-outputs/)
- [06.3 Run all](labs/06-dependencies/06.3-run-all/)
- [06.4 Find, list, and the DAG](labs/06-dependencies/06.4-find-list-dag/)
- [06.5 Scoping](labs/06-dependencies/06.5-scoping/)

### 07 · Stacks

Generate units from a stack file, a catalog, and scaffold.

- [07.1 Units vs stacks](labs/07-stacks/07.1-units-vs-stacks/)
- [07.2 Stack file](labs/07-stacks/07.2-stack-file/)
- [07.3 Values](labs/07-stacks/07.3-values/)
- [07.4 Stack generate](labs/07-stacks/07.4-stack-generate/)
- [07.5 Catalog](labs/07-stacks/07.5-catalog/)
- [07.6 Scaffold](labs/07-stacks/07.6-scaffold/)

### 08 · Hooks

Before and after hooks, tflint, and the `errors` block.

- [08.1 Hooks](labs/08-hooks/08.1-hooks/)
- [08.2 Lint hooks](labs/08-hooks/08.2-lint-hooks/)
- [08.3 Errors block](labs/08-hooks/08.3-errors-block/)

### 09 · Secrets and multi-account

SOPS on your machine. IAM and a second account only in the ☁️ labs.

- [09.1 SOPS](labs/09-secrets-multi-account/09.1-sops/)
- [09.2 Assume role](labs/09-secrets-multi-account/09.2-assume-role/) ☁️
- [09.3 Multi-account](labs/09-secrets-multi-account/09.3-multi-account/) ☁️

### 10 · CI/CD

Design the pipeline, then OIDC, plan on pull request, and apply on merge. The lab target is a local backend. Lecture 10.2 is the one that needs AWS, and its checker stays on the workflow files.

- [10.1 Design](labs/10-cicd/10.1-design/)
- [10.2 GitHub Actions OIDC](labs/10-cicd/10.2-gha-oidc/) ☁️
- [10.3 Plan on pull request](labs/10-cicd/10.3-plan-on-pr/)
- [10.4 Apply on merge](labs/10-cicd/10.4-apply-on-merge/)

### 11 · Migrate and troubleshoot

Move a 0.x queue onto `run --all`, the renamed flags, and stacks in place of `_envcommon`. Then read an ambiguous unit/stack directory with `--log-level debug` and `render`.

- [11.1 Migrate to 1.x](labs/11-migrate-troubleshoot/11.1-migrate-to-1x/)
- [11.2 Troubleshooting](labs/11-migrate-troubleshoot/11.2-troubleshooting/)

### 12 · Add-on: OpenTofu

Point Terragrunt at OpenTofu 1.13.x with `terraform_binary`, `--tf-path`, and `TG_TF_PATH`. Then compare `.tofu` files, the lock-file registry, and state encryption.

- [12.1 Switch to OpenTofu](labs/12-addon-opentofu/12.1-switch-to-tofu/)
- [12.2 OpenTofu specifics](labs/12-addon-opentofu/12.2-tofu-specifics/)

### 13 · Capstone

A dev and prod stack from the local catalog, planned and applied by a CI-shaped script. The AWS role step stays commented. The last lecture is a reading list.

- [13.1 Capstone](labs/13-capstone/13.1-capstone/)
- [13.2 Next](labs/13-capstone/13.2-next/)

## License

[MIT](LICENSE) © 2026 Ahmed Elfakharany.
