# 02.1 completed notes

The checker in `start/check-versions.sh` is the exercise. A passing run looks like this (the patch numbers will move as the `prefix:` pins float):

```text
PASS  Terragrunt 1.2.x: terragrunt version v1.2.1
PASS  Terraform 1.17.x: Terraform v1.17.1
Pins match. OpenTofu may also be installed for section 12; leave it unused here.
```

Commands that produced that result, from a clean shell, using mise:

```bash
cd /path/to/terragrunt-labs
mise trust
mise install
eval "$(mise activate bash)"
labs/02-install/02.1-install/start/check-versions.sh
```

The same check without writing an activation line into the shell config:

```bash
cd labs/02-install/02.1-install/start
mise exec -- ./check-versions.sh
```

tenv equivalent, when mise is not what you want:

```bash
tenv tf install '~> 1.17.0'
tenv tg install '~> 1.2.0'
terragrunt --version
terraform version
```

Optional tenv pin files, not committed in this repo:

```text
# .terraform-version
~> 1.17.0

# .terragrunt-version
~> 1.2.0
```

Terragrunt 1.2 runs the `tofu` binary when it is on `PATH`. The units in 02.2 and 02.3 set `terraform_binary = "terraform"` so those labs stay on Terraform 1.17.
