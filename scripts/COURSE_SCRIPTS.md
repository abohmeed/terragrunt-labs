# Terragrunt for DevOps — All lecture scripts

Concatenated from the per-lecture files in INDEX.md order.


---

# 01.1 Why Terragrunt

- **Estimated time:** 3 min
- **Lab path:** `labs/01-setup/01.1-why/` (README only; no lab files yet)
- **Section:** 01 · Welcome & setup

---

Welcome to Terragrunt for DevOps. [pause 1s]

Before we install anything, I want to show you the exact problem Terragrunt solves. Not in general terms. The specific point where plain Terraform starts to hurt.

[breath]

Picture one Terraform root module. A VPC, a database, an app. You deploy it to dev. It works.

Now you need staging and prod. The usual move is to copy the folder. Three copies of the same root module, three `backend` blocks, three provider blocks, three `terraform.tfvars` files.

(*Diagram: three folders — dev, staging, prod — each holding the same main.tf, backend.tf, provider.tf.*)

[pause 1s]

Here is what breaks. The backend block cannot use variables, so you hard-code the bucket and the key in every copy. Change the provider version in one folder and forget the other two, and your environments drift. Add a fourth region, and you copy everything again.

[breath]

The second problem is size. If everything lives in one root module, every plan touches everything. One state file, one lock, one blast radius. So teams split the code into smaller root modules: network, database, app. Now each piece has its own state. Good. But now the app needs the VPC ID from the network state, and something has to run them in the right order.

[pause 1s]

Terraform alone does not give you that orchestration. Terragrunt does.

Terragrunt is a thin wrapper. It does not replace Terraform. It calls Terraform, or OpenTofu, for you. Before it does, it does three things.

One. It keeps configuration in one place. A root file holds the backend and the provider, and every unit includes it. You write the backend once.

Two. It copies your module into a working directory and writes generated files into it. So the module stays clean, and the environment-specific parts come from Terragrunt.

Three. It knows how units depend on each other. It builds a graph, and runs plan or apply across many units in the right order.

[breath]

In Terragrunt 1.x, the word for one deployable piece is a **unit**. A unit is a directory with a `terragrunt.hcl` file. It points at a module, it sets inputs, and it gets its own state.

A group of units is a **stack**. In 1.x you can describe a stack in one file, `terragrunt.stack.hcl`, and Terragrunt generates the units for you. We will build up to that in section seven.

[pause 1s]

So the course goes in that order. First a single unit. Then shared configuration with `include`. Then remote state, dependencies, and stacks. Then hooks, secrets, and a CI/CD pipeline that plans on pull requests and applies on merge.

Everything runs on Terragrunt 1.2 and Terraform 1.17. Most labs run fully offline on your laptop. The few that need AWS are marked with a cloud icon.

[pause 1s]

In the next lecture, we walk through the lab repository so you know where everything lives.


---

# 01.2 Lab repo tour

- **Estimated time:** 3 min
- **Lab path:** `labs/01-setup/01.2-repo-tour/` (README only) · repo root `README.md`, `.mise.toml`
- **Section:** 01 · Welcome & setup

---

All the labs for this course live in one public repository: `abohmeed/terragrunt-labs` on GitHub.

(*Screen: GitHub repo root.*)

Clone it once. Every lecture after this one works inside it.

[pause 1s]

Open the `labs` folder. There is one folder per section, numbered the same way as the course. Zero-two install. Zero-three core HCL. All the way to thirteen, the capstone.

Inside each section there is one folder per lecture. Open one, for example `03.2-locals-inputs`.

(*Screen: `labs/03-core-hcl/03.2-locals-inputs/` — README.md, start/, solution/.*)

[breath]

Every lecture folder has the same three things.

A `README.md`. That is the goal of the lab and the steps.

A `start` folder. That is where you work. It has TODOs in it, and in many labs it is deliberately broken so you can see the error first.

And a `solution` folder. That is the finished lab. Open it when you are stuck, or when you want to compare.

[pause 1s]

Most labs also have a `check.sh` script. It deletes the cache, runs the lab cold, and prints a line that starts with `PASS`. If you see `PASS`, your lab matches what the lecture expects.

[breath]

Now the version pins. Open `.mise.toml` at the repo root.

(*Screen: `.mise.toml`.*)

Terragrunt is pinned to the 1.2 line. Terraform to 1.17. OpenTofu to 1.13, but we only use it in the add-on section twelve. tflint, sops, and age are pinned to exact releases, because lectures eight-two and nine-one run those binaries directly.

[pause 1s]

One detail you will see in almost every lab: `terraform_binary = "terraform"`. Terragrunt 1.2 prefers OpenTofu when it finds `tofu` on your path. Since `mise install` puts `tofu` there, every lab sets the binary explicitly, so the engine stays on Terraform until section twelve.

[breath]

Last thing. Most labs are offline. They use the `local`, `random`, and `null` providers and a local state backend. You do not need a cloud account for them.

Four lectures need AWS: five-two, the S3 backend bootstrap. Nine-two and nine-three, assume role and multi-account. And ten-two, GitHub Actions with OIDC. Those are marked with a cloud icon. Their checkers only validate the rendered configuration and never call AWS, so you can still follow along without an account.

[pause 1s]

That is the repo. Next, we install the pinned tools and confirm they answer.


---

# 02.1 Pin installs (mise / tenv)

- **Estimated time:** 4 min
- **Lab path:** `labs/02-install/02.1-install/` (`start/check-versions.sh`, `solution/NOTES.md`)
- **Section:** 02 · Install & first unit

---

In this lecture we install Terragrunt and Terraform at the exact versions the labs expect. Nothing gets deployed. We only want both CLIs to answer with the right version.

[pause 1s]

Why pin at all? Because Terragrunt changed a lot between 0.x and 1.x. Flags were renamed. Commands moved. If you follow this course on an old binary, commands will fail in ways that have nothing to do with your code. Pinning removes that variable.

[breath]

The pins live in `.mise.toml` at the repo root. mise is a tool version manager. It reads that file and installs each tool at the requested version.

(*Screen: `.mise.toml`.*)

Terragrunt and Terraform use a `prefix:` request. That means: the newest patch on that minor line. So Terragrunt 1.2.1 passes, and so would 1.2.2. Terraform is anything on 1.17.

[pause 1s]

From the repo root, run `mise trust`, then `mise install`.

(*Terminal: `mise trust && mise install`.*)

`trust` is required because mise will not read a config file from a cloned repo until you say so.

Now put the tools on your path for this shell: `eval "$(mise activate bash)"`. If you use zsh, replace `bash` with `zsh`.

If you only want to try one command without touching your shell config, `mise exec -- terragrunt --version` works too.

[breath]

`mise install` also installs OpenTofu. Leave it alone for now. Section twelve uses it.

[pause 1s]

Now `cd` into this lecture's `start` folder and run `./check-versions.sh`.

(*Terminal: two `PASS` lines.*)

The script asks each CLI for its version and compares it to the pin. Terragrunt must report `v1.2.` something. Terraform must report `v1.17.` something. You should see two `PASS` lines.

[pause 1s]

If you do not use mise, tenv does the same job. `tenv tf install '~> 1.17.0'`, and `tenv tg install '~> 1.2.0'`. Then run the same checker.

tenv can also read a `.terraform-version` or `.terragrunt-version` file from the working directory. This repo pins with mise, so those files are not committed. Pick one tool and stay with it.

[breath]

That is the whole install. Two CLIs, two pinned versions, one checker. Next lecture, we write our first unit.


---

# 02.2 First `terragrunt.hcl`

- **Estimated time:** 6 min
- **Lab path:** `labs/02-install/02.2-first-unit/` (`start/terragrunt.hcl`, `start/modules/marker/`)
- **Section:** 02 · Install & first unit

---

Now we run our first Terragrunt unit. It calls a small local module. No AWS, no remote backend. Everything happens on your machine.

[pause 1s]

Open `start/modules/marker`. This module is already complete. Read it before you touch the unit.

(*Screen: `modules/marker/main.tf`.*)

Three resources. `random_pet.name` builds a name from `var.prefix`. `null_resource.marker` records that name and `var.note`. And `local_file.marker` writes both into a file called `marker.txt`.

[breath]

Now open `start/terragrunt.hcl`. This is the unit. It has two jobs: say which module to run, and say what values to pass to it.

(*Screen: `start/terragrunt.hcl` with `source = "./modules/TODO"`.*)

The `terraform` block has a `source` attribute. Right now it points at `./modules/TODO`. Let's run it as it is, so you see the error first.

`terragrunt run plan`.

(*Terminal: `no such file or directory`.*)

[pause 1s]

Terragrunt tried to copy the source directory and could not find it. That tells you something about how Terragrunt works. Before Terraform runs, Terragrunt copies the module into a working directory under `.terragrunt-cache`. Then it runs Terraform inside that copy.

Fix the path: `./modules/marker`.

[breath]

Next, `inputs`. Inputs are the values Terraform receives. Each key becomes a variable in the module. The module needs `prefix` and `note`. Set `prefix` to a short string, like `lab`. Leave `note` as it is.

If you forget `prefix`, Terraform does not fail. It stops and asks for `var.prefix` and waits for you to type. If that happens, press Ctrl-C and add the input.

[pause 1s]

Look at one more line in this file: `terraform_binary = "terraform"`. Terragrunt 1.2 runs OpenTofu when `tofu` is on your path. mise put it there. So this line pins the engine to Terraform.

You can check which engine runs with `terragrunt run -- version`. The first line should say Terraform 1.17.

[breath]

Now plan again. `terragrunt run plan`.

(*Terminal: provider download, then plan.*)

The first plan downloads three providers from the Terraform registry: local, null, and random. Later plans reuse that download.

Read the end of the plan. `Plan: 3 to add, 0 to change, 0 to destroy.` The pet name and the file contents say `(known after apply)`, because the random name does not exist until we apply.

[pause 1s]

Where is the state? Not next to your `terragrunt.hcl`. It is inside `.terragrunt-cache`, in the working copy. Git already ignores that folder. The same goes for `marker.txt` once we apply. It gets written inside the working copy, not in your source folder.

[breath]

One more file: `.terraform.lock.hcl`. It pins the exact provider versions: local 2.9.1, null 3.3.2, random 3.9.1. Terragrunt copies this lock file into the working directory on init, so every run picks the same providers. The hashes in it work on Linux, Mac, and Windows.

[pause 1s]

Compare your file with `solution/terragrunt.hcl`. The module files are identical in both folders. Only the unit changed: one source path and one input.

That is a unit. A folder, a `terragrunt.hcl`, a module source, and inputs. In the next lecture we apply it, read the outputs, destroy it, and learn the 1.x command line.


---

# 02.3 `run` and the 1.x CLI flags

- **Estimated time:** 5 min
- **Lab path:** `labs/02-install/02.3-cli-basics/` (`start/exercises.sh`, `solution/NOTES.md`)
- **Section:** 02 · Install & first unit

---

The unit in this lab is already complete. That way you can practice the command line without finishing the previous lab. We'll run init, plan, apply, output, and destroy, all with Terragrunt 1.x syntax.

[pause 1s]

In 1.x, the main command is `run`. Everything after `run` goes to Terraform.

`terragrunt run -- version`. `terragrunt run -- init`. `terragrunt run plan`.

[breath]

Notice the double dash. Anything after `--` is passed straight to Terraform. That matters for Terraform flags. Watch this.

`terragrunt run plan -input=false`.

(*Terminal: rejected.*)

Rejected. Terragrunt reads `-input` as its own flag and does not know it. Put the double dash in: `terragrunt run -- plan -input=false`. That works.

[pause 1s]

There are also shortcuts. `terragrunt plan` is the same as `terragrunt run plan`. The common Terraform commands have shortcuts: plan, apply, destroy, init, output, and a few more. So `terragrunt plan -input=false` works too.

[breath]

Now the flag that changed the most from 0.x. In older courses and older blog posts, you will see `--terragrunt-non-interactive`. Try it.

(*Terminal: `terragrunt --terragrunt-non-interactive plan` — rejected.*)

Rejected. In 1.x, the `--terragrunt-` prefix is gone. The flag is just `--non-interactive`, and the environment variable is `TG_NON_INTERACTIVE=true`.

[pause 1s]

Be precise about what it does. `--non-interactive` answers Terragrunt's own prompts. It does not answer Terraform's. A single-unit apply still waits for you to type `yes`, unless you pass `-auto-approve` to Terraform.

So the full apply is: `terragrunt --non-interactive run -- apply -auto-approve -input=false`.

Then `terragrunt output`. You see the pet name and the note.

[breath]

Now look at what Terragrunt actually ran. `find .terragrunt-cache -name main.tf`. And `find .terragrunt-cache -name marker.txt`.

(*Terminal: paths deep inside `.terragrunt-cache`.*)

The module was copied there. Terraform ran there. The file was written there. Your source folder is untouched.

[pause 1s]

One command that is not a shortcut: `workspace`. Run `terragrunt workspace list`. It is not forwarded. Terragrunt separates state by unit, not by workspace, so 1.x does not treat `workspace` as a shortcut. If you really want it, ask `run` explicitly: `terragrunt run -- workspace list`. We compare units and workspaces properly in lecture five-three.

[breath]

Destroy with the same flags: `terragrunt --non-interactive run -- destroy -auto-approve -input=false`.

[pause 1s]

Now run `./exercises.sh`. It deletes `.terragrunt-cache` first, so it starts cold. Then it runs the whole sequence, including the commands that are supposed to be rejected. If any command behaves unexpectedly, it exits with an error.

The last line should be `PASS 02.3 exercises`.

[breath]

So the rules for the rest of the course: `run` plus double dash for Terraform flags. No `--terragrunt-` prefix. `--non-interactive` for Terragrunt prompts, `-auto-approve` for Terraform's. Next section, we go into the HCL itself, starting with `source`.


---

# 03.1 `terraform { source }` and the `//` separator

- **Estimated time:** 4 min
- **Lab path:** `labs/03-core-hcl/03.1-source/` (`start/terragrunt.hcl`, `start/modules/service/main.tf`, `check.sh`)
- **Section:** 03 · Core HCL

---

There are two different things called `source` in this lab, and mixing them up is one of the most common Terragrunt errors. Let's separate them.

[pause 1s]

The lab has two local modules. `modules/service` is the root module the unit runs. `modules/label` creates the pet name, the null marker, and `marker.txt`. The service module calls the label module.

(*Screen: `start/modules/service/main.tf`, `module "label"` block.*)

This `source` is a Terraform module source. It's relative to `modules/service`. Set it to `../label`.

Now open `start/terragrunt.hcl`. The `terraform` block says `source = "./modules/service"`. That's the Terragrunt source. It decides what gets copied into `.terragrunt-cache`.

[breath]

Run `terragrunt run plan`.

(*Terminal: `Unreadable module directory` naming `../label`.*)

Init fails. The error names `../label`. Why? Because a source path without a double slash copies that one directory only. Terragrunt copied `modules/service` into the cache. `modules/label` stayed behind on disk. So when Terraform looks for `../label` inside the cache, it's not there.

[pause 1s]

The fix is the double-slash form.

`source = "${get_terragrunt_dir()}//modules/service"`.

Read it in two halves. Everything before the `//` is the directory that gets copied. Everything after is the root module inside that copy.

`get_terragrunt_dir()` returns the directory of this `terragrunt.hcl`. So now the whole lab folder is copied, both modules included, and Terraform runs from the `modules/service` folder inside it. `../label` resolves.

(*Diagram: unit dir → copied to .terragrunt-cache; arrow "root module = modules/service"; "../label" now present.*)

[breath]

Plan again. `Plan: 3 to add, 0 to change, 0 to destroy.`

Confirm it. `find .terragrunt-cache -type d -name .terraform`. The `.terraform` folder sits inside the staged `modules/service`. That's where Terraform initialized. And right next to it is the `label` folder Terraform called.

[pause 1s]

The same rule applies to remote sources. A Git URL like `git::https://github.com/org/modules.git//vpc?ref=v1.4.0` copies the whole repository and runs the `vpc` folder inside it. That's how a module can reference its siblings with relative paths.

[breath]

Check the engine once more: `terragrunt run -- version`. Terraform 1.17. That's `terraform_binary` doing its job.

Now run `./check.sh`. It plans, checks the staged copy, applies, and destroys. The last line is `PASS 03.1 source`.

[pause 1s]

So remember: the module `source` is resolved by Terraform, relative to the module. The unit `source` is resolved by Terragrunt, and the double slash decides what gets copied. Next, locals and inputs.


---

# 03.2 `locals` and `inputs`

- **Estimated time:** 4 min
- **Lab path:** `labs/03-core-hcl/03.2-locals-inputs/` (`start/dev/`, `start/prod/`, `start/modules/record/`)
- **Section:** 03 · Core HCL

---

In this lab, two units share one module. Dev and prod. Same code, different values. That's the core pattern of Terragrunt, and it depends on two blocks: `locals` and `inputs`.

[pause 1s]

`locals` are values the unit computes for itself. `inputs` are values Terraform receives. Each input key becomes a variable in the root module.

Here's the point that trips people up: Terraform never reads `locals`. A local only reaches the module if an input passes it.

