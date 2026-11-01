# 11.1 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  11.1 migrate to 1.x
```

`legacy/` is the 0.x snapshot: `run-all`, `--terragrunt-*` flags, and an `_envcommon` include. The migrated tree is `units/record` plus `live/dev` and `live/prod` stack files.

What the checker shows:

1. `terragrunt --version` is 1.2.x and `hcl fmt --check` passes.
2. `flags.md` records the 1.x names, including `run --all`, `--tf-path`, `--queue-exclude-dir`, and `TG_TF_PATH`.
3. `scripts/queue.sh` plans two units. Dev's note is `dev stack`. Prod's note is `prod stack`. The legacy tree is not in the queue.
4. `terragrunt run -- version` in the generated dev unit prints `Terraform v1.17.<patch>`.
5. `run --all apply` writes those notes. `run --all destroy` removes the units.

`run --all apply` and `run --all destroy` add `-auto-approve`.
