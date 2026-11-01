# 13.1 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  13.1 capstone
AWS was not contacted. The apply used the local backend. The workflow role steps stay commented.
```

`live/dev` and `live/prod` source `../../catalog//units/record`. Service mocks the network name for plan. Apply reads the real network name.

What the checker shows:

1. `terragrunt catalog --format=jsonl` lists the module `Record`, the unit `Record unit`, and the stack `Environment`.
2. `scripts/plan.sh` plans four units. Each plan is `3 to add`. Both service plans use `mock-network-name`.
3. `scripts/apply.sh` writes local state under `state/`. Dev's service note equals the dev network name (`dev-<word>-<word>`). Prod's service note equals the prod network name (`prd-<word>-<word>`).
4. The generated network unit prints Terraform 1.17.x.
5. Destroy removes both stacks. The workflow files keep the AWS role steps in comments.