(*Diagram: `local.environment` → `inputs.environment` → `var.environment`; same for prefix and note.*)

[breath]

Open `start/dev/terragrunt.hcl`. The source is already set to `../modules/record`, one directory up.

Set `environment` to `dev`, and `prefix_root` to `lab`.

`prefix` is derived. It's already written as `"${local.environment}-${local.prefix_root}"`. Leave that expression alone. When you set the two values, it resolves to `dev-lab`.

[pause 1s]

Now pass them through. Add an `inputs` block with `environment`, `prefix`, and `note`, each set to the matching local.

Repeat the same thing in `start/prod/terragrunt.hcl`. Only `environment` changes, to `prod`. Keep `prefix_root` as `lab` and keep the same note.

[breath]

Plan from `start/dev`. Three to add, and the pet prefix is `dev-lab`. Plan from `start/prod`. Three to add, prefix `prod-lab`.

What did not change? The module. Same files for both. The only difference between the environments is the values in each unit.

[pause 1s]

And each unit is isolated. Each has its own `.terragrunt-cache`, its own working copy, and its own state. Destroying dev cannot touch prod, because they don't share a state file.

[breath]

Let's break it on purpose. Remove `note` from the dev inputs and plan.

(*Terminal: Terraform prompts for `var.note`.*)

Terraform stops and asks for `var.note`. The local is still there, but no input passed it. Press Ctrl-C and put it back.

The opposite mistake, an input the module doesn't declare, is quieter. Terraform ignores it. In lecture three-five we'll use `hcl validate --inputs --strict` to catch that. The checker for this lab already runs it.

[pause 1s]

Run `./check.sh` from `start/`. It plans, applies, and destroys both units. The last line is `PASS 03.2 locals and inputs`.

Notice, though, that dev and prod still repeat most of their file. Next lecture, functions start removing that repetition.


---

# 03.3 Built-in functions

- **Estimated time:** 5 min
- **Lab path:** `labs/03-core-hcl/03.3-functions/` (`start/root.hcl`, `start/region.hcl`, `start/dev/env.hcl`, `start/dev/unit/terragrunt.hcl`)
- **Section:** 03 · Core HCL

---

Terragrunt adds its own functions on top of HCL. In this lab we use four of them to read shared values from parent folders, instead of repeating them in every unit.

[pause 1s]

Look at the layout.

(*Screen: tree of `start/` — root.hcl, region.hcl, dev/env.hcl, dev/unit/terragrunt.hcl.*)

`root.hcl` holds `course`. `region.hcl` holds `region`. `dev/env.hcl` holds `environment` and `prefix_root`. And the unit sits at `dev/unit`.

Notice the file names. None of the parents is called `terragrunt.hcl`. That's deliberate. A file named `terragrunt.hcl` is a unit, and Terragrunt would try to run it. These are just data files.

[breath]

First function: `find_in_parent_folders`. You give it a file name. It walks upward from the unit's directory until it finds that file, and returns the absolute path. So `find_in_parent_folders("root.hcl")` finds the root file, no matter how deep the unit is.

Second: `read_terragrunt_config`. You give it a path, it parses the file, and you can read its locals under `.locals`.

[pause 1s]

Open `start/dev/unit/terragrunt.hcl` and replace the TODOs.

Add an `include "root"` block whose path is `find_in_parent_folders("root.hcl")`.

Then in `locals`, read the three files: `root_cfg`, `region_cfg`, and `env_cfg`, each with `read_terragrunt_config` and `find_in_parent_folders`.

Pull out `course`, `region`, and `environment`. Build `prefix` from environment, region, and `prefix_root`.

[breath]

Why both an include and a `read_terragrunt_config`? Because `include` merges the parent's blocks, things like `terraform` and `inputs`, into the unit. It does not copy the parent's `locals`. If you want the parent's locals, you read them.

And the include is needed for the third function: `path_relative_to_include("root")`. It returns the unit's path relative to the included root file. Here that's `dev/unit`. The label `"root"` must match the include label. In the next section this function becomes the state key for every unit.

[pause 1s]

Fourth: `get_env("LAB_NOTE", "offline functions lab")`. If the environment variable `LAB_NOTE` is set, you get its value. If not, you get the default.

[breath]

Plan from `start/dev/unit`. Three to add. The pet prefix is `dev-local-lab`. The triggers show `course = "terragrunt-labs"`, `region = "local"`, `unit_path = "dev/unit"`, and the default note.

Now apply, read the output, and destroy. Then run apply again with `LAB_NOTE="from the environment"` in front.

(*Terminal: `terragrunt output` — note changes.*)

The first note is the default. The second comes from the environment. `get_env` only falls back when the variable is unset.

[pause 1s]

If it fails: `find_in_parent_folders("TODO")` means you haven't set the file name. And `path_relative_to_include` without an include labeled `root` fails, because there's nothing to be relative to.

Run `./check.sh`. `PASS 03.3 functions`.

[breath]

Next lecture: `generate`, which writes Terraform files into the working copy before init.


---

# 03.4 `generate` blocks

- **Estimated time:** 4 min
- **Lab path:** `labs/03-core-hcl/03.4-generate/` (`start/terragrunt.hcl`, `start/modules/note/`)
- **Section:** 03 · Core HCL

---

A `generate` block writes a file into Terraform's working copy before init runs. In this lab we generate `versions.tf` and `provider.tf` for a module that ships neither.

[pause 1s]

Open `start/modules/note`. It has `main.tf`, `variables.tf`, and `outputs.tf`. No versions file, no provider file.

Why would a module leave those out? Because the provider configuration and the version pins belong to the environment, not to the module. If every unit generates them from one place, you change a version once and every unit follows. In the next section, that one place becomes `root.hcl`.

[breath]

Open `start/terragrunt.hcl`. Between the `terraform` block and `inputs`, add two blocks.

(*Screen: the `generate "versions"` block.*)

`generate "versions"`. `path` is `versions.tf`. `if_exists` is `overwrite_terragrunt`. And `contents` is a heredoc with the `terraform` block: `required_version` greater than or equal to 1.17.0 and below 1.18, plus the three providers with their constraints.

Then `generate "provider"`, path `provider.tf`, with three empty provider blocks: local, null, and random.

[pause 1s]

Two details. `path` is relative to the working copy, not to your source folder. The file never appears in git.

And the heredoc uses `<<-EOF`, with a dash. The dash strips the indentation, so the generated HCL starts in column zero.

[breath]

Now `if_exists`. It decides what happens when the file already exists in the working copy.

(*Diagram: table — overwrite / overwrite_terragrunt / skip / error.*)

`overwrite` replaces it. `skip` leaves it. `error` fails. And `overwrite_terragrunt` replaces the file only if Terragrunt wrote it. Terragrunt marks every generated file with a `# Generated by Terragrunt` line. On the second run it looks for that signature. If a hand-written file with the same name is already in the module, it fails rather than overwrite your work.

That's why we use `overwrite_terragrunt`. It's safe against a module author adding their own file later.

[pause 1s]

Plan. Three to add. Now look inside the cache: `find .terragrunt-cache -name versions.tf -o -name provider.tf`. Open one. The first line is `# Generated by Terragrunt`.

Plan a second time. It succeeds, because Terragrunt recognizes its own files and replaces them.

[breath]

The provider constraints, `~> 2.5`, `~> 3.2`, `~> 3.6`, match the lock file. Terragrunt copies that lock file next to the generated `versions.tf`, so init picks the same provider versions.

Run `./check.sh`. It plans twice, checks the generated files, applies, and destroys. `PASS 03.4 generate`.

Next, the tools that check your HCL before you run anything.


---

# 03.5 `hcl fmt`, `hcl validate`, and `render`

- **Estimated time:** 5 min
- **Lab path:** `labs/03-core-hcl/03.5-fmt-validate-render/` (`start/terragrunt.hcl`, `start/modules/record/`)
- **Section:** 03 · Core HCL

---

The unit in this lab is valid, but badly formatted. We'll format it, validate it, and then render it, so we can see the exact values Terraform will receive.

[pause 1s]

Start with formatting. `terragrunt hcl fmt --diff`.

(*Terminal: diff output.*)

You see the diff, and the file is rewritten. `fmt` and `format` are the same command. It formats `*.hcl` files under the current directory. It doesn't touch `.tf` files. That's Terraform's job.

Now `terragrunt hcl fmt --check`. It exits zero when everything is formatted, and one when something would change. That exit code is what you put in CI.

[breath]

Next, validation. There are two levels.

`terragrunt hcl validate` parses the HCL. Syntax errors, unknown blocks, bad expressions.

`terragrunt hcl validate --inputs --strict --tf-path terraform` goes further. It reads the module's variables. `--inputs` checks that every required variable is set. `--strict` also rejects any input the module does not declare.

[pause 1s]

Why `--tf-path terraform`? Because `hcl validate --inputs` asks the engine about the module, and by default it calls `tofu`. `terraform_binary` in the unit doesn't affect this command. So we pass the path explicitly. `terragrunt run` still follows `terraform_binary`.

[breath]

Break it once. Add an input called `colour` and run the strict validate.

(*Terminal: `inputs that are not defined in the OpenTofu/Terraform module`.*)

Rejected. Without `--strict`, Terraform would ignore that input and you'd never know you had a typo. Remove it.

[pause 1s]

Now `render`. `terragrunt render`.

(*Screen: rendered HCL — inputs show "dev", "lab", "rendered offline".*)

This is the unit after Terragrunt has resolved everything. Locals are evaluated. Function calls are replaced by their results. The `inputs` show `"dev"`, `"lab"`, and `"rendered offline"`, not `local.environment`.

When something looks wrong in a bigger setup, with includes and parent files, `render` is the first thing to run. It shows the final configuration instead of the configuration you think you wrote.

`terragrunt render --format json` prints the same result as one JSON object. That's useful for scripts and `jq`.

[breath]

There's also `--write`, which saves `terragrunt.rendered.hcl` next to the unit. This lab reads stdout. If you try `--write`, delete that file before you commit.

[pause 1s]

Confirm the engine and the plan. `terragrunt run -- version`, Terraform 1.17. `terragrunt run plan`, three to add.

Run `./check.sh`. It formats, validates, renders, plans, applies, and destroys, starting from a cold cache. `PASS 03.5 fmt, validate, and render`.

[breath]

That closes core HCL. One unit, fully understood. But every unit still carries its own copy of the provider and backend config. Next section, `include` fixes that.


---

# 04.1 `root.hcl` + `include`

- **Estimated time:** 5 min
- **Lab path:** `labs/04-include/04.1-root-include/` (`start/root.hcl`, `start/unit/terragrunt.hcl`)
- **Section:** 04 · Include & root

---

Open three environment folders in a typical Terraform repo and you'll find the same backend block, the same provider pin, and the same tags, copied three times. Change the state bucket once, and you have three files to touch and three chances to miss one. If you miss prod, prod plans against the wrong state.

The `include` block is how Terragrunt keeps that configuration in one place.

[pause 1s]

Look at the layout. `start/root.hcl` at the top, and `start/unit/terragrunt.hcl` below it.

(*Screen: `start/root.hcl`.*)

`root.hcl` holds `terraform_binary = "terraform"`, and shared inputs: `course` and `note`.

The name matters. In older Terragrunt projects, and in a lot of blog posts, the root file was also called `terragrunt.hcl`. In 1.x, use `root.hcl`. Terragrunt treats any directory with a `terragrunt.hcl` as a unit. A parent file with that name would become a unit of its own, and `run --all` would try to run it.

[breath]

Open `start/unit/terragrunt.hcl` and replace the TODOs.

`include "root"`, with `path = find_in_parent_folders("root.hcl")`.

Then the unit's inputs: `prefix = "lab"`, and `note = "from the unit"`. Leave `course` out. It should come from the root.

Notice the unit does not set `terraform_binary` either.

[pause 1s]

Run `terragrunt run -- version`. Terraform 1.17. The unit didn't set the binary, so it came from the root through the include.

Now `terragrunt render`.

(*Screen: render — terraform_binary, course, prefix, note.*)

`terraform_binary = "terraform"`. `course = "terragrunt-labs"`, from the root. `prefix = "lab"` and `note = "from the unit"`, from the unit.

[breath]

So what happened with `note`? Both files set it, and the unit won. That's the default merge strategy, called `shallow`. For each top-level key in `inputs`: if the unit leaves it unset, the root value stays. If both set it, the unit wins.

Prove it. Comment out `note` in the unit and render again. Now `note = "from root"`. Put it back, because the checker expects the unit value.

[pause 1s]

One thing `include` does not do: it doesn't copy the parent's `locals` into the unit. Parent locals stay in the parent. You saw one way to read them in lecture three-three, with `read_terragrunt_config`. In lecture four-three you'll see the other way, `expose`.

[breath]

Plan. Three to add. Apply, `terragrunt output`, and destroy. `course` is `terragrunt-labs`. `note` is `from the unit`. The name starts with `lab-`.

From `start/`, run `./check.sh`. `PASS 04.1 root include`.

If the checker fails on `hcl fmt --check`, your alignment differs. Run `terragrunt hcl fmt` and run the checker again.

[pause 1s]

Shallow merge works for flat values. But what about a map of tags, where you want to add one key and keep the rest? That's the next lecture.


---

# 04.2 Merge strategies

- **Estimated time:** 6 min
- **Lab path:** `labs/04-include/04.2-merge/` (`start/root.hcl`, `start/shallow/`, `start/deep/`, `start/no_merge/`)
- **Section:** 04 · Include & root

---

In this lab, three units include the same `root.hcl` and set the same kind of override. The only thing that changes is `merge_strategy`. That way you see exactly what each strategy does.

[pause 1s]

Open `start/root.hcl`. It sets `terraform_binary`, and four inputs. `course`. `note = "from root"`. A `tags` map with three keys: owner, tier, and cost_center. And a `labels` list: course, shared.

Each unit overrides `note`, sets `tags` to a one-key map, `tier = "app"`, and sets `labels` to a one-item list, `unit`.

[breath]

`merge_strategy` is an argument on the `include` block. There are three values.

(*Diagram: table — shallow / deep / no_merge across scalars, maps, lists.*)

`shallow`. Scalars: the unit wins. Maps: the unit map replaces the root map entirely. Lists: the unit list replaces the root list.

`deep`. Scalars: the unit still wins. Maps: the keys merge, and the unit wins on a shared key. Lists: root items first, then unit items.

`no_merge`. Nothing from the root is applied. Not inputs, not `terraform_binary`, nothing.

[pause 1s]

Start with `start/shallow/terragrunt.hcl`. Set the include with `merge_strategy = "shallow"`. That's the default, but writing it makes the intent clear.

Render.

(*Screen: shallow render.*)

`tags` has only `tier = "app"`. Owner and cost_center are gone. The unit map replaced the root map. `labels` is just `["unit"]`.

[breath]

This is the classic surprise. Someone adds one tag in a unit and the shared tags vanish from every resource in it. Shallow merge isn't broken. It replaces at the top level, exactly as designed.

[pause 1s]

Now `start/deep`. Same include, `merge_strategy = "deep"`. Render.

`tags` has owner, cost_center, and `tier = "app"`. The keys merged, and the unit's `tier` won. `labels` is `["course", "shared", "unit"]`. Root items, then unit items.

That's usually what you want for tags.

[breath]

Now `start/no_merge`. This one needs more. Add `expose = true` and `merge_strategy = "no_merge"`.

`expose` means: parse the parent and make it available as `include.root`. `no_merge` means: don't apply any of it automatically.

So the unit picks what it wants. `course = include.root.inputs.course`. Everything else is the unit's own.

And because nothing is merged, `terraform_binary` doesn't come through either. The unit sets it itself.

[pause 1s]

Try removing that line and running `terragrunt run -- version`.

(*Terminal: OpenTofu version.*)

OpenTofu. `tofu` is on the path, and the root value wasn't merged. Put the line back.

[breath]

Render `no_merge`. `course` came through `expose`. Tags and labels are only the unit's values.

When would you use `no_merge`? When a parent file is pure data, like a region file or an env file. You want to read its values, but you don't want it injecting blocks into your unit if someone adds one later. That's the next lecture.

[pause 1s]

Plan each unit: three to add, Terraform 1.17 in all three. From `start/`, run `./check.sh`. It renders, plans, applies, and destroys all three. `PASS 04.2 merge`.

Quick rule of thumb. Shallow for flat inputs. Deep when the root holds maps or lists you want to extend. No-merge with expose when the parent is only data.


---

# 04.3 Multiple includes

- **Estimated time:** 6 min
- **Lab path:** `labs/04-include/04.3-multi-include/` (`start/root.hcl`, `start/region.hcl`, `start/dev/env.hcl`, `start/dev/unit/terragrunt.hcl`)
- **Section:** 04 · Include & root

---

One unit can include more than one parent. In this lab, the unit includes a root file, a region file, and an env file, and reads values from each one with `include.<label>`.

[pause 1s]

The layout is the same shape as lecture three-three. `root.hcl` with `course` and `terraform_binary`. `region.hcl` with `region`. `dev/env.hcl` with `environment` and `prefix_root`. The unit at `dev/unit`.

