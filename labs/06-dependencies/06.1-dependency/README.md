# 06.1 Dependency

Declare a `dependency` block so one unit reads an output from another unit. No AWS account.

## Goal

From `start/service`, after `start/network` has been applied, make this succeed:

```bash
terragrunt run plan
```

The plan adds three resources. `note` is the network unit's `name` output, a value like `net-smart-cattle`. That string is not in the service file. It comes from the network state. `terragrunt run -- version` prints Terraform 1.17.x.

## How an output moves

| Where | What it is |
| --- | --- |
| `network` output `name` | `random_pet` id, known after the network unit is applied |
| `dependency.network.outputs.name` | That same string, read from the network state |
| `inputs.note` | The variable `var.note` in `modules/record` |

Terragrunt reads dependency outputs from the dependency's state. Until `network` has been applied, that state has no outputs, and `service` cannot plan. Lecture 06.2 adds mocks for that case. This lecture does not.

## Layout

```text
start/
  root.hcl                 # terraform_binary
  modules/record/
  network/terragrunt.hcl   # finished
  service/terragrunt.hcl   # dependency block goes here
```

`root.hcl` is the include from lecture 04.1. It sets `terraform_binary = "terraform"`. A directory is a unit only when it contains `terragrunt.hcl`, so the lecture root is not a unit.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). The units do not set `terraform_binary`. The root include merges it.
2. Read `start/network/terragrunt.hcl`. Leave it as it is. `prefix` is `net` and `note` is `network unit`.
3. Replace the TODO in `start/service/terragrunt.hcl`. The dependency and the inputs are:

```hcl
dependency "network" {
  config_path = "../network"
}

inputs = {
  environment = "dev"
  prefix      = "svc"
  note        = dependency.network.outputs.name
}
```

Keep the `include` and `terraform` blocks. `config_path` is relative to the service unit.

4. From `start/service`, before you apply network:

```bash
terragrunt run plan
```

The plan stops. Terragrunt reports that `../network` is a dependency and it detected no outputs.

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

The service plan is `Plan: 3 to add, 0 to change, 0 to destroy.` The `note` output equals the network `name` output. The service `name` is its own pet, prefixed `svc`.

6. Destroy service first. Destroying network while service still reads it leaves service pointed at a unit with no outputs.

```bash
terragrunt --non-interactive run -- destroy -auto-approve -input=false
cd ../network
terragrunt --non-interactive run -- destroy -auto-approve -input=false
```

The lock file next to each unit pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

7. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  06.1 dependency`. The script plans service once before network is applied, then applies both units and destroys service before network.

## If plan stops early

- `detected no outputs` before you have applied network is the result this lecture is demonstrating. Apply `network`, then plan `service` again.
- `note = "TODO"` means the input still has the placeholder. Point it at `dependency.network.outputs.name`.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.
- `hcl fmt --check` fails when the block is not aligned with the snippet. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare your service unit with [`solution/service/terragrunt.hcl`](solution/service/terragrunt.hcl). The network unit, the root file, and the module match `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
