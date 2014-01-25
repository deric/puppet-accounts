# Manages users accounts if enabled
#
class accounts::users (
  $manage,
  $users
) {
  validate_bool($manage)
  validate_hash($users)

  if $manage {
    create_resources(accounts::user, $users)
  }
}
