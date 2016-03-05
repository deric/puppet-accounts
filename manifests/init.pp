# Puppet accounts management
#
class accounts(
  $manage_users  = hiera('accounts::manage_users', true),
  $manage_groups = hiera('accounts::manage_groups', true),
  $users         = {},
  $groups        = {},
  $user_defaults = hiera_hash('accounts::user_defaults', {})
) {
  validate_bool($manage_users)
  validate_bool($manage_groups)
  validate_hash($users)
  validate_hash($groups)
  validate_hash($user_defaults)

  $users_h  = hiera_hash('accounts::users', {})
  $groups_h = hiera_hash('accounts::groups', {})

  $merged_users = merge($users, $users_h)
  $merged_groups = merge($groups, $groups_h)

  class { 'accounts::groups':
    manage => $manage_groups,
    users  => $merged_users,
    groups => $merged_groups,
  }

  class { 'accounts::users':
    manage   => $manage_users,
    users    => $merged_users,
    defaults => $user_defaults,
    require  => Class['accounts::groups']
  }
}
