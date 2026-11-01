# 07.3 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  07.3 values
```

`units/record` reads `values.environment`, `values.prefix`, and `values.note`. `terragrunt.values.hcl` beside it is the default (`prefix = "def"`, `note = "default note"`). The `plain` unit does not set `values`, so generate copies that file. `network` and `service` set `values`, which replaces the file. The service `autoinclude` writes `terragrunt.autoinclude.hcl` with `config_path = "../network"` and `note = dependency.network.outputs.name`.

What the checker shows:

1. `terragrunt hcl fmt --check` passes. `terragrunt --version` is 1.2.x.
2. A cold `stack run plan` is three plans of `3 to add`. Service `note` is `mock-network-name`. Plain `note` is `default note`.
3. After `stack run apply`, `terragrunt stack output --format json` shows service `note` equal to the network `name` (`net-<word>-<word>`). The mock is gone.
4. `stack run destroy` then `stack clean` removes `.terragrunt-stack`.
5. The generated network unit prints Terraform 1.17.x.

The words in the pet name change on every apply. The module matches `start/`.
