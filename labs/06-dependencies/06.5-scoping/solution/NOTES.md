# 06.5 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  06.5 scoping
```

`network` is outside `apps/`, so from `apps/` it is an external dependency. Each app mocks `name` as `mock-network-name` for `validate`, `plan`, and `destroy`.

What the checker shows:

1. `terragrunt run -- version` prints `Terraform v1.17.<patch>`.
2. `run --all plan` from `apps/` queues `api`, `legacy`, and `worker`. It does not queue `network`.
3. `--queue-exclude-external` queues those same three units and warns that external dependencies are already excluded by default.
4. `run --all --exclude-dir ./legacy` is rejected. The error says `--exclude-dir` is not a valid flag for `run`. `--queue-exclude-dir ./legacy` and `--filter='!./legacy'` both queue `api` and `worker`.
5. `run --all plan` from the lecture directory queues `network`, `apps/api`, `apps/worker`, and `apps/legacy`.
6. After `run --all apply`, each app `note` equals the network `name` (`net-<word>-<word>`).
7. `run --all destroy` from `apps/` destroys the three apps and leaves that network name in place.
8. `run --all --queue-include-external -- destroy` from `apps/` destroys the apps and `../network`. `terragrunt run -- state list` in `network` is empty. That is the destroy trap.
9. After another apply, the checker copies the lecture, runs `git init` in the copy, and runs `run --destroy-dependencies-check -- destroy` on that copy's `network` unit. The log prints `Detected dependent units:` with `apps/api`, `apps/worker`, and `apps/legacy`, then destroys `network` anyway. In this repository a direct run stops while parsing unfinished lectures, and the warning does not appear.

The warning does not refuse the destroy. Leave the shared unit out of the queue, or destroy the apps first.
