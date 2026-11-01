# Terragrunt for DevOps: Scale Your Terraform Workflows — Script index

Targets: Terragrunt 1.2.x, Terraform 1.17.x, OpenTofu 1.13.x (section 12). Lab repo: https://github.com/abohmeed/terragrunt-labs (`labs/`).
Markers used: `[pause Ns]`, `[breath]` only. ☁️ = needs an AWS account for the cloud step (checkers stay offline).

**44 lectures · ~229 min estimated (~20,373 narration words)**


## Section 01 · Introduction (6 min)

| Lecture | File | Min | Words | Lab path |
|---|---|---|---|---|
| 01.1 Why Terragrunt | [01.1-why-terragrunt.md](01.1-why-terragrunt.md) | 3 | 482 | `labs/01-setup/01.1-why/` (filled) |
| 01.2 Lab repo tour | [01.2-repo-tour.md](01.2-repo-tour.md) | 3 | 380 | `labs/01-setup/01.2-repo-tour/` (filled) · repo root `README.md`, `.mise.toml` |

## Section 02 · Getting started (15 min)

| Lecture | File | Min | Words | Lab path |
|---|---|---|---|---|
| 02.1 Pin installs (mise / tenv) | [02.1-install.md](02.1-install.md) | 4 | 354 | `labs/02-install/02.1-install/` (`start/check-versions.sh`, `solution/NOTES.md`) |
| 02.2 First `terragrunt.hcl` | [02.2-first-unit.md](02.2-first-unit.md) | 6 | 506 | `labs/02-install/02.2-first-unit/` (`start/terragrunt.hcl`, `start/modules/marker/`) |
| 02.3 `run` and the 1.x CLI flags | [02.3-cli-basics.md](02.3-cli-basics.md) | 5 | 446 | `labs/02-install/02.3-cli-basics/` (`start/exercises.sh`, `solution/NOTES.md`) |

## Section 03 · Configuration basics (22 min)

| Lecture | File | Min | Words | Lab path |
|---|---|---|---|---|
| 03.1 `terraform { source }` and the `//` separator | [03.1-source.md](03.1-source.md) | 4 | 382 | `labs/03-core-hcl/03.1-source/` (`start/terragrunt.hcl`, `start/modules/service/main.tf`, `check.sh`) |
| 03.2 `locals` and `inputs` | [03.2-locals-inputs.md](03.2-locals-inputs.md) | 4 | 363 | `labs/03-core-hcl/03.2-locals-inputs/` (`start/dev/`, `start/prod/`, `start/modules/record/`) |
| 03.3 Built-in functions | [03.3-functions.md](03.3-functions.md) | 5 | 426 | `labs/03-core-hcl/03.3-functions/` (`start/root.hcl`, `start/region.hcl`, `start/dev/env.hcl`, `start/dev/unit/terragrunt.hcl`) |
| 03.4 `generate` blocks | [03.4-generate.md](03.4-generate.md) | 4 | 401 | `labs/03-core-hcl/03.4-generate/` (`start/terragrunt.hcl`, `start/modules/note/`) |
| 03.5 `hcl fmt`, `hcl validate`, and `render` | [03.5-fmt-validate-render.md](03.5-fmt-validate-render.md) | 5 | 423 | `labs/03-core-hcl/03.5-fmt-validate-render/` (`start/terragrunt.hcl`, `start/modules/record/`) |

## Section 04 · DRY with include (25 min)

