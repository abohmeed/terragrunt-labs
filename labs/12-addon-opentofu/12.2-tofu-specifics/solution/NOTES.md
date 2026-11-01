# 12.2 completed notes

`check.sh` is the same script as `start/check.sh`. A passing run ends with:

```text
PASS  12.2 OpenTofu specifics
```

`engine.tofu` and `engine.tf` share the basename `engine`. OpenTofu loads the `.tofu` file. The lab does not add an `encryption` block.

What the checker shows:

1. `tofu version` is OpenTofu 1.13.x.
2. `differences.md` records `.tofu` precedence, `TF_ENCRYPTION`, the 1.13 and 1.17 pins, and the `registry.opentofu.org` lock file.
3. Apply prints `engine_file = "tofu"` and note `tofu specifics`. Destroy removes the unit.
