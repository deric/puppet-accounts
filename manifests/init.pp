# Puppet accounts management
#
class accounts(
  $manage_users       = hiera('accounts::manage_users', true),
  $manage_groups      = hiera('accounts::manage_groups', true),
) {
  $users              = hiera_hash('accounts::users', {})
  $groups             = hiera_hash('accounts::groups', {})

  class { 'accounts::groups':
    manage => $manage_groups,
    groups => $groups,
  }

  class { 'accounts::users':
    manage => $manage_users,
    users  => $users,
  }
}
