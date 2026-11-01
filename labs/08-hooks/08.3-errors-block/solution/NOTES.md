# 08.3 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  08.3 errors block
```

`errors` is a top-level block. `retry/` retries `Error: transient`. `ignore/` ignores `Error: safe-to-ignore` and does not retry it. `root.hcl` holds `terraform_binary = "terraform"`.

What the checker shows:

1. `terragrunt hcl fmt --check` passes. `terragrunt --version` is 1.2.x.
2. Both units print Terraform 1.17.x from `terragrunt run -- version`.
3. The flaky apply logs `Encountered retryable error: transient_network`, `Attempt 1 of 3`, and a one-second wait, then `Apply complete!`. `attempt.count` is `2`.
4. The drift apply exits 0, logs `Ignoring safe-to-ignore drift`, and writes `error-signals.json` with `"safe_to_revert": true`.

The checker deletes the counter and the signals file. The modules match `start/`.
