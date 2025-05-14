locals {
  # OS detection using built-in Terraform functions
  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
  current_os = local.is_windows ? "windows" : "linux"
}