| Lecture | File | Min | Words | Lab path |
|---|---|---|---|---|
| 04.1 `root.hcl` + `include` | [04.1-root-include.md](04.1-root-include.md) | 5 | 443 | `labs/04-include/04.1-root-include/` (`start/root.hcl`, `start/unit/terragrunt.hcl`) |
| 04.2 Merge strategies | [04.2-merge-strategies.md](04.2-merge-strategies.md) | 6 | 508 | `labs/04-include/04.2-merge/` (`start/root.hcl`, `start/shallow/`, `start/deep/`, `start/no_merge/`) |
| 04.3 Multiple includes | [04.3-multi-include.md](04.3-multi-include.md) | 6 | 415 | `labs/04-include/04.3-multi-include/` (`start/root.hcl`, `start/region.hcl`, `start/dev/env.hcl`, `start/dev/unit/terragrunt.hcl`) |
| 04.4 Account / region / env / unit layout | [04.4-env-layout.md](04.4-env-layout.md) | 8 | 601 | `labs/04-include/04.4-env-layout/` (`start/sandbox/local/{dev,prod}/record/terragrunt.hcl`, `account.hcl`, `region.hcl`, `env.hcl`) |

## Section 05 · Remote state (20 min)

| Lecture | File | Min | Words | Lab path |
|---|---|---|---|---|
| 05.1 `remote_state` (local backend) | [05.1-remote-state-local.md](05.1-remote-state-local.md) | 6 | 461 | `labs/05-remote-state/05.1-remote-state/` (`start/root.hcl`, `start/dev/`, `start/prod/`) |
| 05.2 `backend bootstrap` + S3 / `use_lockfile` ☁️ | [05.2-backend-bootstrap-s3.md](05.2-backend-bootstrap-s3.md) | 8 | 678 | `labs/05-remote-state/05.2-backend-bootstrap/` (`start/root.hcl`, `start/dev/`, `start/prod/`) — AWS needed for bootstrap/apply; `check.sh` is offline |
| 05.3 Directories vs Terraform workspaces | [05.3-vs-workspaces.md](05.3-vs-workspaces.md) | 6 | 531 | `labs/05-remote-state/05.3-vs-workspaces/` (`start/layout/`, `start/workspaces/main.tf`) |

## Section 06 · Dependencies & run --all (25 min)

| Lecture | File | Min | Words | Lab path |
|---|---|---|---|---|
| 06.1 `dependency` blocks | [06.1-dependency.md](06.1-dependency.md) | 5 | 382 | `labs/06-dependencies/06.1-dependency/` (`start/network/`, `start/service/terragrunt.hcl`) |
| 06.2 Mock outputs | [06.2-mock-outputs.md](06.2-mock-outputs.md) | 5 | 362 | `labs/06-dependencies/06.2-mock-outputs/` (`start/service/terragrunt.hcl`) |
| 06.3 `run --all` and `--graph` | [06.3-run-all-graph.md](06.3-run-all-graph.md) | 6 | 498 | `labs/06-dependencies/06.3-run-all/` (`start/network/`, `start/database/`, `start/service/`) |
| 06.4 `find`, `list`, and `dag graph` | [06.4-find-list-dag.md](06.4-find-list-dag.md) | 4 | 340 | `labs/06-dependencies/06.4-find-list-dag/` (`start/` — network, database, service, audit) |
| 06.5 Safe scoping and the destroy trap | [06.5-scoping-destroy-trap.md](06.5-scoping-destroy-trap.md) | 5 | 500 | `labs/06-dependencies/06.5-scoping/` (`start/network/`, `start/apps/{api,worker,legacy}/`) |

## Section 07 · Stacks & catalog (28 min)