In three-three we read those files with `read_terragrunt_config`. Now we do it with includes, and `expose`.

[breath]

Open `start/dev/unit/terragrunt.hcl` and replace the TODOs.

First, `include "root"`. Path from `find_in_parent_folders("root.hcl")`, and `expose = true`. Default merge, so shallow.

Second, `include "region"`. Path to `region.hcl`, `expose = true`, and `merge_strategy = "no_merge"`.

Third, `include "env"`. Same pattern, `env.hcl`, exposed, no merge.

[pause 1s]

Why different strategies? The root has to merge, because `terraform_binary` lives there and must reach the unit. The region and env files are data. We want their values, but we don't want them merged in. If someone later adds an `inputs` block to `region.hcl`, it won't silently land in every unit.

(*Diagram: unit with three arrows — root (merge), region (expose only), env (expose only).*)

[breath]

Now the locals.

`course = include.root.locals.course`. `region = include.region.locals.region`. `environment = include.env.locals.environment`.

Exposing a parent still doesn't copy its locals into yours. It gives you a handle, `include.<label>`, and you read from it.

`prefix` joins environment, region, and `prefix_root`. `unit_path = path_relative_to_include("root")`. With more than one include, this function needs the label. Pass `"root"`, so the path is relative to the root file. And `note = "exposed includes"`.

[pause 1s]

Keep the `inputs` block as it is.

Run `terragrunt run -- version`. Terraform 1.17. Then `terragrunt render`. `course = "terragrunt-labs"`, `region = "local"`, `environment = "dev"`, `prefix = "dev-local-lab"`, `unit_path = "dev/unit"`.

Plan. Three to add.

[breath]

Let's break one thing. Remove `expose = true` from the region include, and render.

(*Terminal: `include.region` unknown.*)

`include.region` is unknown. Without `expose`, the include exists but you can't read from it. Put it back.

And one more. Set the root include to `no_merge` and run the version check. OpenTofu. Because `terraform_binary` stayed in the root. That's why `no_merge` goes on the data files only.

[pause 1s]

Apply, output, destroy. The name starts with `dev-local-lab-`.

`./check.sh` from `start/`. `PASS 04.3 multiple includes`.

[breath]

`read_terragrunt_config` and exposed includes both work. The difference: includes are declared at the top, they're visible in `render`, and `path_relative_to_include` can use them. Next lecture, we put all of this into a real directory layout: account, region, environment, unit.


---

# 04.4 Account / region / env / unit layout

- **Estimated time:** 8 min
- **Lab path:** `labs/04-include/04.4-env-layout/` (`start/sandbox/local/{dev,prod}/record/terragrunt.hcl`, `account.hcl`, `region.hcl`, `env.hcl`)
- **Section:** 04 · Include & root

---

This is the layout you'll see in most Terragrunt repos. Four levels: account, region, environment, unit. Each level has one small file with that level's values. The unit at the bottom includes all of them.

The goal of this lab: dev and prod run the exact same `terragrunt.hcl`. Only `env.hcl` differs.

[pause 1s]

(*Screen: tree of `start/`.*)

At the top, `root.hcl` and one shared module under `modules/record`.

Then `sandbox`. That's the account. It has `account.hcl` with `account_name = "sandbox"`.

Under it, `local`. That's the region. In a cloud lab this would be `us-east-1` or `eu-west-1`. Here it's `local`, so nothing leaves your machine. `region.hcl` sets `region = "local"`.

Under the region, `dev` and `prod`. Each has an `env.hcl`. Dev sets `environment = "dev"`. Prod sets `environment = "prod"`. Both set `prefix_root = "lab"`.

And under each environment, `record`. That's the unit.

[breath]

The reason for this shape: the path to a unit describes exactly where it deploys. `sandbox/local/prod/record` reads as: sandbox account, local region, prod environment, record unit. And as you'll see in the next section, that same path becomes the state key.

[pause 1s]

Open `start/sandbox/local/dev/record/terragrunt.hcl` and replace the TODOs.

Four includes, following the pattern from the last lecture.

`include "root"`, exposed, default merge, because it carries `terraform_binary`.

`include "account"`, `include "region"`, `include "env"`. Each exposed, each `no_merge`. They're data.

[breath]

Then the locals. `course` from the root. `account` from `include.account.locals.account_name`. `region` from the region include. `environment` from the env include.

`prefix` is account, environment, and `prefix_root`. So `sandbox-dev-lab`.

`unit_path = path_relative_to_include("root")`.

[pause 1s]

Now look at the `terraform` block, which is already in the file.

`source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/record"`.

Why not `../../../../modules/record`? Because counting `../` breaks the moment someone moves a unit one level deeper. This expression finds the root file, takes its directory, and goes from there. It works in `start`, it works in `solution`, it works at any depth.

[breath]

Now the step that shows why this layout works. Copy the dev `terragrunt.hcl` over the prod one. Don't edit it. Identical files.

How does prod get prod values? `find_in_parent_folders("env.hcl")` walks upward from the unit and stops at the first match. From the prod unit, the first `env.hcl` it meets is `prod/env.hcl`. The function does the environment selection for you.

(*Diagram: two identical unit files; arrows walking up to different env.hcl files, same region.hcl, account.hcl, root.hcl.*)

[pause 1s]

Render from the dev unit. `account = "sandbox"`, `region = "local"`, `environment = "dev"`, `prefix = "sandbox-dev-lab"`, `unit_path = "sandbox/local/dev/record"`.

Render from the prod unit. `environment = "prod"`, `prefix = "sandbox-prod-lab"`, `unit_path = "sandbox/local/prod/record"`.

Same file, different results, because of where it sits.

[breath]

Plan both. Three to add each. Each unit has its own cache and its own state.

Now think about what adding staging costs. A `staging` folder with one `env.hcl`, and a copy of the same unit file. No module changes. No new backend config. Adding a new region is the same: one folder, one `region.hcl`.

[pause 1s]

Common failures. If prod renders `environment = "dev"`, the prod unit is in the wrong folder, so the walk upward found dev's file. If the source can't find the module, someone replaced the `dirname` expression with a `../` count. And the checker compares the two unit files. If they differ, it fails. The point is to change `env.hcl`, not the unit.

[breath]

From `start/`, `./check.sh`. It plans, applies, and destroys both units. `PASS 04.4 environment layout`.

[pause 1s]

That's include. One root, small data files per level, identical units. Next section, we move state out of the cache and into a proper backend, using that unit path as the key.


---

# 05.1 `remote_state` (local backend)

- **Estimated time:** 6 min
- **Lab path:** `labs/05-remote-state/05.1-remote-state/` (`start/root.hcl`, `start/dev/`, `start/prod/`)
- **Section:** 05 · Remote state

---

So far, every unit's state has lived inside `.terragrunt-cache`. That's fine for a demo and dangerous for anything else. The cache is a download cache. Delete it, and you delete your state with it.

In this lecture we move state out, with a `remote_state` block. We'll use the local backend, so it stays offline, but the mechanism is exactly what you'll use with S3 in the next lecture.

[pause 1s]

`remote_state` lives in `root.hcl`, so every unit gets it from one place. It has three parts.

(*Screen: `start/root.hcl`, remote_state block.*)

`backend`. The Terraform backend name. Here, `local`.

`config`. The backend's arguments. The local backend takes one: `path`.

And `generate`. This tells Terragrunt to write a `backend.tf` into the working copy before init. Same mechanism as the `generate` blocks in lecture three-four, same `if_exists = "overwrite_terragrunt"`.

[breath]

That's why Terragrunt can do something plain Terraform can't. A Terraform `backend` block can't use variables or functions. A `remote_state` block can. Terragrunt evaluates the expressions, then writes a plain `backend.tf` with literal values.

[pause 1s]

Now the path. Replace the TODO with:

`"${get_parent_terragrunt_dir()}/state/${path_relative_to_include()}/terraform.tfstate"`.

Two functions. Let's take them one at a time.

`get_parent_terragrunt_dir()` returns the absolute directory of `root.hcl`. Why absolute? Because a relative path is resolved from where Terraform runs, and Terraform runs inside the cache. A relative path would put the state right back in the cache.

`path_relative_to_include()` returns the unit's path relative to the root. Here, `dev` or `prod`. That's what keeps the two units in separate files. Without it, both units would write the same state file, and prod would overwrite dev.

(*Diagram: root.hcl → state/dev/terraform.tfstate, state/prod/terraform.tfstate.*)

[breath]

From `start/dev`, run `terragrunt render`. `backend = "local"`, and a path ending in `state/dev/terraform.tfstate`. From `start/prod`, the path ends in `state/prod`.

Plan each. Three to add.

[pause 1s]

Now the test that matters. Apply dev. Then:

`find ../state -name terraform.tfstate`. There it is, next to `root.hcl`.

`find .terragrunt-cache -name backend.tf`. Open it. `# Generated by Terragrunt`, a `backend "local"` block, and the absolute path.

Now delete the cache. `rm -rf .terragrunt-cache`. And run `terragrunt output`.

(*Terminal: outputs still print.*)

The outputs still come back. Terragrunt rebuilt the working copy, regenerated `backend.tf`, and Terraform read the state from its real location. `environment = "dev"`, `prefix = "dev-lab"`, `note = "local remote state"`.

[breath]

Apply prod. A second state file appears under `state/prod`. Dev's file still records `dev-lab`. Separate keys, separate state.

Destroy both units from their own directories.

[pause 1s]

The `state` folder is gitignored. That's right for a lab. On a team, state has to be shared and locked, which a file on your laptop can't do. That's the S3 backend, next.

Run `./check.sh`. It plans, applies, removes each cache, reads outputs, checks both state files, and destroys. `PASS 05.1 remote state`.


---

# 05.2 ☁️ `backend bootstrap` + S3 / `use_lockfile`

- **Estimated time:** 8 min
- **Lab path:** `labs/05-remote-state/05.2-backend-bootstrap/` (`start/root.hcl`, `start/dev/`, `start/prod/`) — AWS needed for bootstrap/apply; `check.sh` is offline
- **Section:** 05 · Remote state

---

Now we point the same `remote_state` block at S3. This is the setup you'd use on a real team: shared state, encrypted, versioned, and locked.

This lecture needs an AWS account for the bootstrap and the apply. The checker doesn't. It validates the config and renders both units offline. So do the offline part first, and only then spend time on credentials.

[pause 1s]

The resources in the unit don't change. Still `local`, `null`, and `random`. AWS is only the state backend.

[breath]

Open `start/root.hcl`. `backend = "s3"`. The `generate` block stays the same as last lecture. Replace the `config` TODOs.

(*Screen: config block.*)

`bucket`. A lowercase name, unique across all of AWS. The file ships with a placeholder, `example-terragrunt-labs-state`, so the render has a legal name. Replace it with your own before you bootstrap.

`key = "${path_relative_to_include()}/terraform.tfstate"`. Same idea as the local path. Dev gets `dev/terraform.tfstate`, prod gets `prod/terraform.tfstate`.

`region`, `us-east-1` or whatever you use. `encrypt = true`.

And `use_lockfile = true`.

[pause 1s]

Let's talk about that last one, because it changed recently. For years, S3 state locking needed a DynamoDB table. Since Terraform 1.10, the S3 backend can lock with the bucket itself. When an operation starts, Terraform writes a `.tflock` object next to the state object. When it finishes, it removes it. A second apply sees the lock and waits or fails.

So in this lab, we leave `dynamodb_table` unset. If you add it, Terragrunt will also create a DynamoDB table, which we don't need.

[breath]

One more trap. `use_lockfile = true`, not `"true"` in quotes. A quoted string is rejected by Terraform. Check it with `terragrunt render --format json`. You should see `"use_lockfile":true` as a boolean.

[pause 1s]

Render from `start/dev`: `backend = "s3"`, your bucket, `key = "dev/terraform.tfstate"`, `encrypt = true`, `use_lockfile = true`. Render from `start/prod`: same bucket, key `prod/terraform.tfstate`.

Run `./check.sh`. You'll see `PASS 05.2 backend bootstrap` and a line saying AWS was not contacted. That's the offline part done.

[breath]

Now, why does `backend bootstrap` exist? Terraform won't create the bucket it stores state in. Something has to create it first. And you don't want to manage that bucket with Terraform state stored in that same bucket. That's a loop.

`terragrunt backend bootstrap` reads the `remote_state` block and creates the bucket if it's missing. On a bucket it creates, it turns on versioning, server-side encryption, Block Public Access, and a bucket policy that requires TLS. Run it again, and it sees the bucket and leaves it alone.

(*Diagram: remote_state → backend bootstrap → S3 bucket (versioning, SSE, BPA, TLS policy); dev/ and prod/ keys with .tflock.*)

[pause 1s]

AWS part. Use a sandbox account. Credentials in your environment: `AWS_PROFILE`, or access key variables. Never commit them.

From `start/dev`:

`terragrunt --non-interactive backend bootstrap`. Then `terragrunt run plan`. Then apply with `-auto-approve`.

You can also combine the first and last step: `terragrunt run --backend-bootstrap -- apply`. Same work, one command.

[breath]

From `start/prod`, bootstrap and apply again. This time the bucket exists, so bootstrap does nothing. Prod's state goes to `prod/terraform.tfstate`.

Confirm: `aws s3 ls` on the `dev/` prefix and the `prod/` prefix. One state object each.

[pause 1s]

If you list during an apply, you'll also see `dev/terraform.tfstate.tflock`. That's the lock. It disappears when the apply finishes. If one is left behind, either an apply is still running or a run was interrupted. Only break a lock when you're certain nothing else is writing that state.

[breath]

Clean up. Destroy both units. Then remove the state objects. `terragrunt backend delete`, run from a unit, deletes that unit's state object, but leaves the bucket. Because versioning is on, `aws s3 rb --force` will fail while old versions remain. Empty the bucket in the S3 console, which deletes the versions, then delete it.

[pause 1s]

Common errors: `NoSuchBucket` means you haven't bootstrapped. `BucketAlreadyExists` means someone else in the world has that name. Pick another. And `disable_init = true` stops Terragrunt from creating the bucket at all, so leave it out.

Next, a question people always ask: why not just use Terraform workspaces?


---

# 05.3 Directories vs Terraform workspaces

- **Estimated time:** 6 min
- **Lab path:** `labs/05-remote-state/05.3-vs-workspaces/` (`start/layout/`, `start/workspaces/main.tf`)
- **Section:** 05 · Remote state

---

There are two common ways to keep dev and prod state apart. Directories, which is what Terragrunt does. And Terraform workspaces. In this lab we run the same data both ways and look at where the state ends up.

[pause 1s]

The lab has two trees. `layout` is lecture five-one, copied so this lab stands alone. A root, a module, a dev unit, and a prod unit. Don't change it.

`workspaces` is plain Terraform. One `main.tf`, one `versions.tf` with a local backend, one `outputs.tf`. One configuration for every environment.

[breath]

Start with the Terragrunt side. From `start/layout/dev`, run `terragrunt run -- workspace show`.

(*Terminal: `default`.*)

`default`. As we saw in lecture two-three, `workspace` isn't a Terragrunt shortcut, so we forward it through `run --`. And the answer is `default`, because the unit doesn't need a workspace. The directory already separates the state.

Render: `environment = "dev"`, `prefix = "dev-lab"`. Do the same in prod. Plan both. The state files land under `layout/state/dev` and `layout/state/prod`.

[pause 1s]

Now the workspace side. Open `start/workspaces/main.tf`. Set `environment = terraform.workspace`. That's the whole edit. The environment name comes from whichever workspace is selected.

Leave the `lifecycle` precondition in place. It rejects the `default` workspace. We'll see why in a moment.

[breath]

From `start/workspaces`, `terraform init`, then `terraform apply`.

(*Terminal: `Create a named workspace before apply`.*)

It fails. We're on `default`, and the precondition stopped it. That's on purpose. With workspaces, forgetting to select one is the most common mistake, and the result is resources in an environment called `default` that nobody meant to create.

[pause 1s]

`terraform workspace new dev`, apply. `terraform workspace new prod`, apply. `terraform workspace show` prints `prod`. `terraform output` shows `environment = "prod"`.

Where's the state? Not at the path in `versions.tf`. That path is only used for `default`. Named workspaces use `terraform.tfstate.d/dev/terraform.tfstate` and `terraform.tfstate.d/prod/terraform.tfstate`, next to the configuration.

[breath]

Now compare.

(*Diagram: two columns — Directory per environment / Terraform workspaces; rows: where you select, state path, current selection, code.*)

With directories, where you select the environment is the directory you `cd` into. It's visible in your prompt, in the path, in the CI log.

With workspaces, the selection is a name stored in `.terraform/environment`. It's invisible state on your machine. Same command, same folder, different target, depending on what you ran earlier.

[pause 1s]

With directories, each environment has its own `terragrunt.hcl`, so it can have different inputs, a different module version, even a different account. With workspaces, it's one `main.tf` for everything. Differences have to be expressed as conditionals on `terraform.workspace`.

And with directories, the backend can differ per environment. Prod state in the prod account. With workspaces, every environment shares one backend configuration.

[breath]

That's why this course keeps Terragrunt units on the `default` workspace, and splits state by directory. You should still recognize the workspace layout, because you'll meet it in existing code.

