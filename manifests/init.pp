# Puppet accounts management
#
class accounts(
  $manage_users  = true,
  $manage_groups = true,
  $users         = {},
  $groups        = {},
  $user_defaults = {},
) {
  validate_bool($manage_users)
  validate_bool($manage_groups)
  validate_hash($users)
  validate_hash($groups)
  validate_hash($user_defaults)

  class { 'accounts::groups':
    manage => $manage_groups,
    groups => $groups,
  }

  class { 'accounts::users':
    manage   => $manage_users,
    users    => $users,
    defaults => $user_defaults,
    require  => Class['accounts::groups']
  }
}