| Lecture | File | Min | Words | Lab path |
|---|---|---|---|---|
| 07.1 Units vs stacks (and why `_envcommon` goes away) | [07.1-units-vs-stacks.md](07.1-units-vs-stacks.md) | 4 | 434 | `labs/07-stacks/07.1-units-vs-stacks/` (`start/units/record/`, `start/stack/terragrunt.stack.hcl`, `start/_envcommon/`, `start/legacy/`) |
| 07.2 `terragrunt.stack.hcl` | [07.2-stack-file.md](07.2-stack-file.md) | 5 | 361 | `labs/07-stacks/07.2-stack-file/` (`start/live/terragrunt.stack.hcl`, `start/blueprints/platform/`, `start/units/record/`) |
| 07.3 `values` and `autoinclude` | [07.3-values.md](07.3-values.md) | 5 | 491 | `labs/07-stacks/07.3-values/` (`start/live/terragrunt.stack.hcl`, `start/units/record/terragrunt.values.hcl`) |
| 07.4 `stack generate`, `stack run`, `stack output`, `stack clean` | [07.4-stack-generate.md](07.4-stack-generate.md) | 5 | 416 | `labs/07-stacks/07.4-stack-generate/` (`start/live/terragrunt.stack.hcl` — finished) |
| 07.5 Catalog | [07.5-catalog.md](07.5-catalog.md) | 4 | 392 | `labs/07-stacks/07.5-catalog/` (`start/root.hcl`, `start/catalog/`, `start/live/terragrunt.stack.hcl`) |
| 07.6 `catalog` and `scaffold` | [07.6-catalog-scaffold.md](07.6-catalog-scaffold.md) | 5 | 504 | `labs/07-stacks/07.6-scaffold/` (`start/live/terragrunt.values.hcl`, `start/stamped/terragrunt.values.hcl`, `start/catalog/`) |

## Section 08 · Hooks & errors (15 min)

| Lecture | File | Min | Words | Lab path |
|---|---|---|---|---|
| 08.1 Before, after, and error hooks | [08.1-hooks.md](08.1-hooks.md) | 5 | 439 | `labs/08-hooks/08.1-hooks/` (`start/unit/terragrunt.hcl`, `start/modules/record/`) |
| 08.2 tflint, fmt, and Checkov as quality gates | [08.2-lint-hooks.md](08.2-lint-hooks.md) | 5 | 494 | `labs/08-hooks/08.2-lint-hooks/` (`start/unit/terragrunt.hcl`, `start/.tflint.hcl`, `start/hooks/checkov`) |
| 08.3 The `errors` block: retry and ignore | [08.3-errors-block.md](08.3-errors-block.md) | 5 | 463 | `labs/08-hooks/08.3-errors-block/` (`start/retry/terragrunt.hcl`, `start/ignore/terragrunt.hcl`, `start/modules/{flaky,drift}/`) |

## Section 09 · Secrets & multi-account (20 min)

| Lecture | File | Min | Words | Lab path |
|---|---|---|---|---|
| 09.1 SOPS + `get_env` with a local age key | [09.1-sops-get-env.md](09.1-sops-get-env.md) | 7 | 628 | `labs/09-secrets-multi-account/09.1-sops/` (`start/secrets.example.yaml`, `start/unit/terragrunt.hcl`) |
| 09.2 `iam_role` — assume a role from a unit ☁️ | [09.2-iam-role.md](09.2-iam-role.md) | 6 | 555 | `labs/09-secrets-multi-account/09.2-assume-role/` (`start/root.hcl`, `start/unit/`) — AWS needed for plan/apply; `check.sh` is offline |
| 09.3 Multi-account layout ☁️ | [09.3-multi-account.md](09.3-multi-account.md) | 7 | 704 | `labs/09-secrets-multi-account/09.3-multi-account/` (`start/{dev,prod}/account.hcl`, `start/{dev,prod}/us-east-1/record/terragrunt.hcl`) — two AWS accounts for bootstrap/apply; `check.sh` is offline |

## Section 10 · CI/CD (22 min)

