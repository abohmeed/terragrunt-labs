# 04.3 Multiple includes

Include more than one parent from a single unit, expose each parent, and read its values with `include.<label>`. No AWS account.

## Goal

From `start/dev/unit`, make this succeed:

```bash
terragrunt run plan
```

The plan adds three resources. The prefix is `dev-local-lab`. One output is the unit path `dev/unit`. `course` comes from `root.hcl`, `region` from `region.hcl`, and `environment` from `dev/env.hcl`.

## Layout

```text
start/
  root.hcl            # locals.course, terraform_binary
  region.hcl          # locals.region
  dev/
    env.hcl           # locals.environment, locals.prefix_root
    unit/
      terragrunt.hcl
      modules/record/
```

The parents are not named `terragrunt.hcl`, so Terragrunt does not run them as units.

Lecture 03.3 reads these same shapes of file with `read_terragrunt_config`. This lecture exposes the include instead. `expose = true` makes the parsed parent available as `include.<label>`. Parent `locals` are still not copied into the unit. You read them:

```hcl
course = include.root.locals.course
```

| Include | Merge | Why |
| --- | --- | --- |
| `root` | default `shallow` | `terraform_binary` in `root.hcl` has to reach the unit |
| `region` | `no_merge` | The file is data. Expose it, and do not merge blocks it might gain later |
| `env` | `no_merge` | Same as `region` |

`path_relative_to_include("root")` uses the include labeled `root`. With more than one include, pass the label.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). The unit does not set `terraform_binary`. The root include merges `terraform_binary = "terraform"` from `root.hcl`.
2. Read `start/root.hcl`, `start/region.hcl`, and `start/dev/env.hcl`. Leave them as they are.
3. Replace the TODOs in `start/dev/unit/terragrunt.hcl` with:

```hcl
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
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
  region      = include.region.locals.region
  environment = include.env.locals.environment
  prefix      = "${local.environment}-${local.region}-${include.env.locals.prefix_root}"
  unit_path   = path_relative_to_include("root")
  note        = "exposed includes"
}
```

Keep the `inputs` block that passes `course`, `region`, `environment`, `prefix`, `unit_path`, and `note`.

4. From `start/dev/unit`:

```bash
terragrunt run -- version
terragrunt render
terragrunt run plan
```

The version line is Terraform 1.17.x. The render shows `course = "terragrunt-labs"`, `region = "local"`, `environment = "dev"`, `prefix = "dev-local-lab"`, `unit_path = "dev/unit"`, and `note = "exposed includes"`. The plan is `Plan: 3 to add, 0 to change, 0 to destroy.`

5. Apply, read the outputs, and destroy:

```bash
terragrunt --non-interactive run -- apply -auto-approve -input=false
terragrunt output
terragrunt --non-interactive run -- destroy -auto-approve -input=false
```

`name` is `dev-local-lab-<word>-<word>`.

The lock file next to the unit pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

6. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  04.3 multiple includes`.

## If plan stops early

- `include.root` is unknown when that include is missing `expose = true`. The same applies to `include.region` and `include.env`.
- `path_relative_to_include` requires the include labeled `root`. The label in the function matches `include "root"`.
- `OpenTofu` from `terragrunt run -- version` means the root include used `no_merge`, so `terraform_binary` stayed in `root.hcl`. Leave `no_merge` on `region` and `env` only.
- A parent file named `terragrunt.hcl` would be a unit of its own. These parents are `root.hcl`, `region.hcl`, and `env.hcl`.
- `hcl fmt --check` fails when the include arguments are not aligned. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your unit with [`solution/dev/unit/terragrunt.hcl`](solution/dev/unit/terragrunt.hcl). The parent files and the module match `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
