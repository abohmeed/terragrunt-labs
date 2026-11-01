# 07.6 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  07.6 scaffold
```

`live/` is `terragrunt scaffold` of `catalog/units/record`, with `terragrunt.values.hcl` filled in (`prefix = "lab"`, `note = "scaffolded unit"`). `stamped/` is the scaffold of `catalog/stacks/platform`, with `prefix = "stk"`.

What the checker shows:

1. `terragrunt hcl fmt --check` passes. `terragrunt --version` is 1.2.x.
2. `terragrunt catalog --format=jsonl --root-file-name root.hcl` on a temporary Git catalog lists the module, the unit, and the stack.
3. `terragrunt scaffold --non-interactive` of the module writes a `terragrunt.hcl` that includes `root.hcl` and leaves `environment = "" # TODO: fill in value`.
4. A fresh scaffold of the unit matches `live/terragrunt.hcl`. A fresh scaffold of the stack matches `stamped/terragrunt.stack.hcl`.
5. The live unit plans `3 to add`, applies, and the `name` output is `lab-<word>-<word>`. `note` is `scaffolded unit`. Destroy removes it. The engine is Terraform 1.17.x.
6. `terragrunt stack generate` in `stamped/` plans one unit with prefix `stk`.

The words in the pet name change on every apply. The catalog matches `start/`.
