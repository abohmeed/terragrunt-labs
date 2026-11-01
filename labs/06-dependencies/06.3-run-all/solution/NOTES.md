# 06.3 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  06.3 run all
```

The queue is `network`, then `database`, then `service`. Database mocks the network name as `mock-network-name`. Service mocks the database name as `mock-db-name`. Both allow lists are `validate` and `plan`.

What the checker shows:

1. `terragrunt run --all -- plan` from the lecture directory queues `database`, `network`, and `service`. Each plan is `3 to add`. Database's plan note is `mock-network-name`. Service's plan note is `mock-db-name`. Network's note is `network unit`.
2. `terragrunt run -- version` prints `Terraform v1.17.<patch>`.
3. `run --graph` is executed in a temporary copy of the lecture after `git init`, because `--graph` searches up to the git root. From `network` the queue is all three units. From `database` it is `database` and `service`. From `service` it is `service` only.
4. `terragrunt run --all -- apply` writes real outputs. Database `note` equals the network `name` (`net-<word>-<word>`). Service `note` equals the database `name` (`db-<word>-<word>`).
5. `terragrunt run --all -- destroy` reports `Destroy complete` for service, then database, then network.

`run --all apply` and `run --all destroy` add `-auto-approve`.
