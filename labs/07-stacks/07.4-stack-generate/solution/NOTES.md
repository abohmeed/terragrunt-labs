# 07.4 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  07.4 stack generate
```

`live/terragrunt.stack.hcl` is the stack. The source unit stays in `units/record`, outside `live/`, because `stack run` discovers every unit under the working directory and that source unit has no `values` file of its own.

What the checker shows:

1. `terragrunt hcl fmt --check` passes. `terragrunt --version` is 1.2.x.
2. `terragrunt stack generate` writes `.terragrunt-stack/network` and `.terragrunt-stack/service`. `git check-ignore` matches `.terragrunt-stack`.
3. A cold `stack run plan` is two plans of `3 to add`. Service `note` is `mock-network-name`.
4. `stack run apply` adds `-auto-approve`. `terragrunt stack output --format json` shows service `note` equal to the network `name`.
5. `stack run destroy`, then `stack clean`, removes `.terragrunt-stack`.
6. `stack run --no-stack-generate` with nothing generated reports `No units discovered`.
7. The generated network unit prints Terraform 1.17.x.

The words in the pet name change on every apply. The module and the stack file match `start/`.
