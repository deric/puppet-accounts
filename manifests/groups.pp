# Multiple groups management
#
class accounts::groups (
  $groups = {},
  $manage = true,
  $users  = {},
  ) {
  validate_bool($manage)
  validate_hash($groups)
  validate_hash($users)

  if $manage {
    # create primary groups first
    $primary_groups = accounts_primary_groups($users)
    create_resources(accounts::group, $primary_groups)
    # Merge group definition with user's assignment to groups
    $members = accounts_group_members($users, $groups)
    create_resources(accounts::group, $members)
  }
}
