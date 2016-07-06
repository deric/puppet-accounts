# Multiple groups management
#
class accounts::groups (
  $groups         = {},
  $manage         = true,
  $users          = {},
  $default_groups = [],
  ) {
  validate_bool($manage)
  validate_hash($groups)
  validate_hash($users)

  if $manage {
    # Merge group definition with user's assignment to groups
    $members = accounts_group_members($users, $groups, $default_groups)
    create_resources(accounts::group, $members)
  }
}
