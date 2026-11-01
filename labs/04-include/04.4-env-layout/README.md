# 04.4 Environment layout

Lay one account out as `account/region/env/unit`. Dev and prod are sibling environments. They include the same root and run the same unit file. `env.hcl` is what changes. No AWS account.

## Goal

From `start/sandbox/local/dev/record` and from `start/sandbox/local/prod/record`, make this succeed:

```bash
terragrunt run plan
```

Each plan adds three resources. Dev uses the prefix `sandbox-dev-lab`. Prod uses `sandbox-prod-lab`. The two `terragrunt.hcl` files match. `unit_path` is `sandbox/local/dev/record` or `sandbox/local/prod/record`.

## Layout

The path has four levels. A later cloud lab would use a region such as `us-east-1`. This lab uses `local` so nothing leaves the machine.

```text
start/
  root.hcl                                  # locals.course, terraform_binary
  modules/record/                           # one module, shared by both units
  sandbox/                                  # account
    account.hcl                             # locals.account_name
    local/                                  # region
      region.hcl                            # locals.region
      dev/                                  # environment
        env.hcl
        record/terragrunt.hcl               # unit
      prod/
        env.hcl
        record/terragrunt.hcl               # same file as dev
```

| Level | Directory | File | Value this lab sets |
| --- | --- | --- | --- |
| Account | `sandbox/` | `account.hcl` | `account_name = "sandbox"` |
| Region | `sandbox/local/` | `region.hcl` | `region = "local"` |
| Environment | `sandbox/local/dev/` or `prod/` | `env.hcl` | `environment` and `prefix_root` |
| Unit | `.../record/` | `terragrunt.hcl` | Includes the four parents and passes inputs |

`find_in_parent_folders` walks upward from the unit until it finds the file name you pass. `account.hcl` is three directories up. `root.hcl` is four.

The includes follow lecture 04.3. Expose every parent. Merge `root`, because that file holds `terraform_binary`. Use `no_merge` on `account`, `region`, and `env`. Those files are data.

The module lives once, next to `root.hcl`. The unit source is that directory:

```hcl
source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"
```

`dirname` of the root file is `start/` while you work there, and `solution/` when you run the finished lab. The same line works in both copies.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). The unit does not set `terraform_binary`. The root include merges it from `root.hcl`.
2. Read `root.hcl`, `sandbox/account.hcl`, `sandbox/local/region.hcl`, and both `env.hcl` files. Leave them as they are. Dev sets `environment = "dev"`. Prod sets `environment = "prod"`. Both set `prefix_root = "lab"`.
3. Replace the TODOs in `start/sandbox/local/dev/record/terragrunt.hcl` with:

```hcl
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "account" {
  path           = find_in_parent_folders("account.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

include "region" {
  path           = find_in_parent_folders("region.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

locals {
  course      = include.root.locals.course
  account     = include.account.locals.account_name
  region      = include.region.locals.region
  environment = include.env.locals.environment
  prefix      = "${local.account}-${local.environment}-${include.env.locals.prefix_root}"
  unit_path   = path_relative_to_include("root")
}
```

Keep the `terraform` block and the `inputs` block that are already in the file.

4. Copy that `terragrunt.hcl` over `start/sandbox/local/prod/record/terragrunt.hcl`. The files stay identical. Prod reads `prod/env.hcl` because `find_in_parent_folders("env.hcl")` stops at the first parent with that name.

5. From the dev unit, then from the prod unit:

```bash
terragrunt run -- version
terragrunt render
terragrunt run plan
```

The version line is Terraform 1.17.x. Dev render shows `account = "sandbox"`, `region = "local"`, `environment = "dev"`, `prefix = "sandbox-dev-lab"`, and `unit_path = "sandbox/local/dev/record"`. Prod shows `environment = "prod"`, `prefix = "sandbox-prod-lab"`, and `unit_path = "sandbox/local/prod/record"`. Each plan is `Plan: 3 to add, 0 to change, 0 to destroy.`

`course` is `terragrunt-labs` in both. Each unit has its own `.terragrunt-cache` and its own state.

The lock file next to each unit pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan in a unit downloads those providers. You do not need AWS credentials.

6. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  04.4 environment layout`. The script plans, applies, and destroys both units.

## If plan stops early

- `include.account` is unknown when that include is missing `expose = true`. The same applies to `root`, `region`, and `env`.
- `OpenTofu` from `terragrunt run -- version` means the root include used `no_merge`. Leave `no_merge` on `account`, `region`, and `env` only.
- `environment = "dev"` inside the prod unit means prod is including `dev/env.hcl`. `find_in_parent_folders` should find `sandbox/local/prod/env.hcl` first. Put the prod unit at `sandbox/local/prod/record/`.
- A source path that cannot find `modules/record` means `dirname(find_in_parent_folders("root.hcl"))` was replaced with a `../` count that stops short.
- The checker fails when the two `terragrunt.hcl` files differ. Change `env.hcl`, and keep the unit files the same.
- `hcl fmt --check` fails when the include arguments are not aligned. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your unit with [`solution/sandbox/local/dev/record/terragrunt.hcl`](solution/sandbox/local/dev/record/terragrunt.hcl). The prod unit is the same file. The parent files and the module match `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
