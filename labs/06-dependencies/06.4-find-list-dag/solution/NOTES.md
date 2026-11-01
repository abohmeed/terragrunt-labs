# 06.4 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  06.4 find, list, and the dag
```

The checker does not apply the units. `terragrunt run -- version` in `network` prints `Terraform v1.17.<patch>`.

From the lecture directory:

```text
terragrunt find
audit
database
network
service
```

`find --json --dependencies` reports `database` → `network` and `service` → `database`. `audit` and `network` have an empty dependency list.

`list --dag` prints `audit network database service`. Units with no dependencies come first.

`list --long --dependencies --dag` shows `database` depending on `network` and `service` depending on `database`.

`list --tree --dag` nests `service` under `database` under `network`, with `audit` beside `network`.

`dag graph` prints DOT. The edges are `"database" -> "network"` and `"service" -> "database"`. `audit` is a node with no edge. That command is `list --format=dot --dependencies --external`.
