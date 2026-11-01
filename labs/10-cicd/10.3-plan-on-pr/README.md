# 10.3 Plan on pull request

Plan every unit on a pull request, write a run report, and turn that report into the comment body. The backend is local, so the plan runs without AWS. Posting the comment needs GitHub. The checker writes the comment file and does not call GitHub.

## Goal

From `start/`, make `./check.sh` pass. The units are already written. This lecture is the plan command, the comment, and the workflow stub.

`terragrunt run --all plan` plans `network` and `service`. Service's plan note is the mock `mock-network-name`. The report lists both units as `succeeded`. `plan-comment.md` contains that table and both `Plan:` lines.

## The queue

```text
start/
  root.hcl                         # terraform_binary and the local backend
  modules/record/
  network/terragrunt.hcl           # note = "plan on pull request"
  service/terragrunt.hcl           # dependency on network, mock for plan
  scripts/plan.sh                  # the command you add
  scripts/plan-comment.sh          # report.json + plan.log -> plan-comment.md
  .github/workflows/plan.yml       # the stub you add
```

Treat `start/` as the repository root. The workflow file is what that repository would commit at `.github/workflows/plan.yml`.

Mocks are allowed for `validate` and `plan`, the same rule as lecture 06.2. This lecture does not apply, so service keeps the mock.

## The plan command

```bash
terragrunt --no-color --non-interactive run --all \
  --report-file report.json \
  --report-format json \
  -- plan -input=false -no-color
```

| Flag | What it does |
| --- | --- |
| `--non-interactive` | Answers Terragrunt's prompts. `TG_NON_INTERACTIVE=true` is the same switch |
| `run --all` | Queues every unit in this directory |
| `--report-file report.json` | Writes the run report. The `.json` extension selects JSON |
| `--report-format json` | Says the same thing explicitly |
| `--` | Terraform arguments start here |
| `-input=false` | Terraform does not ask questions |
| `--no-color` | The log and the comment stay plain text |

`scripts/plan.sh` runs that command from the lecture directory and tees stdout to `plan.log`. The report is a JSON array. Each object has `Name`, `Result`, `Cmd`, `Started`, and `Ended`. A success omits `Reason` and `Cause`. `Result` is `succeeded`. `Cmd` is `plan`.

## The comment

`scripts/plan-comment.sh` reads `report.json` and `plan.log` and writes `plan-comment.md`:

- a table of unit, result, and command
- every log line that contains `Plan:`

The workflow posts that file. It does not post a second copy of the whole log.

```yaml
- name: Write the plan comment
  if: always()
  run: ./scripts/plan-comment.sh
- name: Post the plan comment
  if: github.event_name == 'pull_request'
  env:
    GH_TOKEN: ${{ github.token }}
  run: gh pr comment "${{ github.event.pull_request.number }}" --body-file plan-comment.md
```

`if: always()` still writes the file when the plan step fails, so the pull request shows the failure. Permissions are `contents: read` and `pull-requests: write`. `github.token` is the job token. The plan job's concurrency group may cancel an older plan for the same pull request (`cancel-in-progress: true`). Apply, in lecture 10.4, does not cancel.

Checkout is `actions/checkout@v7.0.1`. The trigger is `pull_request` only.

## Steps

1. Install the pinned CLIs if you have not (lecture 02.1). `terraform_binary = "terraform"` in `root.hcl` keeps the engine on Terraform 1.17 when `tofu` is on `PATH`.
2. Leave the units and `root.hcl` as they are.
3. Replace `start/scripts/plan.sh` and `start/scripts/plan-comment.sh` with the scripts in `solution/scripts/`. `plan.sh` is the command above. `plan-comment.sh` is the comment writer. Both stay executable.
4. Replace `start/.github/workflows/plan.yml` with the workflow in [`solution/.github/workflows/plan.yml`](solution/.github/workflows/plan.yml).
5. From `start/`:

```bash
terragrunt --working-dir network run -- version
./scripts/plan.sh
./scripts/plan-comment.sh
```

The version line is Terraform 1.17.x. The plan queue names `network` and `service`. Each plan is `3 to add`. Service's note is `mock-network-name`. Network's note is `plan on pull request`. `report.json` lists both names with `"Result": "succeeded"` and `"Cmd": "plan"`. `plan-comment.md` starts with `## Terragrunt plan`.

6. From `start/`, run:

```bash
./check.sh
```

The last lines are:

```text
PASS  10.3 plan on pull request
GitHub was not contacted. plan-comment.md is the comment body the workflow would post.
```

The checker prints `plan-comment.md`, then deletes `plan-comment.md`, `plan.log`, and `report.json`. Run the two scripts yourself when you want the files left on disk. They are gitignored.

The checker needs `python3` and PyYAML. The comment script needs `python3` from the standard library only.

The lock file next to each unit pins `local` 2.9.1, `null` 3.3.2, and `random` 3.9.1. The first plan downloads those providers. You do not need AWS credentials.

## If the plan stops early

- `detected no outputs` means the mock was removed. `plan` has to be allowed to use `mock_outputs` while network has never been applied.
- `report.json` missing means `--report-file report.json` did not run in this directory. `plan.sh` changes to the lecture directory before Terragrunt.
- A comment without `Plan:` means `plan.log` lost stdout. `tee` has to sit on the Terragrunt command.
- `OpenTofu` from `terragrunt run -- version` means `terraform_binary` did not merge from `root.hcl`.
- `hcl fmt --check` fails when a unit drifted. From `start/`, run `terragrunt hcl fmt`, then run the checker again.

The finished units match `start/`. The scripts and the workflow are in `solution/`. What the run prints is written up in [`solution/NOTES.md`](solution/NOTES.md).
