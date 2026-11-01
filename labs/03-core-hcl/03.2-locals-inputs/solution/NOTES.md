# 03.2 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  03.2 locals and inputs
```

`dev` and `prod` call the same module, `modules/record`. The units differ in `locals.environment`.

| Unit | `environment` | Derived `prefix` | `note` |
| --- | --- | --- | --- |
| `dev` | `dev` | `dev-lab` | `offline locals and inputs` |
| `prod` | `prod` | `prod-lab` | `offline locals and inputs` |

What each unit shows:

1. `terragrunt run -- version` prints `Terraform v1.17.<patch>` because `terraform_binary = "terraform"`.
2. `terragrunt hcl validate --inputs --strict --tf-path terraform` reports that `environment`, `prefix`, and `note` are set and that no extra input is set. The command uses `--tf-path terraform` so OpenTofu does not answer it.
3. The plan is `3 to add`. `random_pet` shows `prefix = "dev-lab"` or `prefix = "prod-lab"`.
4. Apply output includes `environment = "dev"` (or `"prod"`), `note = "offline locals and inputs"`, and `name = "<prefix>-<word>-<word>"`. The words change on every apply.
5. Destroy removes that unit's three resources. The other unit has its own cache and is unaffected.

`inputs` is the only channel into the module. `prefix_root` stays a local. It changes `prefix`, and `prefix` is what Terraform receives.
