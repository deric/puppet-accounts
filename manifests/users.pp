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
