# 07.5 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  07.5 catalog
```

`root.hcl` has a `catalog` block with `urls = ["./catalog"]`. `live/terragrunt.stack.hcl` uses `source = "../catalog//units/record"`.

What the checker shows:

1. `terragrunt hcl fmt --check` passes. `terragrunt --version` is 1.2.x.
2. A temporary copy of this lecture runs `git init` in `catalog/`, then `terragrunt catalog --format=jsonl --root-file-name root.hcl`. The stream has a module `modules/record`, a unit `units/record`, and a stack `stacks/platform`. Each `component_source` contains `//`.
3. `terragrunt stack generate` writes `.terragrunt-stack/record`. `stack run plan` is `3 to add` with note `catalog unit`.
4. The generated unit prints Terraform 1.17.x.

The checker does not leave `catalog/.git` in this lecture. The module matches `start/`.
