# 13.2 Next

You have a local multi-environment stack, a catalog, and a plan/apply script. This page is the follow-up list. There is no unit to change and nothing to apply.

From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  13.2 next`. The checker only reads this page.

## Stay on the local backend

- Re-run [13.1 Capstone](../13.1-capstone/) with `./scripts/plan.sh` when you want a clean pass of both environments.
- When a queue looks wrong, `terragrunt render --format json` shows the inputs after locals resolve (lecture 03.5). `--log-level debug` shows discovery, including a directory that is both a unit and a stack (lecture 11.2).
- Keep `terraform_binary = "terraform"` on every unit until you mean to change engines.

## When you have an AWS account

These lectures are marked ☁️ in the repo index. Their checkers still avoid calling AWS until you run the cloud step yourself.

- [05.2 Backend bootstrap](../../05-remote-state/05.2-backend-bootstrap/) moves state from the local backend onto S3 with `use_lockfile` locking.
- [09.2 Assume role](../../09-secrets-multi-account/09.2-assume-role/) assumes an IAM role from a unit.
- [09.3 Multi-account](../../09-secrets-multi-account/09.3-multi-account/) deploys the same unit into two accounts.
- [10.2 GitHub Actions OIDC](../../10-cicd/10.2-gha-oidc/) is the role step that 13.1 leaves commented. [10.3 Plan on pull request](../../10-cicd/10.3-plan-on-pr/) and [10.4 Apply on merge](../../10-cicd/10.4-apply-on-merge/) are the workflows with that step filled in.

## When you want OpenTofu

- [12.1 Switch to OpenTofu](../../12-addon-opentofu/12.1-switch-to-tofu/) sets `terraform_binary = "tofu"` and shows `--tf-path` and `TG_TF_PATH`. The pin is OpenTofu 1.13.x.
- [12.2 OpenTofu specifics](../../12-addon-opentofu/12.2-tofu-specifics/) covers `.tofu` files, the move to `registry.opentofu.org` in the lock file, and state encryption. That lecture does not turn encryption on.

## Pins

The repo root [`.mise.toml`](../../../.mise.toml) tracks Terragrunt 1.2.x, Terraform 1.17.x, and OpenTofu 1.13.x. From the repo root, `mise install` refreshes the patch versions on those lines.
