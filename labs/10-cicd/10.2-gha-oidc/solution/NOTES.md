# 10.2 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  10.2 github actions oidc
AWS was not contacted. Follow the README to create the provider and the roles when you have an account.
```

The checker does not call AWS. It does not run the workflow.

`root.hcl` holds `terraform_binary = "terraform"`.

`iam/plan-trust.json` trusts `repo:OWNER/REPO:pull_request`. `iam/apply-trust.json` trusts `repo:OWNER/REPO:ref:refs/heads/main`. Both use `sts:AssumeRoleWithWebIdentity`, audience `sts.amazonaws.com`, and the GitHub OIDC provider in account `123456789012`. The checker accepts any 12-digit account and any `org/name`. It rejects `*` and `StringLike`.

`.github/workflows/oidc.yml` runs on `workflow_dispatch`. Permissions are `id-token: write` and `contents: read`. `plan-auth` assumes `vars.AWS_PLAN_ROLE_ARN`. `apply-auth` assumes `vars.AWS_APPLY_ROLE_ARN`. Both use `aws-actions/configure-aws-credentials@v6.3.0`, region `us-east-1`, and `aws sts get-caller-identity`. The file has no access key.

What the checker shows:

1. `terragrunt hcl fmt --check` passes.
2. Both trust policies parse and match the subjects above.
3. The workflow parses, requests an OIDC token, and names both roles.

With an account, the console creates the OIDC provider for `https://token.actions.githubusercontent.com`. Each role uses one trust file. Repository variables hold the role ARNs. `workflow_dispatch` then prints the assumed role from `aws sts get-caller-identity`.