| Lecture | File | Min | Words | Lab path |
|---|---|---|---|---|
| 10.1 Pipeline design: plan on PR, apply on merge | [10.1-pipeline-design.md](10.1-pipeline-design.md) | 5 | 563 | `labs/10-cicd/10.1-design/` (`start/design.md`, `start/diagram.mmd`, `start/sample/root.hcl`, `start/sample/.github/workflows/pipeline.yml`) |
| 10.2 GitHub Actions + OIDC ☁️ | [10.2-gha-oidc.md](10.2-gha-oidc.md) | 6 | 517 | `labs/10-cicd/10.2-gha-oidc/` (`start/iam/plan-trust.json`, `start/iam/apply-trust.json`, `start/.github/workflows/oidc.yml`) — AWS needed to create provider/roles; `check.sh` is offline |
| 10.3 Plan on pull request | [10.3-plan-on-pr.md](10.3-plan-on-pr.md) | 5 | 485 | `labs/10-cicd/10.3-plan-on-pr/` (`start/scripts/plan.sh`, `start/scripts/plan-comment.sh`, `start/.github/workflows/plan.yml`) |
| 10.4 Apply on merge | [10.4-apply-on-merge.md](10.4-apply-on-merge.md) | 6 | 541 | `labs/10-cicd/10.4-apply-on-merge/` (`start/scripts/apply.sh`, `start/.github/workflows/apply.yml`) |

## Section 11 · Migration & troubleshooting (15 min)

| Lecture | File | Min | Words | Lab path |
|---|---|---|---|---|
| 11.1 Migrating a 0.x codebase to Terragrunt 1.x | [11.1-migrate-to-1x.md](11.1-migrate-to-1x.md) | 8 | 560 | `labs/11-migrate-troubleshoot/11.1-migrate-to-1x/` (`start/legacy/`, `start/live/*/terragrunt.stack.hcl`, `start/scripts/queue.sh`, `start/flags.md`) |
| 11.2 Troubleshooting | [11.2-troubleshooting.md](11.2-troubleshooting.md) | 7 | 544 | `labs/11-migrate-troubleshoot/11.2-troubleshooting/` (`start/live/`, `start/scripts/debug.sh`) |

## Section 12 · Add-on: OpenTofu (8 min)

| Lecture | File | Min | Words | Lab path |
|---|---|---|---|---|
| 12.1 Switching the engine to OpenTofu | [12.1-switch-to-tofu.md](12.1-switch-to-tofu.md) | 4 | 299 | `labs/12-addon-opentofu/12.1-switch-to-tofu/` (`start/root.hcl`, `start/scripts/engines.sh`) |
| 12.2 OpenTofu specifics | [12.2-tofu-specifics.md](12.2-tofu-specifics.md) | 4 | 357 | `labs/12-addon-opentofu/12.2-tofu-specifics/` (`start/modules/record/engine.tofu`, `start/differences.md`) |

## Section 13 · Capstone (8 min)

| Lecture | File | Min | Words | Lab path |
|---|---|---|---|---|
| 13.1 Capstone: dev + prod from a catalog, CI-shaped | [13.1-capstone.md](13.1-capstone.md) | 6 | 549 | `labs/13-capstone/13.1-capstone/` (`start/live/{dev,prod}/terragrunt.stack.hcl`, `start/scripts/plan.sh`, `start/scripts/apply.sh`, `start/.github/workflows/`) |
| 13.2 Where to go next | [13.2-next.md](13.2-next.md) | 2 | 195 | `labs/13-capstone/13.2-next/` (read-only page; `./check.sh` only reads it) |

## Notes / gaps

- Section 01 labs are stubs (README TODO). 01.1 and 01.2 are conceptual and use the root README.
- Lecture numbers follow the repo (10.1–10.4, 11.1–11.2, 12.1–12.2, 13.1–13.2) where they differ from the locked curriculum.
- Optional 'break it' demos not in the READMEs. Verify them while recording: 03.5 (a `colour` input), 08.2 (an extra space to trip the fmt gate), 07.5 (an example git URL with `?ref`).
- ☁️ lectures (05.2, 09.2, 09.3, 10.2, plus the role step in 10.4) were scripted against the offline checkers. The AWS steps still need a real run to capture on screen.
- The DevCloudLab Hugo posts use 0.x patterns (a root `terragrunt.hcl`, DynamoDB locking), so they were used only for framing.
