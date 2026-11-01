# Flag and command renames

| 0.x | 1.x |
| --- | --- |
| `terragrunt run-all plan` | `terragrunt run --all -- plan` |
| `--terragrunt-non-interactive` | `--non-interactive` |
| `--terragrunt-tfpath` | `--tf-path` |
| `--terragrunt-working-dir` | `--working-dir` |
| `--terragrunt-exclude-dir` | `--queue-exclude-dir` |
| `--terragrunt-debug` | `--inputs-debug` |
| `--terragrunt-log-level` | `--log-level` |
| `terragrunt render-json` | `terragrunt render --format json` |
| `terragrunt hclfmt` | `terragrunt hcl fmt` |
| `TERRAGRUNT_NON_INTERACTIVE` | `TG_NON_INTERACTIVE` |
| `TERRAGRUNT_TFPATH` | `TG_TF_PATH` |
| `TERRAGRUNT_DEBUG` | `TG_INPUTS_DEBUG` |

`--queue-exclude-dir 'legacy/**'` is the renamed exclude flag. `run --help` on 1.2 also shows `--filter '!./legacy/**'` for the same exclusion.
