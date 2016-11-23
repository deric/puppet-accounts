# Puppet accounts management
#
class accounts(
  $manage_users  = hiera('accounts::manage_users', true),
  $manage_groups = hiera('accounts::manage_groups', true),
  $users         = {},
  $groups        = {},
  $user_defaults = hiera_hash('accounts::user_defaults', {}),
  $options       = hiera_hash('accounts::config', {}),
) inherits ::accounts::params {
  validate_bool($manage_users)
  validate_bool($manage_groups)
  validate_hash($users)
  validate_hash($groups)
  validate_hash($user_defaults)

  $users_h  = hiera_hash('accounts::users', {})
  $groups_h = hiera_hash('accounts::groups', {})

  $_users = merge($users, $users_h)

  class{'::accounts::config':
    options => $options,
  } ->
  anchor { 'accounts::primary_groups_created': }

  if $manage_users {
    $udef = merge($user_defaults, {
      home_permissions => $::accounts::params::home_permissions,
      require => Anchor['accounts::primary_groups_created'],
    })
    create_resources(accounts::user, $_users, $udef)
  }

  if $manage_groups {
    $_groups = merge($groups, $groups_h)
    $primary_groups = accounts_primary_groups($_users, $_groups)
    create_resources(accounts::group, $primary_groups, {
      before => Anchor['accounts::primary_groups_created'],
    })

    if has_key($user_defaults, 'groups'){
      $default_groups = $user_defaults['groups']
    } else {
      $default_groups = []
    }
    # Merge group definition with user's assignment to groups
    $members = accounts_group_members($_users, $_groups, $primary_groups, $default_groups)
    create_resources(accounts::group, $members)
  }
}
