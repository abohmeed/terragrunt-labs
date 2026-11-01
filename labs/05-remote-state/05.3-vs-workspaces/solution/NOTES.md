# 05.3 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  05.3 terragrunt and workspaces
```

`layout/` is the local `remote_state` block from lecture 05.1. `workspaces/main.tf` sets `environment = terraform.workspace`.

| Tree | How dev is selected | State file |
| --- | --- | --- |
| `layout/dev` | the directory | `layout/state/dev/terraform.tfstate` |
| `layout/prod` | the directory | `layout/state/prod/terraform.tfstate` |
| `workspaces`, workspace `dev` | `terraform workspace select dev` | `workspaces/terraform.tfstate.d/dev/terraform.tfstate` |
| `workspaces`, workspace `prod` | `terraform workspace select prod` | `workspaces/terraform.tfstate.d/prod/terraform.tfstate` |

`terragrunt run -- workspace show` in a layout unit prints `default`. `terraform workspace show` in `workspaces/` prints `dev` or `prod`.

The `path` in `workspaces/versions.tf` would be the `default` workspace file (`state/workspaces/terraform.tfstate`). Apply on `default` fails the precondition, so that file is never written. Named workspaces use `terraform.tfstate.d` next to `main.tf`.

What the checker shows:

1. `terragrunt hcl fmt --check` and `terraform fmt -check` pass.
2. Each layout plan is `3 to add`. Outputs use `note = "directory per environment"`.
3. Each layout unit's workspace name is `default`.
4. Apply in the `default` Terraform workspace fails the precondition.
5. Dev and prod workspace outputs use `note = "terraform workspace"`, and `environment` matches the selected workspace.
6. Destroy removes the resources, the workspace state directories, and the layout state files.

Terragrunt units in the later lectures keep a directory per environment and stay on the `default` workspace.
