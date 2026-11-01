# 06.2 Mock outputs

Supply `mock_outputs` so a dependent unit can plan before its dependency has been applied. No AWS account.

## Goal

From `start/service`, with no network state, make this succeed:

```bash
terragrunt run plan
```

The plan adds three resources. `note` is `mock-network-name`. Apply of that same unit fails until `network` has been applied. After network is applied, the service plan uses the real network `name` and the mock is gone.

## When a mock is used

Terragrunt uses `mock_outputs` only when both of these are true:

| Condition | This lecture |
| --- | --- |
| The dependency has no outputs in state | True before `network` is applied |
| The Terraform command is listed in `mock_outputs_allowed_terraform_commands` | `validate` and `plan` |

`apply` is not in that list. A cold `apply` still errors with `detected no outputs`. Once `network` has been applied, plan and apply read `dependency.network.outputs.name` from state. The mock does not replace a real output.

## Layout

```text
start/
  root.hcl
  modules/record/
  network/terragrunt.hcl   # finished, from lecture 06.1
  service/terragrunt.hcl   # dependency is wired; mocks are the TODO
```

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17 when `tofu` is on `PATH`.
2. The dependency block and `inputs.note` are already set, as in lecture 06.1. Open `start/service/terragrunt.hcl` and add the mock attributes inside that block:

```hcl
dependency "network" {
  config_path = "../network"

  mock_outputs = {
    name = "mock-network-name"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}
```

The map keys are output names. `name` is the output the service reads. Leave `inputs` as they are.

3. From `start/service`, before applying network:

```bash
terragrunt run plan
```

The plan is `Plan: 3 to add, 0 to change, 0 to destroy.` Terragrunt warns that network has no outputs and that it is returning the mocks. `note` is `mock-network-name`.

4. Apply service anyway:

```bash
terragrunt --non-interactive run -- apply -auto-approve -input=false
```

This fails with `detected no outputs`. The allow list does not include `apply`, so the mock is not a value Terragrunt will write into state.

5. Apply network, then plan and apply service:

```bash
cd ../network
terragrunt --non-interactive run -- apply -auto-approve -input=false
terragrunt output -raw name
cd ../service
terragrunt run plan
terragrunt --non-interactive run -- apply -auto-approve -input=false
terragrunt output -raw note
```

The service plan shows the network pet name, not `mock-network-name`. The service `note` output equals that pet name.

6. Destroy service, then network, in that order.

The lock file next to each unit pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

7. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  06.2 mock outputs`.

## If plan stops early

- `detected no outputs` on `plan` means `mock_outputs` is missing, or `plan` is not in `mock_outputs_allowed_terraform_commands`.
- A service `note` of `mock-network-name` after network has been applied means the plan ran against the old cache from before that apply. Run the plan again from `service/`.
- An apply that succeeds before network exists means `apply` was added to the allow list. Remove it. A mock should not be written as a real input.
- `hcl fmt --check` fails when the block is not aligned with the snippet. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your service unit with [`solution/service/terragrunt.hcl`](solution/service/terragrunt.hcl). The network unit and the module match `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
