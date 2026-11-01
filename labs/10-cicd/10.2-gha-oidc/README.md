# 10.2 GitHub Actions OIDC ☁️

Let GitHub Actions assume an AWS role with OIDC. The workflow stores no access keys. Credentials stay with GitHub's token service until a job asks for them.

This lecture needs an AWS account to create the provider and the roles. `./check.sh` does not call AWS. It reads the workflow and the two trust policies. Run the checker before you spend time on credentials.

## Goal

From `start/`, make `./check.sh` pass.

You finish three files:

| File | AWS uses it for |
| --- | --- |
| `iam/plan-trust.json` | The role a pull request may assume |
| `iam/apply-trust.json` | The role a push to `main` may assume |
| `.github/workflows/oidc.yml` | Asking GitHub for an OIDC token and exchanging it |

`root.hcl` already sets `terraform_binary = "terraform"`. Leave that line. This lecture does not plan a unit.

## What the token proves

GitHub's issuer is `https://token.actions.githubusercontent.com`. A job with `permissions.id-token: write` can request a token. AWS checks two claims:

| Claim | Plan role | Apply role |
| --- | --- | --- |
| `aud` | `sts.amazonaws.com` | `sts.amazonaws.com` |
| `sub` | `repo:OWNER/REPO:pull_request` | `repo:OWNER/REPO:ref:refs/heads/main` |

The action on the role is `sts:AssumeRoleWithWebIdentity`. `StringEquals` keeps the subject exact. A `StringLike` value of `repo:OWNER/REPO:*` would let a pull request assume the apply role. This lecture does not do that.

The workflow reads the role ARNs from repository variables, `vars.AWS_PLAN_ROLE_ARN` and `vars.AWS_APPLY_ROLE_ARN`. A variable is not a credential. The token is the credential, and it lasts for the job.

## Layout

```text
start/
  root.hcl
  check.sh
  iam/plan-trust.json
  iam/apply-trust.json
  .github/workflows/oidc.yml
```

Treat `start/` as the repository root when you read the workflow paths. The file in this lecture is the file you would commit at `.github/workflows/oidc.yml`.

## Offline steps

Do these before you use AWS. They are what `./check.sh` runs.

1. Install the pinned CLIs if you have not (lecture 02.1). The checker formats `root.hcl` and confirms `terraform_binary = "terraform"`.
2. Replace the TODOs in `iam/plan-trust.json`. The principal is the GitHub OIDC provider in account `123456789012`. The subject is `repo:OWNER/REPO:pull_request`. The audience is `sts.amazonaws.com`. The action is `sts:AssumeRoleWithWebIdentity`.
3. Use the same document for `iam/apply-trust.json`, with the subject `repo:OWNER/REPO:ref:refs/heads/main` and `Sid` `ApplyFromMain`.
4. Replace the TODOs in `.github/workflows/oidc.yml`. The workflow runs on `workflow_dispatch`. Permissions are `id-token: write` and `contents: read`. Two jobs, `plan-auth` and `apply-auth`, each check out with `actions/checkout@v7.0.1` and assume a role with `aws-actions/configure-aws-credentials@v6.3.0`:

```yaml
- name: Assume the plan role
  uses: aws-actions/configure-aws-credentials@v6.3.0
  with:
    role-to-assume: ${{ vars.AWS_PLAN_ROLE_ARN }}
    aws-region: us-east-1
    role-session-name: terragrunt-plan
```

The apply job uses `vars.AWS_APPLY_ROLE_ARN` and `role-session-name: terragrunt-apply`. Each job then runs `aws sts get-caller-identity`.

The checker accepts any 12-digit account id and any `org/name` in the subject. The files ship with `123456789012` and `OWNER/REPO` so they parse before you have a repository. Put your account and repository in before the AWS steps. The checker rejects a `*` in the subject.

5. From `start/`, run:

```bash
./check.sh
```

The last lines are:

```text
PASS  10.2 github actions oidc
AWS was not contacted. Follow the README to create the provider and the roles when you have an account.
```

The checker needs `python3` and PyYAML (`python3 -c 'import yaml'`). On Debian and Ubuntu that package is `python3-yaml`.

## AWS steps ☁️

Use a sandbox account. The identity that creates the provider and the roles is yours. The workflow's identity is the role it assumes. Keep that identity in the environment for the setup commands (`AWS_PROFILE`, or `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`). Do not commit those values, and do not put them in the workflow.

1. In the account, create an IAM OIDC provider. The URL is `https://token.actions.githubusercontent.com`. The audience is `sts.amazonaws.com`. The AWS console fills in the thumbprint. Copy the thumbprint from the console or from GitHub's current OIDC documentation when you use the CLI. Leave the thumbprint out of git.
2. Create two roles. The trust policy of each role is the matching JSON file after you replace the account id and `OWNER/REPO`. The plan role's permissions are the read actions a plan needs. The apply role's permissions are the actions an apply needs. This lecture stops at the trust policy. It does not attach `AdministratorAccess`.
3. In the GitHub repository, add variables `AWS_PLAN_ROLE_ARN` and `AWS_APPLY_ROLE_ARN`. Variables, not secrets. The values are role ARNs.
4. Commit the workflow at `.github/workflows/oidc.yml` on the repository you named in the subject. Run it with **workflow_dispatch**. `aws sts get-caller-identity` prints the assumed role. `plan-auth` can run from a pull request only after the plan workflow in lecture 10.3 calls the same step. This lecture's workflow is the auth check, on demand.

## If the checker or the job stops early

- `id-token: read` cannot request a token. The permission is `write`, and that write is the right to request the token.
- A workflow that still contains `AWS_ACCESS_KEY_ID` or `aws-access-key-id` is using stored keys. Remove them.
- `Not authorized to perform sts:AssumeRoleWithWebIdentity` means the subject in the token does not match the trust policy. A pull request token's subject ends in `:pull_request`. A push to `main` ends in `:ref:refs/heads/main`.
- The checker fails on `TODO`, on a `*` in the JSON, and on `StringLike`.
- `hcl fmt --check` fails when `root.hcl` drifted. From `start/`, run `terragrunt hcl fmt`.

Compare your files with [`solution/iam/plan-trust.json`](solution/iam/plan-trust.json), [`solution/iam/apply-trust.json`](solution/iam/apply-trust.json), and [`solution/.github/workflows/oidc.yml`](solution/.github/workflows/oidc.yml). What the checker prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
