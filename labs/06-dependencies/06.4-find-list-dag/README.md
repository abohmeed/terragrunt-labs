# 06.4 Find, list, and the DAG

Use `find`, `list`, and `dag graph` to see which units exist and the order Terragrunt will run them. No AWS account.

## Goal

From `start/`, make `./check.sh` pass. The units are already written. Nothing in this lecture is applied. The commands only read the HCL.

## Layout

The chain from lecture 06.3, plus `audit`, which depends on nothing:

```text
start/
  root.hcl
  modules/record/
  network/terragrunt.hcl
  database/terragrunt.hcl    # depends on network
  service/terragrunt.hcl     # depends on database
  audit/terragrunt.hcl       # no dependency block
```

`find` and `list` discover units under the working directory. They do not walk the rest of this repository.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17. From `network/`, `terragrunt run -- version` prints Terraform 1.17.x.
2. From `start/`, list the units:

```bash
terragrunt find
terragrunt find --json --dependencies
```

`find` prints one path per line, in this order:

```text
audit
database
network
service
```

The JSON form adds a `dependencies` array. `database` depends on `network`. `service` depends on `database`. `audit` and `network` have no dependencies.

3. Ask `list` for the run order:

```bash
terragrunt list --dag
terragrunt list --long --dependencies --dag
terragrunt list --tree --dag
```

`list --dag` prints units with no dependencies first (`audit`, then `network`), then `database`, then `service`. The long form is:

```text
Type  Path      Dependencies
unit  audit
unit  network
unit  database  network
unit  service   database
```

The tree form groups dependents under the unit they read:

```text
.
├── audit
╰── network
    ╰── database
        ╰── service
```

4. Print the same edges as a Graphviz graph:

```bash
terragrunt dag graph
```

`dag graph` is `list --format=dot --dependencies --external`. The graph contains `"database" -> "network"` and `"service" -> "database"`. `audit` is a node with no arrow. `| dot -Tsvg` turns that into a picture when Graphviz is installed. The checker only reads the DOT text.

5. From `start/`, run:

```bash
./check.sh
```

The last line is `PASS  06.4 find, list, and the dag`.

## If a command lists units from another lecture

`find` and `list` use the working directory. Run them from `start/` or from `solution/`, not from the repository root. The repository root contains every lecture.

The finished units match `start/`. What the commands print is written up in [`solution/NOTES.md`](solution/NOTES.md).
