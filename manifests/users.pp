# ==============================
# SHOULD NOT BE CALLED DIRECTLY!
# ==============================
# Always include main class definition:
#
#  class{ '::accounts': }
#
# or with pure YAML declaration, site.pp:
#
#  hiera_include('classes')
#
# hiera configuration e.g. default.yaml:
#   classes:
#     - '::accounts'
#   accounts::users:
#     myuser:
#       groups: ['users']
#
# Manages users accounts if enabled
#
class accounts::users (
  $users    = {},
  $manage   = true,
  $defaults = {},
) {
  validate_bool($manage)
  validate_hash($users)
  validate_hash($defaults)

  if $manage {
    create_resources(accounts::user, $users, $defaults)
  }
}
