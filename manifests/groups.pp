# Multiple groups management
#
class accounts::groups (
  $groups = {},
  $manage = true,
  ) {
  validate_bool($manage)
  validate_hash($groups)

  if $manage {
    create_resources(accounts::group, $groups)
  }
}