[pause 1s]

Clean up. In `workspaces`, select prod and destroy, select dev and destroy, select default, then delete both workspaces. Then destroy both layout units with Terragrunt.

`./check.sh` runs both trees, checks all four state paths, and destroys them. `PASS 05.3 terragrunt and workspaces`.

Next section: units that depend on each other's outputs.


---

# 06.1 `dependency` blocks

- **Estimated time:** 5 min
- **Lab path:** `labs/06-dependencies/06.1-dependency/` (`start/network/`, `start/service/terragrunt.hcl`)
- **Section:** 06 · Dependencies & `run --all`

---

Once you split infrastructure into units, one unit will need a value from another. The app needs the network ID. The service needs the database endpoint. In plain Terraform you'd use a `terraform_remote_state` data source and hard-code where the other state lives. In Terragrunt, you use a `dependency` block.

[pause 1s]

This lab has two units. `network`, which is finished. And `service`, which will read the network's `name` output.

Open `start/network/terragrunt.hcl`. `prefix = "net"`, `note = "network unit"`. Its module outputs a `name`, a random pet like `net-smart-cattle`.

[breath]

Now `start/service/terragrunt.hcl`. Replace the TODO.

`dependency "network"`, with `config_path = "../network"`. That path is relative to the service unit. It points at another unit's directory, not at a state file.

Then the inputs. `environment = "dev"`, `prefix = "svc"`, and `note = dependency.network.outputs.name`.

(*Diagram: network output `name` → dependency.network.outputs.name → inputs.note → var.note.*)

[pause 1s]

How does Terragrunt get that value? It goes to the network unit, reads its state, and pulls the outputs. It doesn't matter where that state lives. Local file, S3, another account. Terragrunt reads the network unit's own `remote_state` config to find it. You never write the state location twice.

[breath]

Now plan the service, before network exists.

(*Terminal: `detected no outputs`.*)

It stops. `../network` is a dependency, and Terragrunt detected no outputs. That's correct. Network has never been applied, so its state has nothing in it. There's no value to pass.

We'll handle that case with mocks in the next lecture. For now, do it in order.

[pause 1s]

`cd ../network`, apply, and `terragrunt output -raw name`. Note the pet name.

`cd ../service`. Plan. Three to add. Apply. `terragrunt output -raw note`.

(*Terminal: same pet name.*)

The same string. It's not written anywhere in the service file. It came from the network state at plan time.

[breath]

Order matters on the way down too. Destroy service first, then network. If you destroy network while service still reads it, service is left pointing at a unit with no outputs, and its next plan fails.

Run `./check.sh` from `start/`. It plans service once before network exists, to show that error, then applies both and destroys in the right order. `PASS 06.1 dependency`.

[pause 1s]

Two units in order is easy to do by hand. Ten units isn't. But first, mocks.


---

# 06.2 Mock outputs

- **Estimated time:** 5 min
- **Lab path:** `labs/06-dependencies/06.2-mock-outputs/` (`start/service/terragrunt.hcl`)
- **Section:** 06 · Dependencies & `run --all`

---

Last lecture, the service couldn't plan until network was applied. That's a problem in two places. On a fresh environment, where nothing exists yet. And in CI, where you want to plan every unit on a pull request before anything is applied.

`mock_outputs` solves that, with strict rules about when they apply.

[pause 1s]

Open `start/service/terragrunt.hcl`. The dependency and `inputs.note` are already there from last lecture. Add two attributes inside the dependency block.

`mock_outputs = { name = "mock-network-name" }`. The keys are output names. The service reads `name`, so we mock `name`.

`mock_outputs_allowed_terraform_commands = ["validate", "plan"]`.

[breath]

Terragrunt uses a mock only when two things are true at once. The dependency has no outputs in its state. And the command you're running is in the allowed list.

(*Diagram: two conditions — "no outputs in state" AND "command in allow list" → use mock.*)

[pause 1s]

Plan the service, with no network state.

(*Terminal: warning, then `Plan: 3 to add`.*)

Terragrunt warns that network has no outputs and that it's returning the mocks. The plan works. `note` is `mock-network-name`.

Now try to apply.

(*Terminal: `detected no outputs`.*)

It fails. `apply` isn't in the allow list. And that's the point. A mock is a placeholder for planning. You never want a fake value written into real infrastructure. If someone adds `apply` to that list, a cold apply would succeed with `mock-network-name` baked into a resource. Keep `apply` out.

[breath]

Now apply network. `terragrunt output -raw name`. Back to service, and plan.

The plan now shows the real pet name. Not the mock. Once the dependency has real outputs, Terragrunt uses them. A mock never overrides a real output.

Apply the service. `terragrunt output -raw note` equals the network name.

[pause 1s]

One gotcha. If you still see `mock-network-name` after network was applied, the plan ran against an old cache. Run the plan again from `service/`.

And a planning caveat. A plan built on mocks only tells you the shape of the change. The real values arrive at apply time. Review accordingly.

[breath]

Destroy service, then network. `./check.sh` from `start/`. `PASS 06.2 mock outputs`.

Next, we let Terragrunt figure out the order for us.


---

# 06.3 `run --all` and `--graph`

- **Estimated time:** 6 min
- **Lab path:** `labs/06-dependencies/06.3-run-all/` (`start/network/`, `start/database/`, `start/service/`)
- **Section:** 06 · Dependencies & `run --all`

---

Now we have a chain of three units. Network, database, service. Database reads network. Service reads database. All three are already written. This lecture is about the queue: running them all in the right order with one command.

[pause 1s]

(*Screen: tree — network, database, service.*)

Each dependent unit has mocks for `validate` and `plan`, exactly like the last lecture. Database mocks `mock-network-name`. Service mocks `mock-db-name`.

[breath]

From `start/`, run `terragrunt --non-interactive run --all -- plan -input=false`.

(*Terminal: queue of three units.*)

`--all` is a flag on `run`. In 0.x this was a separate command called `run-all`. In 1.x it's `run --all`, and Terraform arguments still go after the double dash.

Terragrunt discovers every unit under the current directory, reads their dependency blocks, and builds a graph. Then it runs them in order. Units with no dependencies first. Units that depend on them after. Units at the same level run in parallel.

[pause 1s]

Look at the plan. Network's note is `network unit`. Database's note is `mock-network-name`. Service's note is `mock-db-name`. Nothing is applied yet, so every dependent sees a mock. Three to add in each.

[breath]

Now apply. `terragrunt --non-interactive run --all -- apply -input=false`.

Notice we didn't pass `-auto-approve`. `run --all apply` and `run --all destroy` add it for you. That's why `--non-interactive` matters here. Terragrunt asks once, for the whole queue, and the flag answers that prompt.

The order is network, then database, then service. Each one waits for its dependencies. So by the time database applies, network has real outputs, and the mock is gone.

[pause 1s]

Check it. From `start/`, use `--working-dir` so you don't have to `cd`.

`terragrunt --working-dir network output -raw name`. `--working-dir database output -raw note`. The same string.

Database's `name`, and service's `note`. The same string. No mocks left.

[breath]

Now `--graph`. `--all` says: everything under this directory. `--graph` says: this unit, and everything that depends on it.

