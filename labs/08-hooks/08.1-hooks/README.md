# 08.1 Hooks

Run a command before Terraform, after Terraform, and when Terraform fails. No AWS account.

## Goal

From `start/`, make `./check.sh` pass.

A successful plan prints `before hook: plan starts` and `after hook: plan finished`. `terragrunt run -- plan -var note=fail` still prints the before hook, then prints `error hook: plan failed`, and does not print the after hook.

## What each hook does

Hooks live inside the `terraform` block. They run for the commands listed in `commands`.

| Block | When it runs |
| --- | --- |
| `before_hook` | Before Terraform. A non-zero status skips Terraform and skips an `after_hook` whose `run_on_error` is not true |
| `after_hook` | After Terraform. `run_on_error = false` skips it when Terraform fails |
| `error_hook` | After a Terraform failure whose output matches `on_errors`. A match does not turn the failure into a success |

`on_errors` is a list of regular expressions. `.*deliberate plan failure.*` matches the validation message on `var.note`.

The module rejects `note = "fail"` with that message. Every other note plans three resources.

## Layout

```text
start/
  root.hcl                     # terraform_binary
  modules/record/              # finished. note = "fail" does not plan.
  unit/terragrunt.hcl          # hooks go here
  unit/.terraform.lock.hcl
```

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17.
2. Leave `modules/record` as it is. Read the validation on `var.note`.
3. Replace the TODOs in `start/unit/terragrunt.hcl` with these blocks, inside `terraform` and after `source`:

```hcl
before_hook "stamp_start" {
  commands = ["plan", "apply"]
  execute  = ["echo", "before hook: plan starts"]
}

after_hook "stamp_done" {
  commands     = ["plan", "apply"]
  execute      = ["echo", "after hook: plan finished"]
  run_on_error = false
}

error_hook "stamp_error" {
  commands  = ["plan", "apply"]
  execute   = ["echo", "error hook: plan failed"]
  on_errors = [".*deliberate plan failure.*"]
}
```

`execute` is the command and its arguments. `echo` is enough here. The hook prints one line, and the checker looks for that line.

4. From `start/`:

```bash
terragrunt --working-dir unit run -- version
terragrunt --working-dir unit run -- plan
```

The version line is Terraform 1.17.x. The plan is `Plan: 3 to add, 0 to change, 0 to destroy.` and `note` is `hooks lab`. The log contains the before hook and the after hook. It does not contain the error hook.

5. Fail the plan on purpose:

```bash
terragrunt --working-dir unit run -- plan -var note=fail
```

Terraform exits non-zero and prints `deliberate plan failure`. The before hook has already run. The error hook runs because the output matches `on_errors`. The after hook does not run, because `run_on_error` is false.

`-var note=fail` overrides the `inputs` value for this one command. The file stays `note = "hooks lab"`.

6. From `start/`:

```bash
./check.sh
```

The last line is `PASS  08.1 hooks`.

The lock file pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

## If plan stops early

- `source` still points at `modules/record`. The hooks do not replace it.
- An error hook that never prints means `on_errors` does not match `deliberate plan failure`, or the hook is not listed for `plan`.
- An after hook on the failing plan means `run_on_error` is true. This lecture sets it to false so the two runs are different.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.
- `hcl fmt --check` fails when the blocks are not aligned with the snippet. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your unit with [`solution/unit/terragrunt.hcl`](solution/unit/terragrunt.hcl). The module matches `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
