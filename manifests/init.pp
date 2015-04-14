# Puppet accounts management
#
class accounts(
  $manage_users  = true,
  $manage_groups = true,
  $users         = {},
  $groups        = {},
) {
  validate_bool($manage_users)
  validate_bool($manage_groups)
  validate_hash($users)
  validate_hash($groups)

  class { 'accounts::groups':
    manage => $manage_groups,
    groups => $groups,
  }

  class { 'accounts::users':
    manage  => $manage_users,
    users   => $users,
    require => Class['accounts::groups']
  }
}
