# 08.3 Errors block

Retry a transient apply failure, and ignore a known one, without editing the module. No AWS account.

## Goal

From `start/`, make `./check.sh` pass.

`retry/` applies a provisioner that fails once with `Error: transient`, waits one second, and applies again. The second call succeeds. `attempt.count` ends at `2`.

`ignore/` applies a provisioner that always fails with `Error: safe-to-ignore`. Terragrunt exits 0, prints `Ignoring safe-to-ignore drift`, and writes `ignore/error-signals.json` with `"safe_to_revert": true`.

## Retry and ignore

The `errors` block is a top-level block. It is not inside `terraform`. Ignore rules run first. A match is not retried. A leading `!` on a pattern excludes that error.

| Unit | Block | What the module does | What Terragrunt does |
| --- | --- | --- | --- |
| `retry/` | `retry "transient_network"` | Prints `Error: transient` and exits 1 on the first call | Runs apply again, up to 3 attempts, waiting 1 second |
| `ignore/` | `ignore "known_drift"` | Prints `Error: safe-to-ignore` and exits 1 | Treats the failure as handled and writes `error-signals.json` |

`max_attempts = 3` and `sleep_interval_sec = 1` keep the lab short. A real network blip waits longer. The patterns stay on separate units so the ignore rule cannot swallow the transient error.

The flaky provisioner counts attempts in `attempt.count` next to the unit. That path comes from `get_terragrunt_dir()`, so it is outside `.terragrunt-cache`. A counter inside the module copy can disappear when Terragrunt fetches the source again, and the retry would fail forever.

`signals` are for a caller, such as CI, to read after a handled failure. This lecture sets `safe_to_revert = true`. Terragrunt writes those keys to `error-signals.json` in the unit directory.

Plan does not run `local-exec`. The failure, the retry, and the ignore all happen on apply.

## Layout

```text
start/
  root.hcl                         # terraform_binary
  modules/flaky/                   # fails the first apply. Leave it.
  modules/drift/                   # fails every apply. Leave it.
  retry/terragrunt.hcl             # errors.retry goes here
  retry/.terraform.lock.hcl
  ignore/terragrunt.hcl            # errors.ignore goes here
  ignore/.terraform.lock.hcl
```

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17.
2. Read both modules. Leave them. Each one is a `null_resource` with a `local-exec` provisioner.
3. Replace the TODO in `start/retry/terragrunt.hcl` with this block after `inputs`:

```hcl
errors {
  retry "transient_network" {
    retryable_errors   = [".*Error: transient.*"]
    max_attempts       = 3
    sleep_interval_sec = 1
  }
}
```

4. Replace the TODO in `start/ignore/terragrunt.hcl` with this block after `terraform`:

```hcl
errors {
  ignore "known_drift" {
    ignorable_errors = [
      ".*Error: safe-to-ignore.*",
      "!.*Error: do not ignore.*",
    ]
    message = "Ignoring safe-to-ignore drift"
    signals = {
      safe_to_revert = true
    }
  }
}
```

`!.*Error: do not ignore.*` is the exclusion. An error that matches it is not ignored, even though it also matches a pattern without the `!`. This module does not emit that text. The pattern is here so the exclusion is visible.

5. From `start/`:

```bash
terragrunt --working-dir retry run -- version
terragrunt --no-color --working-dir retry run -- apply -auto-approve
terragrunt --no-color --working-dir ignore run -- apply -auto-approve
```

The version line is Terraform 1.17.x. Use `--no-color` on apply. The retry expression is matched against the text Terraform prints, and color codes in the middle of a line can miss `Error: transient`.

The retry log contains `Encountered retryable error: transient_network` and `Attempt 1 of 3`. The apply then completes. `retry/attempt.count` contains `2`.

The ignore log contains `Ignoring safe-to-ignore drift`. `ignore/error-signals.json` contains `"safe_to_revert": true`. The command exits 0.

6. From `start/`:

```bash
./check.sh
```

The last line is `PASS  08.3 errors block`. The script deletes `attempt.count` and `error-signals.json` when it finishes. Both are gitignored.

The lock files pin `null` 3.3.2. The first apply downloads that provider. You do not need AWS credentials.

## If apply stops early

- The first retry attempt fails. That is the provisioner. The next attempt is the one that should succeed. `attempt.count` at `1` with a non-zero exit means the retry block did not match `Error: transient`.
- `sleep_interval_sec` above 1 still works, and the checker looks for a one-second wait. Leave it at 1.
- An ignore that still exits non-zero means `ignorable_errors` does not match `Error: safe-to-ignore`, or a negative pattern excluded it.
- No `error-signals.json` means the `signals` attribute is missing. The message alone does not write the file.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.
- `hcl fmt --check` fails when the blocks are not aligned with the snippet. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

Compare the units with [`solution/retry/terragrunt.hcl`](solution/retry/terragrunt.hcl) and [`solution/ignore/terragrunt.hcl`](solution/ignore/terragrunt.hcl). The modules match `start/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
