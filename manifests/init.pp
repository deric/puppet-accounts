# Puppet accounts management
#
class accounts(
  $manage_users  = hiera('accounts::manage_users', true),
  $manage_groups = hiera('accounts::manage_groups', true),
  $users         = {},
  $groups        = {},
) {
  validate_bool($manage_users)
  validate_bool($manage_groups)
  validate_hash($users)
  validate_hash($groups)

  $users_h  = hiera_hash('accounts::users', {})
  $groups_h = hiera_hash('accounts::groups', {})

  $merged_users = merge($users, $users_h)
  $merged_groups = merge($groups, $groups_h)

  class { 'accounts::groups':
    manage => $manage_groups,
    groups => $merged_groups,
  }

  class { 'accounts::users':
    manage => $manage_users,
    users  => $merged_users,
  }
}
