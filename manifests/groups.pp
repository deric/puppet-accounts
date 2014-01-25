# Multiple groups management
#
class accounts::groups (
  $manage,
  $groups
  ) {

  if $manage {
    create_resources(accounts::group, $groups)
  }
}
