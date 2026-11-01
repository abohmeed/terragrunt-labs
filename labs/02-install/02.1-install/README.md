# 02.1 Install

Install the pinned Terragrunt 1.2.x and Terraform 1.17.x releases and confirm both CLIs answer.

## Goal

Use the pins in the repo root [`.mise.toml`](../../../.mise.toml). A `prefix:` request tracks the newest patch on that minor line, so Terragrunt 1.2.1 and 1.2.2 both pass, and the same is true for Terraform 1.17.x. This lecture does not apply infrastructure.

## Steps with mise

1. Install [mise](https://mise.jdx.dev/installing-mise.html) if it is not already on the machine.
2. From the repo root, trust this config and install the pins:

```bash
mise trust
mise install
```

3. Put the tools on `PATH` in this shell:

```bash
eval "$(mise activate bash)"
```

Use `zsh` instead of `bash` if that is your shell. To try one command without changing the shell config:

```bash
mise exec -- terragrunt --version
mise exec -- terraform version
```

4. From this lecture's `start/` directory, run the checker:

```bash
./check-versions.sh
```

Both tools should print a `PASS` line.

`mise install` also installs OpenTofu, because section 12 uses it. Leave OpenTofu unused until that section.

## Steps with tenv

[tenv](https://github.com/tofuutils/tenv) installs the same minor lines if you are not using mise:

```bash
tenv tf install '~> 1.17.0'
tenv tg install '~> 1.2.0'
terragrunt --version
terraform version
```

Then run `start/check-versions.sh`. tenv also reads a `.terraform-version` or `.terragrunt-version` file from the working directory or a parent. This repo pins the tools with mise, so those files are not committed.

## What the checker accepts

- Terragrunt `v1.2.<patch>`
- Terraform `v1.17.<patch>`

A completed run is written up in [`solution/NOTES.md`](solution/NOTES.md).
