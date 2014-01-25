# Manages users accounts if enabled
#
class accounts::users (
  $manage,
  $users
) {

  if $manage {
    create_resources(accounts::user, $users)
  }
}
