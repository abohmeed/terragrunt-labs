# 03.3 Functions

Read parent files from a unit with Terragrunt HCL functions. The parents live in this lab directory. Nothing is fetched from a network, and no AWS account is required.

## Goal

From `start/dev/unit`, make this succeed:

```bash
terragrunt run plan
```

The plan adds three resources. The prefix is `dev-local-lab`. One output is the unit path `dev/unit`.

## Layout

```text
start/
  root.hcl            # locals.course
  region.hcl          # locals.region
  dev/
    env.hcl           # locals.environment, locals.prefix_root
    unit/
      terragrunt.hcl
      modules/record/
```

`root.hcl`, `region.hcl`, and `env.hcl` are shared data. They are not named `terragrunt.hcl`, so Terragrunt does not run them as units. `find_in_parent_folders` walks upward from `dev/unit` until it finds the file name you pass.

| Function | Role in this unit |
| --- | --- |
| `find_in_parent_folders("root.hcl")` | Absolute path of the nearest parent `root.hcl` |
| `read_terragrunt_config(path)` | Parsed file. Locals are at `.locals` |
| `path_relative_to_include("root")` | `dev/unit`, relative to the included `root.hcl` |
| `get_env("LAB_NOTE", "offline functions lab")` | `LAB_NOTE` when it is set, otherwise the default |

An `include` block merges parent blocks such as `terraform` and `inputs` into the unit. It does not copy parent `locals` into the unit. `read_terragrunt_config` is how the unit reads those locals. The include is still required: `path_relative_to_include("root")` uses the include labeled `root`.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` keeps the engine on Terraform 1.17 when `tofu` is on `PATH`.
2. Read `start/root.hcl`, `start/region.hcl`, and `start/dev/env.hcl`. Leave them as they are.
3. Replace the TODOs in `start/dev/unit/terragrunt.hcl` with:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  root_cfg   = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  region_cfg = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_cfg    = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  course      = local.root_cfg.locals.course
  region      = local.region_cfg.locals.region
  environment = local.env_cfg.locals.environment
  prefix      = "${local.environment}-${local.region}-${local.env_cfg.locals.prefix_root}"
  unit_path   = path_relative_to_include("root")
  note        = get_env("LAB_NOTE", "offline functions lab")
}
```

Keep the `inputs` block that passes `course`, `region`, `environment`, `prefix`, `unit_path`, and `note`.

4. From `start/dev/unit`:

```bash
terragrunt run -- version
terragrunt run plan
```

The version line is Terraform 1.17.x. The plan is `Plan: 3 to add, 0 to change, 0 to destroy.` The pet prefix is `dev-local-lab`. The triggers include `course = "terragrunt-labs"`, `region = "local"`, `unit_path = "dev/unit"`, and `note = "offline functions lab"`.

5. Apply, read the outputs, then run again with `LAB_NOTE` set:

```bash
terragrunt --non-interactive run -- apply -auto-approve -input=false
terragrunt output
terragrunt --non-interactive run -- destroy -auto-approve -input=false

LAB_NOTE="from the environment" terragrunt --non-interactive run -- apply -auto-approve -input=false
terragrunt output
terragrunt --non-interactive run -- destroy -auto-approve -input=false
```

The first `note` output is `offline functions lab`. The second is `from the environment`. `get_env` uses the default only when `LAB_NOTE` is unset.

6. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  03.3 functions`.

The lock file next to the unit pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

## If plan stops early

- `find_in_parent_folders("TODO")` means the include path still needs `root.hcl`. The same file name is what `read_terragrunt_config` reads.
- `path_relative_to_include` requires the include labeled `root`. The label in `path_relative_to_include("root")` matches `include "root"`.
- A parent file named `terragrunt.hcl` would be a unit of its own. These parents are `root.hcl`, `region.hcl`, and `env.hcl`.

Compare your unit with [`solution/dev/unit/terragrunt.hcl`](solution/dev/unit/terragrunt.hcl). The parent files and the module match `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
