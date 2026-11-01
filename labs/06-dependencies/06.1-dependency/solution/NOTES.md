# 06.1 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  06.1 dependency
```

`service/terragrunt.hcl` has a `dependency "network"` block whose `config_path` is `../network`. `inputs.note` is `dependency.network.outputs.name`. There is no `mock_outputs` block.

What the checker shows:

1. `terragrunt hcl fmt --check` passes.
2. A service plan before network is applied exits non-zero and reports `detected no outputs`.
3. `terragrunt run -- version` in both units prints `Terraform v1.17.<patch>`. The unit files have no `terraform_binary` assignment. `root.hcl` sets it to `"terraform"`.
4. Network apply produces `name = "net-<word>-<word>"`.
5. The service plan is `3 to add` and contains that same name as `note`.
6. After service apply, `note` equals the network `name`. Service `name` is `svc-<word>-<word>`.
7. `terragrunt hcl validate --inputs --strict --tf-path terraform` passes for the service unit.
8. Destroy removes service first, then network.

The words in the pet name change on every apply. The module matches `start/`.