(*Diagram: table — run --graph from network / database / service and what's queued.*)

From `network/`, `--graph` queues all three, because database and service both depend on network, directly or indirectly. From `database/`, it queues database and service. Network isn't in the queue, because it's a dependency, not a dependent. From `service/`, only service.

That's the command you want after changing a shared unit. "I changed network. Plan everything affected by it."

[pause 1s]

One practical note. To find dependents, `--graph` walks up to the git root and scans every unit it finds. In this course repo, that's every lecture. So the checker copies this lab into a temporary directory, runs `git init` there, and runs `--graph` in the copy. The README has the exact commands. In your own repo, you'd just run it.

From the network copy, the graph plans three units. From service, one.

[breath]

Destroy the queue from `start/`: `run --all -- destroy`. Service goes first, then database, then network. The exact reverse.

`./check.sh`. `PASS 06.3 run all`.

Next, how to see that graph before you run anything.


---

# 06.4 `find`, `list`, and `dag graph`

- **Estimated time:** 4 min
- **Lab path:** `labs/06-dependencies/06.4-find-list-dag/` (`start/` — network, database, service, audit)
- **Section:** 06 · Dependencies & `run --all`

---

Before you run a queue, you want to know what's in it and in what order. In this lecture nothing is applied. We only read the HCL with three commands: `find`, `list`, and `dag graph`.

[pause 1s]

The layout is the chain from last lecture, plus one more unit, `audit`, which depends on nothing.

From `start/`, run `terragrunt find`.

(*Terminal: audit, database, network, service.*)

One path per line, alphabetical. Four units. `find` discovers units under the working directory. It doesn't walk the rest of the repository.

Add `--json --dependencies`. Now each unit has a `dependencies` array. Database depends on network. Service depends on database. Audit and network have none.

[breath]

`find` tells you what exists. `list --dag` tells you the order.

`terragrunt list --dag`.

Audit and network come first, because they have no dependencies. Then database. Then service. That's the order `run --all` would use.

[pause 1s]

`terragrunt list --long --dependencies --dag` gives you a table. Type, path, dependencies. Unit audit. Unit network. Unit database, depends on network. Unit service, depends on database.

And `terragrunt list --tree --dag` draws it.

(*Screen: tree — audit; network → database → service.*)

Dependents sit under the unit they read. Audit stands alone. Network has database under it, and service under that.

[breath]

Last, `terragrunt dag graph`. This prints a Graphviz DOT graph. You'll see `"database" -> "network"` and `"service" -> "database"`. Audit is a node with no arrows.

`dag graph` is a shortcut for `list --format=dot --dependencies --external`. If you have Graphviz installed, pipe it into `dot -Tsvg` and you get a picture. Useful for a design review, or for a README in a big repo.

[pause 1s]

One rule: run these from the directory you care about. If you run `find` from the root of this course repo, you'll get every unit from every lecture.

`./check.sh` from `start/`. It only reads the DOT and list output. `PASS 06.4 find, list, and the dag`.

Next, the most important part of `run --all`: making sure the queue contains only what you mean to touch.


---

# 06.5 Safe scoping and the destroy trap

- **Estimated time:** 5 min
- **Lab path:** `labs/06-dependencies/06.5-scoping/` (`start/network/`, `start/apps/{api,worker,legacy}/`)
- **Section:** 06 · Dependencies & `run --all`

---

`run --all` is powerful because it touches many units at once. That's also why it's dangerous. In this lecture we control exactly which units are in the queue, and we look at one destroy command that removes more than you typed.

[pause 1s]

The layout: a shared `network` unit, and next to it an `apps` folder with three units. `api`, `worker`, and `legacy`. Each app depends on `../../network`.

From inside `apps/`, network is an **external dependency**. The apps depend on it, but it lives outside the working directory.

[breath]

From `start/`, plan everything: `run --all -- plan`. Four units. Network and the three apps.

Now `cd apps` and plan again. Three units. Network isn't in the queue. In Terragrunt 1.2, external dependencies are excluded from `run --all` by default. The apps still read network's outputs, but network itself isn't planned or applied.

[pause 1s]

In older versions, you had to ask for that with `--queue-exclude-external`. Try it. It works, but it warns that the flag is deprecated, because this is now the default.

[breath]

Now exclude one unit. You might guess `--exclude-dir`. Try it.

(*Terminal: error naming `hcl format --exclude-dir`.*)

Rejected. `--exclude-dir` belongs to `hcl fmt`. The `run` flag is `--queue-exclude-dir ./legacy`. That queues api and worker.

The filter syntax does the same: `--filter='!./legacy'`. Same result, and filters can express more than a single directory.

[pause 1s]

Now apply from `start/`, so all four exist. Read network's name. Then destroy only the apps: `--working-dir apps run --all -- destroy`. Read network's name again. Same value. Network survived. That's the safe command.

[breath]

Now the trap. Apply the apps again. Then, still from `apps`, run destroy with one extra flag: `--queue-include-external`.

(*Terminal: apps destroyed, then network destroyed.*)

The apps go, and then network goes. Check it: `--working-dir network run -- state list`. Empty.

You typed the command inside `apps/`. You were thinking about apps. But `--queue-include-external` put the shared unit back in the queue, and destroy runs dependencies last. Every other team using that network just lost it.

(*Diagram: apps/ boundary; destroy arrow crossing the boundary to network with --queue-include-external.*)

[pause 1s]

There's a related safety net, `--destroy-dependencies-check`. When you destroy a unit, it looks for other units that depend on it and prints `Detected dependent units:` with their paths.

Read that carefully. It's a warning. It doesn't refuse the destroy. In the lab, it lists api, worker, and legacy, and then destroys network anyway.

Like `--graph`, it walks up to the git root, so the lab runs it in a temporary copy. The README has the commands.

[breath]

So the rules. Run `run --all` from the narrowest directory that contains what you mean. Keep external dependencies excluded, which is the default. Exclude with `--queue-exclude-dir` or `--filter`. Never combine `--queue-include-external` with destroy unless you really mean to remove the shared unit. And destroy dependents before the thing they depend on.

[pause 1s]

`./check.sh` from `start/`. `PASS 06.5 scoping`.

That closes dependencies. Next section: stacks, where Terragrunt generates the units for you.


---

# 07.1 Units vs stacks (and why `_envcommon` goes away)

- **Estimated time:** 4 min
- **Lab path:** `labs/07-stacks/07.1-units-vs-stacks/` (`start/units/record/`, `start/stack/terragrunt.stack.hcl`, `start/_envcommon/`, `start/legacy/`)
- **Section:** 07 · Stacks, catalog & scaffold

---

This section is about stacks, the biggest change in Terragrunt 1.x. Before we write one, let's be precise about two words: unit and stack.

[pause 1s]

A **unit** is one Terraform run. It's a directory with a `terragrunt.hcl`. You run `terragrunt run plan` in it, and one plan happens.

A **stack** is a blueprint that generates units. It's a directory with a `terragrunt.stack.hcl`. You don't plan a stack directly. You run `terragrunt stack generate`, Terragrunt writes the units, and then those units run.

A directory can't be both. If Terragrunt finds `terragrunt.hcl` and `terragrunt.stack.hcl` side by side, it errors.

(*Diagram: unit = terragrunt.hcl → one run; stack = terragrunt.stack.hcl → generate → many units.*)

[breath]

Now look at what we're replacing. Open `start/_envcommon/record.hcl`.

If you've worked on a Terragrunt 0.x repo, you've seen this folder. `_envcommon` held partial configs: the shared `source` and common inputs for one component. It's not a unit. Its name is `record.hcl`, not `terragrunt.hcl`, so nothing runs it.

Then open `legacy/dev/terragrunt.hcl` and `legacy/prod/terragrunt.hcl`. Each environment kept its own unit file that included the partial and overrode a few inputs.

[pause 1s]

It worked, but it was indirect. To know what prod ran, you had to read the unit, then the partial, then the root, and merge them in your head.

Stacks retire that partial. The shared configuration becomes a real unit, `units/record`. Open it. It doesn't include `_envcommon`. Its note is `one unit`.

[breath]

Now open `start/stack/terragrunt.stack.hcl` and replace the TODOs.

`unit "record"`, with `source = "../units/record"` and `path = "record"`.

`source` is the unit directory to copy, relative to the stack file. `path` is the folder Terragrunt generates under `.terragrunt-stack`.

[pause 1s]

Plan the unit directly, from `start/units/record`. Three to add, note `one unit`.

Now try `terragrunt run plan` from `start/stack`.

(*Terminal: does not contain a terragrunt.hcl file.*)

It fails. That folder doesn't have a `terragrunt.hcl`. It's not a unit. It's a stack.

So generate it. `terragrunt stack generate`. Then plan the generated unit with `--working-dir .terragrunt-stack/record`.

Three to add, note `one unit`. Open the generated `terragrunt.hcl`. It's a copy of the record unit. No `_envcommon` anywhere.

[breath]

`.terragrunt-stack` is gitignored. You commit the stack file, not the generated output.

For comparison, plan `legacy/dev`. Three to add, note `legacy include`. Both paths work. Only one is the 1.x way.

[pause 1s]

Last, from `start/`, run `terragrunt find`. It lists `units/record`, both legacy units, and `stack`. It doesn't list `_envcommon`. `find` lists units and stacks. A partial is neither.

`./check.sh`. `PASS 07.1 units vs stacks`.

Next, a stack file with more than one block, including a stack inside a stack.


---

# 07.2 `terragrunt.stack.hcl`

- **Estimated time:** 5 min
- **Lab path:** `labs/07-stacks/07.2-stack-file/` (`start/live/terragrunt.stack.hcl`, `start/blueprints/platform/`, `start/units/record/`)
- **Section:** 07 · Stacks, catalog & scaffold

---

A stack file can hold two kinds of block. `unit`, which generates a unit. And `stack`, which generates another stack. In this lab we write one of each.

[pause 1s]

(*Screen: tree — units/record, blueprints/platform/terragrunt.stack.hcl, live/terragrunt.stack.hcl.*)

`units/record` is a finished unit. Prefix `rec`, note `record unit`.

`blueprints/platform` is a finished nested stack. It has its own `terragrunt.stack.hcl` with a unit block.

And `live/terragrunt.stack.hcl` is where we work.

[breath]

Replace the TODOs.

`unit "edge"`, `source = "../units/record"`, `path = "edge"`.

`stack "platform"`, `source = "../blueprints/platform"`, `path = "platform"`.

Paths are relative to `live/`.

[pause 1s]

From `start/live`, run `terragrunt stack generate`. Then list what it wrote.

(*Terminal: find output — three files.*)

Three files matter.

`.terragrunt-stack/edge/terragrunt.hcl`. That's a unit.

`.terragrunt-stack/platform/terragrunt.stack.hcl`. That's the nested stack file, copied.

And `.terragrunt-stack/platform/.terragrunt-stack/record/terragrunt.hcl`. That's the unit the nested stack generated.

[breath]

So generation is recursive. Terragrunt copies the nested stack file first, and then generates that stack, from its new location.

That order explains the one line in the blueprint you shouldn't change. Open `blueprints/platform/terragrunt.stack.hcl`. The unit source is:

`"${dirname(find_in_parent_folders("root.hcl"))}/units/record"`.

Why not `../../units/record`? Because by the time this file is evaluated, it's no longer in `blueprints/platform`. It's in `live/.terragrunt-stack/platform`. A `../` path would resolve from there, and the fetch would fail with `relative paths require a module with a pwd`. Anchoring on `root.hcl` works from wherever the file ends up.

(*Diagram: blueprint copied into live/.terragrunt-stack/platform; ../ path breaks, root.hcl anchor works.*)

[pause 1s]

Now run it. `terragrunt stack run -- plan`.

Two plans. `edge`, and the nested `record`. Each three to add, note `record unit`.

If you only see one plan, the `stack` block is missing, so the nested unit was never generated.

[breath]

Check the engine in a generated unit: `terragrunt run -- version`. Terraform 1.17. The generated units still include `root.hcl`, so `terraform_binary` still merges.

[pause 1s]

Why nest stacks at all? A blueprint like `platform` can bundle several units that always go together. Network, database, service. Every environment's stack file then names one `stack "platform"` instead of listing every unit. You'll see that in the capstone.

`./check.sh`. `PASS 07.2 stack file`.

Right now every generated unit is identical. Next lecture, `values` makes them different.


---

# 07.3 `values` and `autoinclude`

- **Estimated time:** 5 min
- **Lab path:** `labs/07-stacks/07.3-values/` (`start/live/terragrunt.stack.hcl`, `start/units/record/terragrunt.values.hcl`)
- **Section:** 07 · Stacks, catalog & scaffold

---

One unit, generated three times, with different values each time. And one generated unit reading another's output. That's this lecture.

[pause 1s]

Open `start/units/record/terragrunt.hcl`. Instead of hard-coded inputs, it reads `values.environment`, `values.prefix`, and `values.note`.

Where do those come from? A file called `terragrunt.values.hcl` in the unit directory. There's a default one next to the unit. Prefix `def`, note `default note`.

[breath]

In the stack file, there are two ways a generated unit gets its values file.

If the `unit` block sets no `values`, the default file is copied as it is.

If the `unit` block sets `values = { ... }`, Terragrunt writes a new `terragrunt.values.hcl` and throws the default away.

That second rule matters. It's a replacement, not a merge. If your `values` block sets `prefix` and forgets `note`, the generated file has no `note`, and the unit fails when it reads `values.note`. Set every attribute the unit reads.

[pause 1s]

Open `start/live/terragrunt.stack.hcl`. The `plain` block is already there, with no values. Leave it.

Add `unit "network"`. Same source, `path = "network"`, and `values` with environment `dev`, prefix `net`, note `network unit`.

Add `unit "service"`. Same source, `path = "service"`, values with prefix `svc` and a placeholder note.

[breath]

Now, service needs the network's `name` output. Can values do that? No. Values are fixed when the stack is generated. They can't read state.

That's what `autoinclude` is for. Inside the service block, add an `autoinclude` block. In it, a `dependency "network"` with `config_path = unit.network.path`, the mock outputs, and the allow list with `validate` and `plan`. Then `inputs = { note = dependency.network.outputs.name }`.

[pause 1s]

`unit.network.path` is important. You don't hard-code `../network`. Terragrunt computes the relative path between the two generated units and writes it for you.

Generate, and look at the files.

(*Screen: three cat outputs.*)

`plain/terragrunt.values.hcl` is the default, unchanged. `network/terragrunt.values.hcl` starts with an auto-generated header and has prefix `net`. And `service/terragrunt.autoinclude.hcl` has `config_path = "../network"`.

[breath]

Terragrunt merges the autoinclude file into the service unit on every run. Inputs merge key by key, and the autoinclude wins. So `note` comes from the dependency, even though `values.note` is also set.

Plan: `terragrunt stack run -- plan`. Three plans. Service note is `mock-network-name`. Nothing exists yet, so the mock is used, same rules as section six.

[pause 1s]

Apply: `terragrunt --non-interactive stack run -- apply`. Like `run --all`, it adds `-auto-approve`, and network goes first.

Now `terragrunt stack output`. Note: that's its own command. Not `stack run output`.

Service note equals the network name, something like `net-smart-cattle`. Service name starts with `svc`. Plain starts with `def`.

[breath]

Clean up in this order. `stack run -- destroy` first, service before network. Then `terragrunt stack clean`, which deletes `.terragrunt-stack`.

The order matters, because this lab has no remote backend. The state lives inside `.terragrunt-stack`. Clean before you destroy, and you've lost the state of real resources. With a remote backend, that risk goes away.

[pause 1s]

`./check.sh`. `PASS 07.3 values`.


---

# 07.4 `stack generate`, `stack run`, `stack output`, `stack clean`

- **Estimated time:** 5 min
- **Lab path:** `labs/07-stacks/07.4-stack-generate/` (`start/live/terragrunt.stack.hcl` — finished)
- **Section:** 07 · Stacks, catalog & scaffold

---

The stack file in this lab is already written. Network and service, with the autoinclude from last lecture. This lecture is about the commands, and the rules around the generated directory.

[pause 1s]

(*Diagram: command table — stack generate / stack run / stack output / stack clean / --no-stack-generate.*)

Five commands to know.

`stack generate` writes `.terragrunt-stack` from the stack file.

`stack run -- plan`, `apply`, or `destroy` generates first, then runs every generated unit. Apply and destroy add `-auto-approve`.

`stack output` prints the outputs of every unit.

`stack clean` deletes `.terragrunt-stack`.

And `stack run --no-stack-generate` runs what's already generated, without writing it again.

[breath]

From `start/live`, run `terragrunt stack generate`, then list the files.

Network gets `terragrunt.hcl` and `terragrunt.values.hcl`. Service also gets `terragrunt.autoinclude.hcl`.

Now `git check-ignore -v .terragrunt-stack`. It prints the rule from the repo's `.gitignore`. Generated output is never committed. The stack file is the source of truth. The generated directory is a build artifact.

[pause 1s]

Plan: `stack run -- plan`. Network, then service. Cold service note is the mock. Apply. `stack output`. Service note now equals the network name.

Check the engine with `--working-dir .terragrunt-stack/network run -- version`. Terraform 1.17.

[breath]

Now, where you run from matters. `stack run` discovers every unit under the working directory, not only the generated ones.

That's why the stack is in `live/`, and the source unit is in `units/`, outside it. If you ran `stack run` from `start/`, it would also find `units/record`, the source. That unit reads `values`, and `values` only exists after generation. You'd get `There is no variable named "values"`.

Keep source units and stack files in separate trees.

[pause 1s]

Destroy: `stack run -- destroy`. Then `stack clean`. The directory is gone.

Now try `stack run --no-stack-generate -- plan`.

(*Terminal: No units discovered.*)

`No units discovered`. Nothing was generated, and we told it not to generate. When would you want that flag? When you generated once, read the files, and want the run to use exactly those files. For example, in CI, where you generate in one step and run in the next.

[breath]

One more time on state. In this lab, state lives inside `.terragrunt-stack`. `stack clean` deletes it. So destroy before you clean. On a real project you'd add the `remote_state` block from section five to `root.hcl`, and the generated directory becomes disposable.

[pause 1s]

`./check.sh`. `PASS 07.4 stack generate`.

So far, sources have been local folders. Next, a catalog: a place where reusable units and stacks are published.


---

# 07.5 Catalog

- **Estimated time:** 4 min
- **Lab path:** `labs/07-stacks/07.5-catalog/` (`start/root.hcl`, `start/catalog/`, `start/live/terragrunt.stack.hcl`)
- **Section:** 07 · Stacks, catalog & scaffold

---

A catalog is a repository of reusable components: modules, units, and stacks. Teams publish there, and stack files reference it. In real life it's a Git repo. In this lab it's a local folder, so nothing is cloned.

[pause 1s]

(*Screen: tree of `start/catalog/`.*)

`catalog/modules/record` is a module. Plain `.tf` files.

`catalog/units/record` is a unit. It has a `terragrunt.hcl`.

`catalog/stacks/platform` is a stack. It has a `terragrunt.stack.hcl`.

That's exactly how `terragrunt catalog` classifies them. `.tf` files mean module. `terragrunt.hcl` means unit. `terragrunt.stack.hcl` means stack.

[breath]

First, tell Terragrunt where the catalog is. In `start/root.hcl`, add a `catalog` block with `urls = ["./catalog"]`. A relative path is resolved from `root.hcl`. In a real repo, that would be a Git URL.

[pause 1s]

Now list it. Two details first.

`terragrunt catalog` opens each URL as a Git repository. A plain folder needs `git init` before the command will read it. It doesn't need a commit. So the lab copies the catalog to a temp folder and runs `git init` there. If you init the folder in place, remove `catalog/.git` afterwards, so the course repo doesn't get a nested repository.

And our root file is `root.hcl`, not `terragrunt.hcl`. So pass `--root-file-name root.hcl`, or the command won't see the catalog block.

[breath]

`terragrunt catalog --format=jsonl --root-file-name root.hcl`.

(*Terminal: three JSON lines.*)

Three lines. Kinds: module, unit, stack. Titles come from each README heading: Record, Record unit, Platform.

Without `--format`, in a terminal, `catalog` opens an interactive browser. `jsonl` is for scripts. `md` prints Markdown.

[pause 1s]

Look at `component_source` in each line. It uses the double slash: `.../catalog//units/record`. Same meaning as in lecture three-one. Before the `//` is what gets fetched. After it is the folder inside.

That's the form a stack file uses. Open `start/live/terragrunt.stack.hcl` and set the unit source to `"../catalog//units/record"`, path `record`.

This is a local path, so it doesn't need `git init`. Only the `catalog` browse command does.

[breath]

From `start/live`: `stack generate`, then `stack run -- plan`. One unit, three to add, note `catalog unit`. Engine check: Terraform 1.17.

[pause 1s]

In a real setup, that source would be something like `git::https://github.com/your-org/catalog.git//units/record?ref=v1.3.0`. Pinning the ref means every environment uses a reviewed, tagged version of the unit, and upgrading is a one-line change per stack.

`./check.sh`. `PASS 07.5 catalog`.

Next, `scaffold`: stamping out a new unit or stack from a catalog entry.


---

# 07.6 `catalog` and `scaffold`

- **Estimated time:** 5 min
- **Lab path:** `labs/07-stacks/07.6-scaffold/` (`start/live/terragrunt.values.hcl`, `start/stamped/terragrunt.values.hcl`, `start/catalog/`)
- **Section:** 07 · Stacks, catalog & scaffold

---

Last lecture, a stack file referenced a catalog entry. This lecture, we copy a catalog entry into our own tree with `terragrunt scaffold`, and fill in its values.

[pause 1s]

Same local catalog: one module, one unit, one stack. List it once with `terragrunt catalog --format=jsonl --root-file-name root.hcl`, after a `git init`, and remove the `.git` afterwards. Three entries.

[breath]

`scaffold` takes a component source, and what it writes depends on the kind.

(*Diagram: table — module / unit / stack → what scaffold writes.*)

From a **module**, it writes a brand-new `terragrunt.hcl`. It points `terraform.source` at the module and lists every variable as an input.

From a **unit**, it copies the unit, and adds a `terragrunt.values.hcl` with every `values.*` reference the unit reads.

From a **stack**, same idea: a copy of the stack file, plus a values file.

[pause 1s]

Try the module first. Make an empty folder, `scratch-module`, and run:

`terragrunt --non-interactive scaffold --root-file-name root.hcl --output-folder scratch-module ./catalog/modules/record`.

`--non-interactive` writes placeholders instead of opening a form. `--root-file-name` makes the new file include our `root.hcl`. `--output-folder` picks the target.

Open the result. It includes `root.hcl`, and the required inputs say `"" # TODO: fill in value`.

[breath]

You'll see two warnings: failed to parse URL, and failed to find a last release tag. A local path has no Git tags. Scaffold warns, still writes the files, and exits zero. That's expected here.

Delete `scratch-module`. It was only to read.

[pause 1s]

Now the unit. `live/` is already a unit scaffold. To see how it was made, scaffold `./catalog//units/record`, with the double slash, into `scratch-unit`, then diff the two `terragrunt.hcl` files. They match.

Open `live/terragrunt.values.hcl`.

(*Screen: values file — Required / Optional sections.*)

Scaffold split it into two parts. Required: `environment` and `prefix`, set to `"TODO"`. Those are values the unit reads directly. Optional: `note`, already filled with `"catalog note"`. That's a value the unit reads through `try()`, and scaffold used the fallback.

[breath]

Replace the values: environment `dev`, prefix `lab`, note `scaffolded unit`.

Don't edit `live/terragrunt.hcl`. The checker diffs it against a fresh scaffold. The values file is the only file that's yours.

From `start/live`: plan, three to add. Apply. Name is `lab-` and two words. Note `scaffolded unit`. Destroy.

[pause 1s]

Now the stack. `stamped/` is a scaffold of `catalog//stacks/platform`. Fill its values: environment `dev`, prefix `stk`, note `stack note`.

From `start/stamped`: `stack generate`, then `stack run -- plan`. One unit, prefix `stk`. Generate resolved `values.prefix` into the nested unit's values file.

[breath]

One flag that doesn't apply here: `--var`. It only fills boilerplate templates. For units and stacks, values go in `terragrunt.values.hcl`.

And scaffold won't overwrite existing files. Use an empty output folder, or edit the values file you already have.

[pause 1s]

`./check.sh`. It scaffolds all three kinds into temp folders, diffs them against `live` and `stamped`, applies the unit, and plans the stack. `PASS 07.6 scaffold`.

That's stacks. Units generated from blueprints, values per instance, a catalog to share them, and scaffold to start new ones. Next section, hooks.


---

# 08.1 Before, after, and error hooks

- **Estimated time:** 5 min
- **Lab path:** `labs/08-hooks/08.1-hooks/` (`start/unit/terragrunt.hcl`, `start/modules/record/`)
- **Section:** 08 · Hooks & quality gates

---

A hook is a command Terragrunt runs around Terraform. Before it, after it, or when it fails. In this lab we add all three and watch which ones fire on a good plan and on a bad one.

[pause 1s]

Hooks live inside the `terraform` block, next to `source`. Each hook has a `commands` list, which Terraform commands it applies to, and an `execute` list, the command to run and its arguments.

(*Diagram: timeline — before_hook → Terraform → after_hook; failure branch → error_hook.*)

[breath]

There are three kinds.

`before_hook` runs before Terraform. If it exits non-zero, Terraform doesn't run at all. That's what makes it a gate.

`after_hook` runs after Terraform. With `run_on_error = false`, it's skipped when Terraform fails.

`error_hook` runs after a Terraform failure, but only if the output matches one of the regular expressions in `on_errors`. And a match doesn't turn the failure into a success. The command still fails. The hook is a reaction, not a fix.

[pause 1s]

Open `start/modules/record`. Look at the validation on `var.note`. If `note` is `"fail"`, it rejects the value with the message `deliberate plan failure`. Any other note plans normally.

[breath]

Open `start/unit/terragrunt.hcl`. Inside `terraform`, after `source`, add three blocks.

`before_hook "stamp_start"`, commands plan and apply, execute `echo`, `before hook: plan starts`.

`after_hook "stamp_done"`, same commands, echo `after hook: plan finished`, and `run_on_error = false`.

`error_hook "stamp_error"`, same commands, echo `error hook: plan failed`, and `on_errors = [".*deliberate plan failure.*"]`.

`echo` is enough. We only want to see when each one fires.

[pause 1s]

From `start/`, run `terragrunt --working-dir unit run -- plan`.

(*Terminal: before line, plan, after line.*)

The before line. Then the plan, three to add, note `hooks lab`. Then the after line. No error line.

[breath]

Now fail it on purpose: `terragrunt --working-dir unit run -- plan -var note=fail`.

`-var` overrides the input for this one command. The file still says `hooks lab`.

(*Terminal: before line, `deliberate plan failure`, error line.*)

The before line ran, because it runs before Terraform knows anything. Terraform fails with `deliberate plan failure`. The error hook matches that text and runs. The after hook doesn't, because `run_on_error` is false. And the exit code is still non-zero.

[pause 1s]

What do people use these for in practice? Before hooks: linting, formatting checks, security scans, anything that should stop a plan. After hooks: notifications, writing a plan summary somewhere. Error hooks: reacting to a specific known failure, like posting a message when a lock is held.

A hook runs inside the working copy in `.terragrunt-cache`, not next to your `terragrunt.hcl`. That detail matters in the next lecture.

[breath]

`./check.sh`. `PASS 08.1 hooks`.


---

# 08.2 tflint, fmt, and Checkov as quality gates

- **Estimated time:** 5 min
- **Lab path:** `labs/08-hooks/08.2-lint-hooks/` (`start/unit/terragrunt.hcl`, `start/.tflint.hcl`, `start/hooks/checkov`)
- **Section:** 08 · Hooks & quality gates

---

Now we use before hooks for real work. Three gates that run before every plan and apply: tflint, `terraform fmt`, and a Checkov scan. If any of them fails, Terraform never starts.

[pause 1s]

First, a change from older Terragrunt. Earlier versions bundled tflint inside the Terragrunt binary. 1.x doesn't. You install tflint yourself, like any other tool.

In this repo it's pinned in `.mise.toml` to an exact release, 0.65.0. From the repo root, `mise install`, activate, and `tflint --version`.

That release ships the Terraform ruleset built in. `start/.tflint.hcl` turns on three rules and declares no plugin block, so the hook doesn't download anything.

[breath]

Checkov is a Python application, so it isn't pinned. The lab calls `hooks/checkov`. If a real `checkov` binary is on your path, that script runs it. If not, it's a small stand-in: any `.tf` file containing `allow_all` fails, everything else passes. `allow_all` stands in for an overly open policy, so you can see a security gate fail without installing Python packages.

[pause 1s]

Open `start/unit/terragrunt.hcl`. Inside `terraform`, add three before hooks.

`before_hook "tflint"`. Commands plan and apply. Execute `tflint` with `--minimum-failure-severity=error`. Warnings print, errors block.

`before_hook "fmt"`. Execute `terraform fmt -check -diff`. A formatting diff fails the hook.

`before_hook "checkov"`. Execute the checkov script, with `-d .`, `--framework terraform`, `--quiet`, and `--compact`.

[breath]

Look at how the checkov path is written:

`"${dirname(find_in_parent_folders("root.hcl"))}/hooks/checkov"`.

Remember from last lecture: hooks run in the working copy inside `.terragrunt-cache`. `./hooks/checkov` would be looked up there, and it isn't there. So we build an absolute path from `root.hcl`. Then `-d .` scans the current directory, which is the module copy. Exactly what we want to scan.

(*Diagram: unit dir vs .terragrunt-cache working copy; hook cwd = working copy.*)

[pause 1s]

tflint is the exception. Notice we wrote just `tflint`, not a path. Terragrunt recognizes a bare `tflint` command and does extra work. It finds `.tflint.hcl` by walking up from the unit, and it passes your `inputs` to tflint as `--var`. If you give tflint an absolute path, that integration turns off. So keep it bare.

[breath]

From `start/`: `terragrunt --working-dir unit run -- plan`.

(*Terminal: tflint OK, fmt silent, checkov stub OK, plan.*)

`Tflint has run successfully. No issues found.` The fmt hook prints nothing. The checkov script says no findings. Then the plan, three to add, note `lint hooks`.

[pause 1s]

Break one gate. Add an extra space to a line in `modules/record/main.tf` and plan again. The fmt hook prints the diff and fails. Terraform never runs. Run `terraform fmt` in the module, and you're back.

The checker also runs the checkov stand-in against a throwaway file containing `allow_all`, and expects that to fail.

[breath]

One more failure to know. If `terraform_binary` didn't merge, the unit would run OpenTofu while the fmt hook calls Terraform. Keep the engine and the hook tools consistent.

`./check.sh`. `PASS 08.2 lint hooks`.

These same gates run in CI in section ten, because the hooks travel with the unit.


---

# 08.3 The `errors` block: retry and ignore

- **Estimated time:** 5 min
- **Lab path:** `labs/08-hooks/08.3-errors-block/` (`start/retry/terragrunt.hcl`, `start/ignore/terragrunt.hcl`, `start/modules/{flaky,drift}/`)
- **Section:** 08 · Hooks & quality gates

---

Some failures aren't bugs. A network call times out once. A provider reports a known, harmless error. You don't want to edit the module for that, and you don't want CI to fail for it. The `errors` block handles both: retry, and ignore.

[pause 1s]

`errors` is a top-level block. Not inside `terraform`. It has two kinds of rule. `retry` and `ignore`.

Ignore rules are checked first. If an error matches an ignore rule, it's not retried.

[breath]

The lab has two modules, and you leave both alone. `flaky` has a `local-exec` provisioner that prints `Error: transient` and fails on the first call, then succeeds. `drift` fails on every call with `Error: safe-to-ignore`.

These run during apply. Plan doesn't run provisioners.

[pause 1s]

Open `start/retry/terragrunt.hcl`. After `inputs`, add:

`errors`, and inside it `retry "transient_network"`. `retryable_errors = [".*Error: transient.*"]`. `max_attempts = 3`. `sleep_interval_sec = 1`.

One second keeps the lab short. For a real network blip, you'd wait longer.

[breath]

From `start/`, apply with `--no-color`: `terragrunt --no-color --working-dir retry run -- apply -auto-approve`.

Why `--no-color`? The pattern is matched against the text Terraform prints. Color codes in the middle of a line can break the match.

(*Terminal: `Encountered retryable error: transient_network`, `Attempt 1 of 3`, then success.*)

First attempt fails. Terragrunt logs `Encountered retryable error: transient_network`, waits one second, and runs apply again. The second attempt succeeds. `retry/attempt.count` says `2`.

[pause 1s]

That counter file lives next to the unit, using `get_terragrunt_dir()`. Not inside the cache. If the counter were inside the module copy, it could vanish when Terragrunt refetches the source, and the module would fail forever. Same lesson as the hooks: know which directory you're in.

[breath]

Now `start/ignore/terragrunt.hcl`. Add `errors`, with `ignore "known_drift"`.

`ignorable_errors` is a list. First, `".*Error: safe-to-ignore.*"`. Second, `"!.*Error: do not ignore.*"`. The leading `!` is an exclusion. An error that matches it is never ignored, even if it also matches the first pattern. This module never prints that text. It's there so you see the syntax.

`message = "Ignoring safe-to-ignore drift"`.

And `signals = { safe_to_revert = true }`.

[pause 1s]

Apply with `--no-color`. The module fails, Terragrunt prints `Ignoring safe-to-ignore drift`, and the command exits zero.

Look in the unit directory. `error-signals.json`, with `"safe_to_revert": true`. Signals are for whoever called Terragrunt. A CI job can read that file after a handled failure and decide what to do next. The message alone doesn't write the file. You need `signals`.

[breath]

A caution. Ignoring errors is a sharp tool. Keep patterns as narrow as possible. That's why this lab keeps retry and ignore on separate units, so the ignore rule can't swallow the transient error.

`./check.sh`. It cleans up the counter and the signals file when it finishes. `PASS 08.3 errors block`.

Next section, secrets and multiple accounts.


---

# 09.1 SOPS + `get_env` with a local age key

- **Estimated time:** 7 min
- **Lab path:** `labs/09-secrets-multi-account/09.1-sops/` (`start/secrets.example.yaml`, `start/unit/terragrunt.hcl`)
- **Section:** 09 · Secrets & multi-account

---

Every real unit eventually needs a secret. A database password, an API token. You can't put it in `terragrunt.hcl` in plain text, and you'd like it versioned next to the code. SOPS solves that: the file is committed encrypted, and Terragrunt decrypts it at run time.

In this lab we use SOPS with age, a small modern encryption tool, so everything stays on your machine.

[pause 1s]

Install the pins first. sops and age aren't part of Terragrunt. They're pinned in `.mise.toml` to exact releases: sops 3.13.3 and age 1.3.2. `mise install`, activate, and check each version.

[breath]

Open `start/secrets.example.yaml`. Two keys: `db_password` and `note`. The password is `lab-db-password`. That's a lab fixture, not a real credential. Leave the values as they are.

[pause 1s]

Now create a key. Outside the repository. The conventional place is `~/.config/sops/age/keys.txt`.

`age-keygen -o ~/.config/sops/age/keys.txt`.

Then `export SOPS_AGE_KEY_FILE` pointing at that file. And get the public half with `age-keygen -y`. That's the line starting with `age1`.

(*Diagram: private key (stays on your machine, outside repo) / public recipient (used to encrypt) / secrets.enc.yaml (committed).*)

[breath]

The split is the point. The public recipient can be shared. It's only used to encrypt. The private key file decrypts. It never goes into git, and never into a unit file.

[pause 1s]

Encrypt. From `start/`:

`sops --encrypt --age "$pub" --filename-override secrets.enc.yaml secrets.example.yaml > secrets.enc.yaml`.

Open `secrets.enc.yaml`. The keys are still readable. The values are `ENC[AES256_GCM,...]`. At the bottom there's a `sops:` metadata section with the recipient. This file is safe to commit. Without the matching private key, nobody can read the values. That includes another clone of this repo, because the bytes depend on your key.

[breath]

Now the unit. Open `start/unit/terragrunt.hcl` and replace the TODOs.

In `locals`:

`age_key_file = get_env("SOPS_AGE_KEY_FILE")`. One argument, no default.

`secrets = yamldecode(sops_decrypt_file(find_in_parent_folders("secrets.enc.yaml")))`.

`sops_decrypt_file` is a Terragrunt function. It calls SOPS on the file and returns the plaintext. SOPS reads `SOPS_AGE_KEY_FILE` to find the key. `yamldecode` turns it into an object.

[pause 1s]

Why `get_env` with no default? Because if the variable is missing, you want Terragrunt to stop immediately with `Required environment variable SOPS_AGE_KEY_FILE - not found`. With an empty default, the unit renders fine and then decryption fails with a much less clear error.

[breath]

The `terraform` source is the module next to `root.hcl`. In `inputs`: `note = local.secrets.note`, `db_password = local.secrets.db_password`, and `age_key_configured`, a boolean that's true when the key path is set. That boolean records that a key was configured. It doesn't pass the key into Terraform.

[pause 1s]

From `start/unit`, with the variable exported: `terragrunt render`.

(*Screen: render showing decrypted values.*)

Notice something. `render` shows `db_password = "lab-db-password"` in plain text. Render prints resolved inputs. That's useful for debugging, and it's also a reason to be careful with `render` output in CI logs when real secrets are involved.

Now plan. Three to add. In the plan, `db_password` shows as `(sensitive value)`, because the module marks that variable sensitive.

[breath]

Be clear about the limits. SOPS protects the secret at rest in git. Once Terraform has it, it can end up in state. That's why the state backend from section five is encrypted, and access to it is restricted.

[pause 1s]

Common errors. `sops metadata not found`: the encrypted file is missing or still plaintext. `failed to get the data key`: the private key doesn't match the recipient that encrypted the file.

Run `./check.sh`. It doesn't touch your key. It generates a temporary key, encrypts the example, renders, applies, destroys, and deletes that key. If you already had a `secrets.enc.yaml`, it puts yours back. `PASS 09.1 sops`.

In production, the age key is often replaced by a cloud KMS key, so access is controlled by IAM instead of a file. Same SOPS file format, same Terragrunt function.


---

# 09.2 ☁️ `iam_role` — assume a role from a unit

- **Estimated time:** 6 min
- **Lab path:** `labs/09-secrets-multi-account/09.2-assume-role/` (`start/root.hcl`, `start/unit/`) — AWS needed for plan/apply; `check.sh` is offline
- **Section:** 09 · Secrets & multi-account

---

In most AWS setups, you don't deploy with your own credentials directly. You assume a role in the target account, and that role does the work. Terragrunt has one attribute for that: `iam_role`.

This lecture needs AWS for the plan and apply. The checker doesn't. Do the offline steps first.

[pause 1s]

Open `start/root.hcl`. The `locals` are already there: `account_id`, which ships as `111111111111`, a placeholder. `aws_region`. And `role_arn`, built as `arn:aws:iam::${local.account_id}:role/terragrunt-labs`. Change the account ID in one place and the ARN follows.

[breath]

Add two things.

`iam_role = local.role_arn`.

And a `generate "provider"` block that writes `provider.tf`, with `if_exists = "overwrite_terragrunt"`, and a provider stub: `provider "aws"` with only the region.

[pause 1s]

Here's what `iam_role` does. Before Terraform runs, Terragrunt calls `sts:AssumeRole` on that ARN, gets temporary credentials, and exports them into Terraform's environment. Terraform and the AWS provider then run as the role. They don't know anything was assumed.

(*Diagram: caller credentials → Terragrunt sts:AssumeRole → session env vars → Terraform / AWS provider.*)

[breath]

That's why the provider stub has no `assume_role` block. It's a common mistake. If you add one pointing at the same role, the provider tries to assume `terragrunt-labs` while already being `terragrunt-labs`. AWS doesn't let a role assume itself, so it's denied. `iam_role` already did the assume. The provider just sets the region.

[pause 1s]

Also notice: the generated file is only the provider block. No `required_providers`. The module's `versions.tf` already has that, and Terraform 1.17 rejects a second `required_providers` block.

[breath]

From `start/unit`, render.

`iam_role = "arn:aws:iam::111111111111:role/terragrunt-labs"`, and a generated provider with region `us-east-1`. The JSON form shows the same ARN.

`./check.sh`. `PASS 09.2 assume role`, and a line saying AWS was not contacted. The checker also disables the instance metadata lookup, so a missing credential fails fast instead of hanging.

[pause 1s]

Now AWS. Use a sandbox account. You need two identities.

The caller: whoever is in your environment right now. `aws sts get-caller-identity` prints it.

The role: `terragrunt-labs`, in the account where the unit runs.

[breath]

Create the role. Its trust policy has to name the caller as principal. For an IAM user, that's the user ARN. If you're already in a role, use that role's ARN, not the `assumed-role/.../session` ARN that `get-caller-identity` prints. The trust policy must match the role, not one session of it.

The caller also needs `sts:AssumeRole` permission on the role's ARN. Trust is two-sided: the role trusts the caller, and the caller is allowed to assume the role.

The role needs no extra policy for this lab. The unit creates no AWS resources. Provider init only calls `sts:GetCallerIdentity`.

[pause 1s]

Put your real account ID in `account_id`. Plan from `start/unit`. Terragrunt assumes the role, the AWS provider initializes with that session, and Terraform plans three local resources. Apply. Output has `prefix = "assume"` and `note = "assume role"`.

[breath]

Errors you'll see. `no EC2 IMDS role found`, or a timeout to `169.254.169.254`: your shell has no credentials. `AccessDenied` on AssumeRole: the trust policy doesn't name the caller, or the caller lacks the permission. And the self-assume error: remove `assume_role` from the provider stub.

Destroy. State is local in this lab. Keep the role if you're continuing to the next lecture.

[pause 1s]

Next, the same unit in two accounts, each with its own role and its own state bucket.


---

# 09.3 ☁️ Multi-account layout

- **Estimated time:** 7 min
- **Lab path:** `labs/09-secrets-multi-account/09.3-multi-account/` (`start/{dev,prod}/account.hcl`, `start/{dev,prod}/us-east-1/record/terragrunt.hcl`) — two AWS accounts for bootstrap/apply; `check.sh` is offline
- **Section:** 09 · Secrets & multi-account

---

This lecture combines three things you've already built. The account/region layout from four-four. The S3 backend from five-two. And `iam_role` from nine-two. The result: one unit file that deploys into two accounts, each with its own role, its own state bucket, and its own state key.

You need two AWS accounts for the real run. The checker is offline.

[pause 1s]

(*Screen: tree — dev/account.hcl, dev/us-east-1/region.hcl, dev/us-east-1/record/; same for prod.*)

Two top-level folders: `dev` and `prod`. Here they're accounts, not just environments. Each has an `account.hcl`. Under each, `us-east-1` with a `region.hcl`. Under that, the `record` unit.

Open `dev/account.hcl`. `account_name = "dev"`. A placeholder `account_id`. `role_name = "terragrunt-labs"`. A `role_arn` built from those. And `state_bucket`, a placeholder bucket name.

Prod's file has a different account ID and a different bucket. Same role name.

[breath]

Why a bucket per account? Because the state of the prod account should live in the prod account. Someone with access only to dev can't read prod state, and a mistake in dev can't touch prod's backend.

[pause 1s]

Open `start/dev/us-east-1/record/terragrunt.hcl`. Three includes are already there. Root, merged, for `terraform_binary`. Account and region, exposed, `no_merge`. Same pattern as four-four, but no `env.hcl` here.

Replace the TODOs. Start with `locals`: `account_name`, `account_id`, `role_arn`, and `state_bucket` from `include.account.locals`. `aws_region` from the region include. And `unit_path = path_relative_to_include("root")`.

With more than one include, `path_relative_to_include` needs the label. Called without an argument, it fails.

[breath]

Then `iam_role = local.role_arn`. This account's role, for the whole run.

Then `remote_state`. Backend `s3`, generate `backend.tf`. Config: `bucket = local.state_bucket`, `key` from `path_relative_to_include("root")`, region, `encrypt = true`, `use_lockfile = true`.

And the provider stub, same as last lecture. Region only.

[pause 1s]

The key detail. `iam_role` applies to the whole run. That includes `backend bootstrap` and the S3 backend itself. So the bucket is created by the dev role, in the dev account, and state is read and written by that role.

That's why there's no `role_arn` inside `remote_state`, and no `assume_role` in the provider. Either one would try to assume `terragrunt-labs` a second time, from inside `terragrunt-labs`. AWS denies that.

(*Diagram: one unit file → dev path → dev role → dev bucket / prod path → prod role → prod bucket.*)

[breath]

Copy the dev file over the prod unit. Identical. Prod reads `prod/account.hcl` because `find_in_parent_folders` stops at the first `account.hcl` above the unit.

Render dev. Dev account, dev bucket, key `dev/us-east-1/record/terraform.tfstate`, dev role. Render prod. Prod account, prod bucket, key `prod/us-east-1/record/terraform.tfstate`, prod role. JSON shows `encrypt` and `use_lockfile` as real booleans.

`./check.sh`. It checks that the two unit files match, that dev and prod don't share an account ID or a bucket, and renders both. `PASS 09.3 multi-account`. AWS not contacted.

[pause 1s]

Now AWS. Two sandbox accounts, and one caller identity, in a third account or in one of these.

In each target account, create the `terragrunt-labs` role with a trust policy naming the caller. The caller needs `sts:AssumeRole` on both role ARNs. A trust policy in dev doesn't cover prod. Each account has its own.

Each role needs permission to create and configure its own state bucket, versioning, encryption, public access block, TLS policy, and to read and write objects in it, including the `.tflock`. Nothing else. The unit's resources are still local.

[breath]

Put real account IDs and bucket names you own into both `account.hcl` files. The checker still passes.

From the dev unit: `backend bootstrap`, plan, apply. Bootstrap runs as the dev role, so the bucket is created in the dev account. From the prod unit, the same. Prod role, prod bucket.

Confirm with `aws s3 ls`, using credentials for the account that owns each bucket. One state object per account, each under its own key.

[pause 1s]

Clean up. Destroy both units. Then `terragrunt backend delete` from each unit to remove its state object. Empty each versioned bucket in the console and delete it. Delete the roles when you're done.

[breath]

So what does adding a third account cost now? One folder, one `account.hcl`, one role with the right trust policy, and a copy of the same unit file. The code doesn't change. That's the payoff of the layout.

Next section, we put all of this behind a CI/CD pipeline.


---

# 10.1 Pipeline design: plan on PR, apply on merge

- **Estimated time:** 5 min
- **Lab path:** `labs/10-cicd/10.1-design/` (`start/design.md`, `start/diagram.mmd`, `start/sample/root.hcl`, `start/sample/.github/workflows/pipeline.yml`)
- **Section:** 10 · CI/CD

---

Until now, every apply in this course ran from your laptop. On a team, that's where problems start. Two people apply at once. Someone applies a branch that was never reviewed. Nobody can see what changed.

In this section we build a pipeline. A pull request runs a plan. A merge to `main` runs the apply. This first lecture is the design, before any workflow runs.

[pause 1s]

(*Diagram: Pull request → terragrunt plan → plan comment + report.json; Merge to main → terragrunt apply; OIDC feeding both; provider cache feeding apply.*)

Two jobs.

The **plan** job runs on `pull_request`. The command is `terragrunt --non-interactive run --all --report-file report.json -- plan -input=false`. It writes a report, and posts a comment on the pull request with the result.

The **apply** job runs on `push` to `main`. That's the event a merge produces. The command is `terragrunt --non-interactive run --all --provider-cache -- apply -input=false`. The provider cache makes sure each provider is downloaded once, not once per unit.

[breath]

Why apply on merge, and not from the pull request? Because a pull request is still a proposal. It can change after review. Apply waits until that proposal is the actual commit on `main`. And the plan comment sits on the pull request, right next to the code diff, so reviewers see both.

[pause 1s]

Every flag in those commands is something you already know. `--non-interactive` answers Terragrunt's prompts. `run --all` queues every unit under the working directory. The double dash keeps `plan` and `-input=false` on Terraform's side.

[breath]

Auth. The pipeline stores no AWS keys. No `AWS_ACCESS_KEY_ID` in repository secrets. Instead, GitHub mints a short-lived OIDC token for each job, and AWS exchanges it for a role session. The workflow needs one permission for that: `id-token: write`. Lecture ten-two writes the trust policies.

And the plan job and the apply job use different roles. The pull request can't assume the apply role.

[pause 1s]

State. For the labs, the sample uses the local backend from five-one, so the next lectures run without an account. A real pipeline uses S3 from five-two. Either way the key is one state file per unit, built from `path_relative_to_include()`.

[breath]

Now the lab. Fill four files.

`design.md`: replace the TODOs with the two jobs, their triggers and commands, the auth method, and the state key. It's a written record of the decisions.

`diagram.mmd`: the same path as a Mermaid flowchart. First line is `flowchart LR`, no code fence around it.

`sample/root.hcl`: the local state path, the same expression as five-one.

And `sample/.github/workflows/pipeline.yml`: the two jobs as a sketch. Plan only on `pull_request`. Apply only when `github.ref` is `refs/heads/main`. Permissions `contents: read`, `id-token: write`, `pull-requests: write`.

[pause 1s]

One setting to notice in that file: `cancel-in-progress: false`. If a second push arrives while an apply is running, you do not want GitHub to kill the apply halfway through writing state. A cancelled apply can leave a held lock and half-applied resources. The plan job is different. In ten-three it gets its own group, and cancelling an outdated plan is fine.

[breath]

Render `sample/dev` and `sample/prod`. Terraform 1.17. Keys end in `state/dev` and `state/prod`. Note `ci design`.

`./check.sh` needs Python with PyYAML. It reads the design, the diagram, and the workflow, and renders both units. No apply, no workflow run. `PASS 10.1 design`.

Next, the OIDC trust that makes keyless auth work.


---

# 10.2 ☁️ GitHub Actions + OIDC

- **Estimated time:** 6 min
- **Lab path:** `labs/10-cicd/10.2-gha-oidc/` (`start/iam/plan-trust.json`, `start/iam/apply-trust.json`, `start/.github/workflows/oidc.yml`) — AWS needed to create provider/roles; `check.sh` is offline
- **Section:** 10 · CI/CD

---

The pipeline should never hold long-lived AWS keys. Keys in repository secrets can leak, and they never expire on their own. With OIDC, GitHub proves who the job is, and AWS hands out a session that lasts only for that job.

This lecture needs AWS to create the provider and the roles. The checker only reads files.

[pause 1s]

Here's the exchange.

(*Diagram: GitHub job (id-token: write) → token from token.actions.githubusercontent.com → AWS STS AssumeRoleWithWebIdentity → checks aud + sub → role session.*)

A job with `id-token: write` asks GitHub for a token. The issuer is `https://token.actions.githubusercontent.com`. The job sends that token to AWS, calling `sts:AssumeRoleWithWebIdentity`. AWS checks the token against the role's trust policy, and returns temporary credentials.

[breath]

Two claims in the token matter.

`aud`, the audience. For AWS it's `sts.amazonaws.com`.

`sub`, the subject. It says which repository and which event. A pull request token has a subject like `repo:OWNER/REPO:pull_request`. A push to main has `repo:OWNER/REPO:ref:refs/heads/main`.

That difference is what lets us have two roles.

[pause 1s]

Open `iam/plan-trust.json` and replace the TODOs. The principal is the GitHub OIDC provider in your account. The action is `sts:AssumeRoleWithWebIdentity`. The condition is `StringEquals`: audience `sts.amazonaws.com`, subject `repo:OWNER/REPO:pull_request`.

Then `iam/apply-trust.json`. Same document, `Sid` `ApplyFromMain`, subject `repo:OWNER/REPO:ref:refs/heads/main`.

[breath]

Why `StringEquals` and not `StringLike`? Because a `StringLike` with `repo:OWNER/REPO:*` matches every event in the repo, including pull requests. Anyone who can open a pull request could then assume the apply role. The checker rejects any `*` in the subject, and any `StringLike`.

[pause 1s]

Now the workflow, `.github/workflows/oidc.yml`. Trigger `workflow_dispatch`, so you run it on demand. Permissions `id-token: write` and `contents: read`.

`id-token: write` sounds odd. You're not writing a token. The permission is the right to request one. `read` can't request it.

[breath]

Two jobs, `plan-auth` and `apply-auth`. Each checks out the code, then uses `aws-actions/configure-aws-credentials`, pinned to v6.3.0. `role-to-assume` comes from a repository variable, `vars.AWS_PLAN_ROLE_ARN` for one and `vars.AWS_APPLY_ROLE_ARN` for the other. Region `us-east-1`. A session name, `terragrunt-plan` or `terragrunt-apply`. Then `aws sts get-caller-identity`.

Notice those are **variables**, not secrets. A role ARN isn't a credential. The token is the credential, and it expires with the job.

[pause 1s]

The files ship with `123456789012` and `OWNER/REPO`, so they parse before you have a real repo. `./check.sh` needs PyYAML. `PASS 10.2 github actions oidc`, AWS not contacted.

[breath]

AWS steps, in a sandbox account.

One. Create an IAM OIDC provider for `token.actions.githubusercontent.com`, audience `sts.amazonaws.com`. The console fills in the thumbprint. Keep it out of git.

Two. Create two roles with these trust policies, after replacing the account ID and the repo. The plan role gets the read permissions a plan needs. The apply role gets what an apply needs. This lecture stops at trust. Don't attach `AdministratorAccess` to make it work.

Three. In the GitHub repo, add the two variables with the role ARNs.

Four. Commit the workflow and run it with workflow dispatch. `get-caller-identity` prints the assumed role.

[pause 1s]

If it fails with `Not authorized to perform sts:AssumeRoleWithWebIdentity`, compare the token's subject to the trust policy. That's almost always the mismatch.

Next lecture: the plan job itself.


---

# 10.3 Plan on pull request

- **Estimated time:** 5 min
- **Lab path:** `labs/10-cicd/10.3-plan-on-pr/` (`start/scripts/plan.sh`, `start/scripts/plan-comment.sh`, `start/.github/workflows/plan.yml`)
- **Section:** 10 · CI/CD

---

Now we build the plan job. On a pull request, plan every unit, write a run report, and turn that report into the comment the pull request shows. The backend is local, so the plan runs without AWS. The checker writes the comment file but doesn't post it.

[pause 1s]

The units are already written. `network`, and `service`, which depends on network with a mock for `plan`. Nothing gets applied in this lecture, so service keeps the mock.

[breath]

Here's the plan command, in `scripts/plan.sh`.

(*Screen: plan.sh.*)

`terragrunt --no-color --non-interactive run --all`, then `--report-file report.json`, `--report-format json`, then the double dash, `plan -input=false -no-color`.

`--no-color` twice: once for Terragrunt, once for Terraform. CI logs and PR comments should be plain text, not escape codes.

`--report-file` is new in this course. It writes a run report: a JSON array, one object per unit, with `Name`, `Result`, `Cmd`, `Started`, and `Ended`. On a failure it also has `Reason` and `Cause`. That's machine-readable, so you don't have to parse logs to know which unit failed.

[pause 1s]

The script changes to the lab directory first, so the report lands there, and tees stdout into `plan.log`.

Then `scripts/plan-comment.sh` reads `report.json` and `plan.log`, and writes `plan-comment.md`. Two parts: a table of unit, result, and command. And every log line that contains `Plan:`. That's the summary a reviewer needs. Not the whole log.

[breath]

Copy both scripts from `solution/scripts/`, and keep them executable. Run them.

(*Terminal: queue network, service; plan-comment.md.*)

Network and service, three to add each. Service's note is `mock-network-name`. The report shows both as `succeeded`, command `plan`. And `plan-comment.md` starts with `## Terragrunt plan`.

[pause 1s]

Now the workflow, `.github/workflows/plan.yml`, from the solution. Let's read the parts that matter.

Trigger: `pull_request` only. Permissions: `contents: read` and `pull-requests: write`, so it can comment.

Concurrency: a group per pull request, with `cancel-in-progress: true`. If you push twice quickly, the older plan is cancelled. That's safe. A plan changes nothing. Apply, next lecture, never cancels.

[breath]

Then two steps at the end. "Write the plan comment", with `if: always()`. That runs even when the plan failed, so the pull request shows the failure instead of nothing.

And "Post the plan comment", which runs `gh pr comment` with the PR number and `--body-file plan-comment.md`, using the job's own `github.token`.

In a real pipeline, you'd add the OIDC step from ten-two before the plan, assuming the plan role.

[pause 1s]

This lab's units have no hooks. But in a repo that uses the hooks from section eight, tflint, the fmt gate, and the security scan are part of the unit, so they run inside this same plan with no extra CI config.

[breath]

`./check.sh`. It prints `plan-comment.md`, then removes the generated files. `PASS 10.3 plan on pull request`, GitHub not contacted.

If the comment has no `Plan:` lines, `tee` isn't on the Terragrunt command, so stdout never reached the log.

Next, apply on merge.


---

# 10.4 Apply on merge

- **Estimated time:** 6 min
- **Lab path:** `labs/10-cicd/10.4-apply-on-merge/` (`start/scripts/apply.sh`, `start/.github/workflows/apply.yml`)
- **Section:** 10 · CI/CD

---

The last job. After the pull request merges, apply the queue, and download each provider once. The lab uses the local backend, so the checker applies for real on your machine. The OIDC role step in the workflow is the cloud part.

[pause 1s]

Here's the command for `scripts/apply.sh`.

(*Screen: apply.sh.*)

`terragrunt --no-color --non-interactive run --all`, then `--tf-path terraform`, `--provider-cache`, `--provider-cache-dir` pointing at `.provider-cache` in the lab, the report flags, and then `-- apply -input=false -no-color`.

`run --all apply` adds `-auto-approve` on its own.

[breath]

Start with the provider cache. Without it, every unit runs its own `init` and downloads its own copy of every provider. Ten units, ten copies of the AWS provider, which is hundreds of megabytes each time.

With `--provider-cache`, Terragrunt starts a small cache server on localhost for the duration of the run. Each provider is stored once, under `.provider-cache/registry.terraform.io/hashicorp/...`, and every unit gets it from there.

(*Diagram: units → local cache server → .provider-cache (one copy per provider/version).*)

[pause 1s]

Two log lines tell you it worked. `Installed hashicorp/random v3.9.1 (unauthenticated)`. That "unauthenticated" is normal. It means Terraform got the provider from the local cache server. The lock file next to each unit still pins the hashes. And at the end, `Terragrunt Cache server stopped`.

A unit without a lock file doesn't use the cache. Another reason to commit lock files.

[breath]

Now `--tf-path terraform`. Why is it needed when `terraform_binary` is already set?

Because the cache server picks its engine at startup, from `--tf-path`, `TG_TF_PATH`, or whichever of `tofu` and `terraform` it finds first. `terraform_binary` sets the unit's engine, but not the cache server's. In this course, `tofu` is on the path. So without the flag, the server is set up for OpenTofu, the units run Terraform, and Terragrunt skips the cache because they don't match. `--tf-path terraform` points both at Terraform 1.17.

[pause 1s]

Run it. `./scripts/apply.sh`.

Network, then service. Network note: `apply on merge`. Service note: the network's real name, not the mock. The mock allow list is still `validate` and `plan`, and network was applied first, so service reads real output. The report shows `apply`, `succeeded`, for both.

Destroy the queue with `run --all -- destroy`. Service, then network.

[breath]

Now the workflow, `.github/workflows/apply.yml`.

Trigger: `push` to `main`. And a job-level `if`: `github.event_name == 'push' && github.ref == 'refs/heads/main'`. Belt and braces. Even if someone edits the trigger, this job won't apply from a branch.

Permissions: `id-token: write`, `contents: read`.

Concurrency: group `apply-main`, `cancel-in-progress: false`. Two merges in a row queue up. The second waits. It never kills the first while it's writing state.

[pause 1s]

Then the role step. `configure-aws-credentials` with `vars.AWS_APPLY_ROLE_ARN`, region `us-east-1`, session `terragrunt-apply`. That role only trusts pushes to `main`, from ten-two. Then `./scripts/apply.sh`.

On your machine, with the local backend, you skip the role step and just run the script. That's what the checker does.

[breath]

`./check.sh`. It applies, checks the cache and the outputs, destroys, and cleans up. `PASS 10.4 apply on merge`.

[pause 1s]

That's the full loop. A pull request plans every unit with mocks where needed, runs the hooks, and comments the result. A merge applies in dependency order, with a cache, under a role that only `main` can assume. No stored keys.


---

# 11.1 Migrating a 0.x codebase to Terragrunt 1.x

- **Estimated time:** 8 min
- **Lab path:** `labs/11-migrate-troubleshoot/11.1-migrate-to-1x/` (`start/legacy/`, `start/live/*/terragrunt.stack.hcl`, `start/scripts/queue.sh`, `start/flags.md`)
- **Section:** 11 · Migration & troubleshooting

---

A lot of Terragrunt code out there was written for 0.x. Blog posts, old repos, maybe your company's monorepo. If you paste those commands into Terragrunt 1.2, many of them fail. This lecture takes a small 0.x tree and moves it onto 1.x.

[pause 1s]

The lab has a `legacy/` folder. That's the 0.x snapshot, and we leave it as it is. It has `commands.sh` with the old commands, an `_envcommon/record.hcl`, and dev and prod units that include it.

Run the old command.

(*Terminal: `./legacy/commands.sh`.*)

```
unknown command: "run-all"
```

`run-all` isn't a command in 1.2.

[breath]

Three changes show up here.

One. **Commands.** `terragrunt run-all plan` becomes `terragrunt run --all -- plan`. The double dash keeps `plan` and its flags on Terraform's side. You've been using this form all course.

Two. **Flags.** The `--terragrunt-` prefix is gone. `--terragrunt-non-interactive` is `--non-interactive`. `--terragrunt-tfpath` is `--tf-path`. `--terragrunt-exclude-dir` is `--queue-exclude-dir`.

Three. **Structure.** The `_envcommon` pattern, where each environment includes a shared file, becomes a `unit` block in a `terragrunt.stack.hcl`.

[pause 1s]

Environment variables changed the same way. `TERRAGRUNT_` became `TG_`. `TERRAGRUNT_NON_INTERACTIVE` is `TG_NON_INTERACTIVE`. `TERRAGRUNT_TFPATH` is `TG_TF_PATH`. Some were renamed along with the flag: `TERRAGRUNT_DEBUG` is now `TG_INPUTS_DEBUG`, and the flag is `--inputs-debug`.

A few commands too. `render-json` is `render --format json`. `hclfmt` is `hcl fmt`.

[breath]

In CI, these are the ones that cause silent problems. A renamed flag fails loudly. But an old environment variable just gets ignored. If your pipeline sets `TERRAGRUNT_NON_INTERACTIVE` and nothing else, after the upgrade Terragrunt may stop at a prompt. Grep your pipelines for `TERRAGRUNT_`.

[pause 1s]

Lab, step one. `flags.md`. Fill the rename table from the solution. It's your reference for the rest of the migration.

Step two. The stacks. `live/dev/terragrunt.stack.hcl` and `live/prod` already have a `unit` block with `path = "record"` and a `values` block. Set the source to `../../units/record`. Dev's note stays `dev stack`, prod's `prod stack`.

`units/record` is the shared unit. It's what `_envcommon` used to be. One definition, values per environment.

[breath]

Step three. `scripts/queue.sh`, the command a pipeline would run.

(*Screen: queue.sh.*)

`terragrunt --no-color --non-interactive run --all --tf-path terraform`, two `--queue-exclude-dir` flags, then `-- plan -input=false -no-color`.

Look at where `--tf-path` sits. After `run`, not before it. In 1.x, `--tf-path` is a flag of `run`. Put it in front and you get `flag --tf-path is not a valid global flag`.

[pause 1s]

The two excludes. `legacy/**` keeps the 0.x tree out of the queue. Otherwise `run --all` discovers `legacy/dev/record` and tries to plan it too. `units/**` keeps the unit template out. That template has a default `terragrunt.values.hcl`, so it would plan with `default note`. In the generated units, the stack's `values` replace that file.

`--filter '!./legacy/**'` does the same thing. We use `--queue-exclude-dir` here so the rename stays visible.

[breath]

Run it.

`run --all` generates each stack first, then plans the generated units. Two units, three to add each. Notes `dev stack` and `prod stack`. Version check on the generated unit: Terraform 1.17.

`./check.sh` plans, applies, and destroys. `PASS 11.1 migrate to 1.x`.

[pause 1s]

On a real migration, go in this order. Upgrade the binary in CI and fix commands and flags first. Then rename the environment variables. Restructure `_envcommon` into stacks last, one environment at a time, because that step moves state paths. Check every plan before you apply it. A migration should plan with no changes.

Next, troubleshooting.


---

# 11.2 Troubleshooting

- **Estimated time:** 7 min
- **Lab path:** `labs/11-migrate-troubleshoot/11.2-troubleshooting/` (`start/live/`, `start/scripts/debug.sh`)
- **Section:** 11 · Migration & troubleshooting

---

When Terragrunt does something you didn't expect, it's usually one of three things. Discovery found the wrong files. The wrong binary ran. Or the inputs aren't what you think. This lecture shows the two tools I use first: `--log-level debug` and `render`.

[pause 1s]

The lab ships with a bug. Try to generate the stack at debug level.

(*Terminal: `terragrunt --log-level debug --working-dir live stack generate`.*)

Lots of `DEBUG` lines, then:

```
contains both configuration files terragrunt.hcl and terragrunt.stack.hcl. A component must be either a unit or a stack, not both.
```

[breath]

A directory is one component. A `terragrunt.hcl` makes it a unit. A `terragrunt.stack.hcl` makes it a stack. It can't be both, because discovery wouldn't know which to run. This happens a lot when you're moving a directory from units to stacks and forget to remove the old file.

`live/terragrunt.stack.hcl` is the real stack. It points at `units/record`. `live/terragrunt.hcl` is the extra file. Delete only that one.

[pause 1s]

Now, the debug output. The default level is `info`. `--log-level debug`, or `TG_LOG_LEVEL=debug`, adds Terragrunt's own decisions: which files it parsed, which directories it found, what it ran.

Look for this line:

```
DEBUG  Running command: tofu -version
```

[breath]

That one confuses people. It looks like the unit is running OpenTofu. It's not. That's the startup probe. When `--tf-path` isn't set, Terragrunt checks which binary is on the path, and in this course `tofu` is there. The unit's engine is still `terraform_binary` from `root.hcl`.

Add `--tf-path terraform`, and the probe becomes `Running command: terraform -version`.

[pause 1s]

With that flag you'll also see:

```
DEBUG  Auto provider cache dir setup failed: auto provider cache dir requires OpenTofu, but detected terraform
```

Also not an error. The command exits zero. The automatic provider cache directory is an OpenTofu feature, so with Terraform it doesn't start. The plan is unchanged. Debug output contains lines like this, so read them as information, not as failures.

[breath]

Second tool: `render`. You saw it in three-five. `terragrunt render --format json` prints the config after locals and functions resolve. `--json` is a short form.

In the unit, `inputs.note` is set to `local.note`. The rendered JSON shows the resolved string:

```json
"note": "traced from render"
```

If you're not sure what a unit will receive, render it. Don't guess from the HCL.

[pause 1s]

Write `scripts/debug.sh`. It removes the old `.terragrunt-stack`, runs `stack generate` at debug level with `--tf-path terraform`, then renders the generated unit as JSON, also at debug level with `--tf-path`.

Again, flag placement. `--tf-path` goes after `generate`, and after `render`. If you still see `tofu -version` on a command that has the flag, the flag is on the wrong command.

And render the generated unit, `live/.terragrunt-stack/record`, not the template. The template with its default values isn't what gets applied.

[breath]

Run it, then `stack run -- plan`. Debug shows `terraform -version`. JSON shows `traced from render`. Plan: three to add.

`./check.sh`. `PASS 11.2 troubleshooting`.

[pause 1s]

A short checklist for when things go wrong. Run `--log-level debug` and read which directories were discovered. Check `run -- version` for the engine. Render the unit and read the real inputs. For queue problems, use `list --dag` from section six. Most problems show up in one of those four.


---

# 12.1 Switching the engine to OpenTofu

- **Estimated time:** 4 min
- **Lab path:** `labs/12-addon-opentofu/12.1-switch-to-tofu/` (`start/root.hcl`, `start/scripts/engines.sh`)
- **Section:** 12 · Add-on: OpenTofu

---

All course long we've pinned the engine to Terraform. In this add-on, we switch to OpenTofu 1.13. For Terragrunt it's a small change. One attribute, plus two ways to override it.

[pause 1s]

First, how Terragrunt picks the binary. In order:

(*On screen: 1. --tf-path · 2. TG_TF_PATH · 3. terraform_binary · 4. tofu on PATH, then terraform.*)

The `--tf-path` flag wins. Then the `TG_TF_PATH` environment variable. Then `terraform_binary` in the unit, including a value merged from `root.hcl`. And if none is set, `tofu` if it's on the path, then `terraform`.

That last fallback is why every lab so far set `terraform_binary = "terraform"`. Without it, Terragrunt 1.2 would choose `tofu` on any machine that has it.

[breath]

In `root.hcl`, set `terraform_binary = "tofu"`. Every unit that includes root now runs OpenTofu.

Now `scripts/engines.sh`. Three version checks.

(*Screen: engines.sh.*)

The first uses the attribute: `run -- version`. The second adds the flag: `run --tf-path terraform -- version`. The third sets the variable for one command only: `TG_TF_PATH=terraform terragrunt run -- version`. No `export`.

[pause 1s]

Run it. Attribute: OpenTofu 1.13. Flag: Terraform 1.17. Environment variable: Terraform 1.17. The override applies to one command and leaves the repo setting unchanged. Use that during a migration to compare plans from both engines.

[breath]

Two details.

The module's `required_version` is `>= 1.13.0, < 1.18.0`. Both pins fit. And notice that OpenTofu 1.13 is not Terraform 1.13. The version numbers split after the fork. A constraint like `>= 1.17.0` rejects OpenTofu 1.13 even though it's current. The checker reads the actual version line to confirm.

Second, the lock file. This lab's lock file points at `registry.opentofu.org`. OpenTofu pulls providers from its own registry. Lecture twelve-two explains why that matters.

[pause 1s]

Apply. Note: `switched to tofu`. Destroy. `./check.sh`. `PASS 12.1 switch to OpenTofu`.


---

# 12.2 OpenTofu specifics

- **Estimated time:** 4 min
- **Lab path:** `labs/12-addon-opentofu/12.2-tofu-specifics/` (`start/modules/record/engine.tofu`, `start/differences.md`)
- **Section:** 12 · Add-on: OpenTofu

---

Most of what you've learned stays the same on OpenTofu. Same units, same inputs, same backend, same `terragrunt.hcl`. This lecture covers three differences: `.tofu` files, state encryption, and the lock file.

[pause 1s]

**`.tofu` files.** OpenTofu loads both `.tf` and `.tofu`. If a module has `engine.tf` and `engine.tofu` side by side, OpenTofu loads the `.tofu` file and ignores the `.tf`. Terraform does the opposite. It loads `.tf` and ignores every `.tofu` file.

It's a whole-file replacement, matched by basename. Not a merge like `_override.tf`.

[breath]

The module already has `engine.tf` with an output `engine_file`, value `tf`. Add `engine.tofu` next to it, same output name, value `tofu`.

On OpenTofu, `engine_file` is `tofu`. On Terraform it would be `tf`. Only one file loads, so there's no duplicate output error. This is how one module can use an OpenTofu-only feature and still work on Terraform.

If you get `tf` on OpenTofu, check the basename. It has to be exactly `engine`.

[pause 1s]

**State encryption.** OpenTofu can encrypt state and plan files at rest, with an `encryption` block in the `terraform` block, or the `TF_ENCRYPTION` variable. Terraform has no equivalent. With Terraform you rely on the backend, like S3 server-side encryption from five-two.

[breath]

This lab does **not** turn it on, and the checker rejects an `encryption` block. Two reasons. A passphrase committed to a repo is a leaked key. And encrypted state can't be read without that key. If you lose it, you lose the state. So we write the behaviour down in `differences.md` and leave the module alone. Turning it on means a key management plan first.

[pause 1s]

**The lock file.** OpenTofu installs from `registry.opentofu.org`. On init, it rewrites a lock file that says `registry.terraform.io` and drops the Terraform hashes, because the provider builds aren't byte-for-byte identical. If Terraform then runs with that rewritten file, it reports an inconsistent dependency lock file.

So when you switch engines on an existing unit, commit the lock file the new engine wrote. Don't try to share one file between engines.

[breath]

Fill `differences.md` from the solution. Apply. Version: OpenTofu 1.13. `engine_file`: `tofu`. Note: `tofu specifics`. Destroy. `./check.sh`. `PASS 12.2 OpenTofu specifics`.


---

# 13.1 Capstone: dev + prod from a catalog, CI-shaped

- **Estimated time:** 6 min
- **Lab path:** `labs/13-capstone/13.1-capstone/` (`start/live/{dev,prod}/terragrunt.stack.hcl`, `start/scripts/plan.sh`, `start/scripts/apply.sh`, `start/.github/workflows/`)
- **Section:** 13 · Capstone

---

The capstone puts the course together. A catalog, two environments built from it as stacks, a dependency with mocks, local state, and the plan and apply flow from section ten. No AWS. The role step stays commented.

[pause 1s]

(*Diagram: catalog/units/record → live/dev stack (network, service) and live/prod stack (network, service); plan.sh on PR, apply.sh on main; commented OIDC role step.*)

Start with the layout. `catalog/` has a module, a unit, and an `env` stack. It's finished. `root.hcl` has the catalog block and the local backend. `live/dev` and `live/prod` each have a stack file with two units, `network` and `service`, both built from `catalog/units/record`.

[breath]

`terragrunt catalog` lists the catalog's module, unit, and stack, as long as `catalog/` is a git repository. Locally that means `git init`, no commit needed. The checker does that in a temporary copy. You don't have to, and if you did it in the lecture itself, remove `catalog/.git`.

The live stacks don't need git. They use a plain path with the double slash:

```hcl
source = "../../catalog//units/record"
```

That's the only blank in both stack files. Fill it in, and keep the `values` and the `autoinclude`.

[pause 1s]

Here are the values. Dev's network has prefix `dev` and note `dev network`. Prod's has prefix `prd` and note `prod network`. Service has prefix `svc` in both.

Service's note comes from the network. The `autoinclude` adds a dependency on the network unit, and at apply time `values.note` is replaced by the network's `name` output. Mocks are allowed only for `validate` and `plan`. A cold plan shows `mock-network-name`. Apply runs network first, so service stores the real name.

[breath]

Now the scripts. `scripts/plan.sh` loops over `dev` and `prod`, and in each one runs:

`terragrunt --no-color --non-interactive --working-dir live/$env stack run --tf-path terraform -- plan -input=false -no-color`

`scripts/apply.sh` is the same loop with `apply`. Keep both executable.

These are the commands the CI jobs would run, so you can run them on your machine and get the same result.

[pause 1s]

The workflows, from the solution. `plan.yml` triggers on `pull_request` and runs `plan.sh`. `apply.yml` triggers on push to `main`, runs `apply.sh`, with `cancel-in-progress: false`. Each has the role step from ten-two, `AWS_PLAN_ROLE_ARN` or `AWS_APPLY_ROLE_ARN`, commented out. The checker fails if a `role-to-assume` line is active. Uncommenting it is the cloud step, when you have an account.

[breath]

Run it.

(*Terminal: plan.sh, apply.sh, stack output for dev and prod.*)

Plan: four units, three to add each. Both services show `mock-network-name`.

Apply. Then `stack output --format json` for each environment. Dev's service note is `dev-` plus two words, the dev network name. Prod's is `prd-` and two words. Network notes `dev network` and `prod network`.

[pause 1s]

If a service still shows `mock-network-name` after apply, someone added `apply` to the mock allow list. Take it out.

`./check.sh` plans, applies, checks both stacks, destroys, and cleans up state. `PASS 13.1 capstone`.

[breath]

Look at what's there now. One unit definition in a catalog. Two environments that differ only in their values. Dependencies in the right order. State per unit, from the include path. And a pipeline shape where plans come from pull requests and applies come from `main`. Moving this to AWS means three steps from earlier: the S3 backend from five-two, the roles from ten-two, and uncommenting the role step.


---

# 13.2 Where to go next

- **Estimated time:** 2 min
- **Lab path:** `labs/13-capstone/13.2-next/` (read-only page; `./check.sh` only reads it)
- **Section:** 13 · Capstone

---

That's the course. You have a multi-environment stack, a catalog, and a plan and apply flow. Here's where to go from here.

[pause 1s]

**On the local backend.** Re-run the capstone's `plan.sh` any time you want a clean pass of both environments. When a queue or an input looks wrong, use `render --format json` and `--log-level debug`. And keep `terraform_binary` set on every unit until you decide to change engines.

[breath]

**When you have an AWS account.** The lectures marked with a cloud are the ones to revisit. Five-two moves state to S3 with `use_lockfile`. Nine-two assumes a role from a unit. Nine-three deploys the same unit into two accounts. And ten-two through ten-four are the OIDC role and the real workflows, the step the capstone leaves commented. Their checkers still don't call AWS until you run the cloud step yourself.

[pause 1s]

**For OpenTofu,** section twelve covers the switch and the differences.

The repo's `.mise.toml` tracks Terragrunt 1.2, Terraform 1.17, and OpenTofu 1.13. `mise install` from the repo root picks up new patch versions.

[breath]

The lab for this lecture has nothing to apply. `./check.sh` prints `PASS 13.2 next`.

Thanks for taking the course.
