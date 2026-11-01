# 04.2 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  04.2 merge
```

The three units include one `root.hcl`. The child `inputs` set `note`, a one-key `tags` map, and a one-item `labels` list. `prefix` names the unit.

| | `shallow` | `deep` | `no_merge` |
| --- | --- | --- | --- |
| `terraform_binary` | Inherited from `root.hcl` | Inherited from `root.hcl` | Set on the unit |
| `course` | Kept from the root | Kept from the root | `include.root.inputs.course` |
| `note` | `from the unit` | `from the unit` | `from the unit` |
| `tags` | `{ tier = "app" }` | `owner = "platform"`, `tier = "app"`, `cost_center = "labs"` | `{ tier = "app" }` |
| `labels` | `unit` | `course,shared,unit` | `unit` |
| `prefix` | `shallow` | `deep` | `no-merge` |

`owner` and `cost_center` outputs are empty strings for `shallow` and `no_merge`. `deep` keeps the root keys and replaces `tier`.

`terragrunt run -- version` prints `Terraform v1.17.<patch>` in every unit. `no_merge` sets `terraform_binary` itself. The other two inherit it.

Each plan is `3 to add`. Apply output includes `name = "<prefix>-<word>-<word>"`. The words change on every apply. Destroy runs after each apply.
