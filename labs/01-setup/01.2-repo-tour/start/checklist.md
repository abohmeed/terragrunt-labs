# Repo tour checklist

Fill the blanks, then compare with [`../solution/NOTES.md`](../solution/NOTES.md).

`./check.sh` checks the repository itself. It does not read these answers, and it does not call AWS.

## Layout

- Repo root, from `labs/01-setup/01.2-repo-tour/`: ________
- Section folders under `labs/`: ________
- First section folder: ________
- Last section folder: ________

## One lecture

Open `labs/03-core-hcl/03.2-locals-inputs/`.

- The three entries in that folder: ________
- `start/` is where you: ________
- `solution/` is: ________
- A passing checker prints a line that starts with: ________

## Pins in `.mise.toml`

- Terragrunt: ________
- Terraform: ________
- OpenTofu: ________
- tflint: ________
- sops: ________
- age: ________

## Engine

- Labs set `terraform_binary` to: ________
- That line is there because Terragrunt 1.2 otherwise runs: ________
- The section that switches the engine: ________

## Cloud lectures

| Lecture | Path | Needs AWS for |
| --- | --- | --- |
| 05.2 | ________ | ________ |
| 09.2 | ________ | ________ |
| 09.3 | ________ | ________ |
| 10.2 | ________ | ________ |

Those four checkers call AWS: ________
