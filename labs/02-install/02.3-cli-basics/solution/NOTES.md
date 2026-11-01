# 02.3 completed notes

`exercises.sh` is the same script as `start/exercises.sh`. A passing run ends with:

```text
PASS  02.3 exercises
```

What each step is showing:

1. `terragrunt run -- version` prints `Terraform v1.17.<patch>`. `terraform_binary = "terraform"` selects that binary. With `tofu` on `PATH` and no `terraform_binary`, Terragrunt 1.2 runs OpenTofu instead.
2. `terragrunt run -- init` downloads the `local`, `null`, and `random` providers into the working copy. The first run needs the Terraform registry. It does not need AWS.
3. `terragrunt run plan` is the explicit command with no extra Terraform flags. The plan is `3 to add`.
4. `terragrunt run -- plan -input=false` is the same plan. The `--` separator is how `run` tells Terragrunt flags from Terraform flags.
5. `terragrunt plan` is the shortcut for `terragrunt run -- plan`. Shortcuts accept Terraform flags directly: `terragrunt plan -input=false`.
6. `terragrunt run plan -input=false` fails. `-input` is not a Terragrunt flag. The error tells you to put Terraform flags after `--`.
7. `terragrunt --terragrunt-non-interactive plan` fails with `flag provided but not defined: -terragrunt-non-interactive`. The 1.x flag is `--non-interactive`. The environment variable is `TG_NON_INTERACTIVE=true`.
8. `--non-interactive` answers Terragrunt prompts. It does not answer Terraform's apply prompt. `-auto-approve` does. `apply` creates the pet name, the null marker, and `marker.txt`.
9. `terragrunt output` is the shortcut for `terragrunt run -- output`. `name` looks like `lab-trusting-salmon` (the words change every apply).
10. The OpenTofu/Terraform working directory is under `.terragrunt-cache/<hash>/<hash>/`. That directory holds the copied module, `.terraform/`, and the local state file. `marker.txt` is created there, not beside `terragrunt.hcl`.
11. `terragrunt workspace list` fails with `unknown command: "workspace"`. `terragrunt run -- workspace list` prints `* default`.
12. `terragrunt --non-interactive run -- destroy -auto-approve` removes the three resources. The cache directory remains until you delete it. The script deletes it the next time it starts.
