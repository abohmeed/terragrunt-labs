# 08.2 Lint hooks

Fail a unit before Terraform runs when tflint, `terraform fmt`, or the Checkov hook fails. No AWS account.

## Goal

From `start/`, make `./check.sh` pass.

`terragrunt run -- plan` in `unit/` prints `Tflint has run successfully. No issues found.`, runs `terraform fmt -check`, runs `hooks/checkov`, then plans `3 to add`.

## Pin tflint

tflint is not part of the Terragrunt install, and this repo does not commit the binary. The pin is an exact release in the repo root [`.mise.toml`](../../../.mise.toml):

```toml
tflint = "0.65.0"
```

From the repo root:

```bash
mise install
eval "$(mise activate bash)"
tflint --version
```

The version line is `TFLint version 0.65.0`. That release ships `ruleset.terraform` (0.15.0, bundled). `start/.tflint.hcl` turns three rules on and does not declare a `plugin` block, so the hook does not download a ruleset.

`./check.sh` installs that pin when `tflint` is missing. If the install fails, the checker still reads the hook text and skips the live plan.

## Checkov

Checkov is a Python application. It is not pinned in `.mise.toml`. The hook calls `hooks/checkov` with the same arguments a Checkov scan uses:

```text
-d . --framework terraform --quiet --compact
```

The script execs a real `checkov` binary when one is on `PATH`. Otherwise it is a one-pattern stand-in: a `.tf` file that contains `allow_all` fails the hook, and the record module passes. `allow_all` stands in for an overly open policy so the lab can run without the Python package.

## Why the checkov path is absolute

A `before_hook` runs in the module copy under `.terragrunt-cache`, not next to `terragrunt.hcl`. `./hooks/checkov` would not be found there. The hook builds an absolute path from `root.hcl`:

```hcl
"${dirname(find_in_parent_folders("root.hcl"))}/hooks/checkov"
```

`-d .` then scans the module copy. tflint is special: Terragrunt recognizes a bare `tflint` command, finds `.tflint.hcl` by walking up from the unit, and passes `inputs` as `--var`. An absolute path to tflint turns that integration off, so the hook uses `tflint` and not a filesystem path.

`terraform fmt -check -diff` also runs in the module copy. A diff fails the hook, and a failing `before_hook` never starts Terraform.

## Layout

```text
start/
  root.hcl                     # terraform_binary
  .tflint.hcl                  # rules. Leave it.
  hooks/checkov                # Checkov or the stand-in. Leave it.
  modules/record/
  unit/terragrunt.hcl          # three before_hooks go here
  unit/.terraform.lock.hcl
```

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1), then install the tflint pin above. `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17. The fmt hook calls the `terraform` binary on `PATH`.
2. Read `.tflint.hcl` and `hooks/checkov`. Leave both.
3. Replace the TODOs in `start/unit/terragrunt.hcl` with these blocks, inside `terraform` and after `source`:

```hcl
before_hook "tflint" {
  commands = ["plan", "apply"]
  execute  = ["tflint", "--minimum-failure-severity=error"]
}

before_hook "fmt" {
  commands = ["plan", "apply"]
  execute  = ["terraform", "fmt", "-check", "-diff"]
}

before_hook "checkov" {
  commands = ["plan", "apply"]
  execute = [
    "${dirname(find_in_parent_folders("root.hcl"))}/hooks/checkov",
    "-d", ".",
    "--framework", "terraform",
    "--quiet",
    "--compact",
  ]
}
```

`--minimum-failure-severity=error` keeps a tflint warning from blocking the plan. An error still fails the hook.

4. From `start/`:

```bash
terragrunt --working-dir unit run -- version
terragrunt --working-dir unit run -- plan
```

The version line is Terraform 1.17.x. tflint reports no issues. fmt prints nothing. The checkov script prints `checkov stub: no findings` when the real binary is absent. The plan is `Plan: 3 to add, 0 to change, 0 to destroy.` and `note` is `lint hooks`.

5. From `start/`:

```bash
./check.sh
```

The last line is `PASS  08.2 lint hooks`. The script also runs the stand-in against a throwaway file that contains `allow_all` and expects that run to fail.

The lock file pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

## If plan stops early

- `tflint: command not found` means the pin is not on `PATH`. From the repo root, `mise install` and `eval "$(mise activate bash)"`.
- A fmt diff names the file. From `modules/record`, run `terraform fmt`, then plan again.
- `checkov stub: found allow_all` means a `.tf` file in the module copy contains that token. Take it out.
- An absolute `execute` path for tflint skips Terragrunt's plugin init and `--var` handling. Keep the command as `tflint`.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`. The fmt hook would then be calling Terraform while the unit runs OpenTofu.
- `hcl fmt --check` fails when the blocks are not aligned with the snippet. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your unit with [`solution/unit/terragrunt.hcl`](solution/unit/terragrunt.hcl). The module, `.tflint.hcl`, and `hooks/checkov` match `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
