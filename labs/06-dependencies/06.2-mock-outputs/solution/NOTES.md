# 06.2 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  06.2 mock outputs
```

`service/terragrunt.hcl` keeps the dependency from lecture 06.1 and adds:

```hcl
mock_outputs = {
  name = "mock-network-name"
}

mock_outputs_allowed_terraform_commands = ["validate", "plan"]
```

What the checker shows:

1. `terragrunt hcl fmt --check` passes.
2. `terragrunt run -- version` prints `Terraform v1.17.<patch>`.
3. A service plan before network is applied is `3 to add`, and `note` is `mock-network-name`.
4. A service apply at that point exits non-zero and reports `detected no outputs`. `apply` is not in the allow list.
5. After network is applied, the service plan contains `name = "net-<word>-<word>"` and does not contain `mock-network-name`.
6. The applied service `note` equals that network name.
7. `terragrunt hcl validate --inputs --strict --tf-path terraform` passes.
8. Destroy removes service first, then network.

The mock is used only for the cold plan. It is not written into the service state.
