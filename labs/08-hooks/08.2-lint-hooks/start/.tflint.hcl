# Loaded by the tflint before_hook. tflint 0.65.0 ships ruleset.terraform,
# so this file does not declare a plugin block and does not download one.

config {
  call_module_type = "local"
}

# The recommended structure rule wants a README.md beside every module.
# This course documents modules in the lecture README instead.
rule "terraform_standard_module_structure" {
  enabled = false
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}
