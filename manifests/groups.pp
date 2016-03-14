# Multiple groups management
#
class accounts::groups (
  $groups = {},
  $manage = true,
  $users  = {},
  ) {
  validate_bool($manage)
  validate_hash($groups)

  if $manage {
    # Merge group definition with user's assignment to groups
    $members = accounts_group_members($users, $groups)
    create_resources(accounts::group, $members)
  }
}
