# Manages users accounts if enabled
#
class accounts::users (
  $users  = {},
  $manage = true,
) {
  validate_bool($manage)
  validate_hash($users)

  if $manage {
    create_resources(accounts::user, $users)
  }
}
