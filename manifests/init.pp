# Puppet accounts management
#
class accounts(
  Boolean $manage_users   = true,
  Boolean $manage_groups  = true,
  Hash    $users          = {},
  Hash    $groups         = {},
  Hash    $user_defaults  = {},
  Hash    $options        = {},
  Hash    $ssh_key_groups = {},
  Boolean $use_lookup     = true,
) inherits ::accounts::params {

  # currently used mainly in tests to turn-off hiera backends
  # puppet should automatically resolve class parameters from hiera
  if $use_lookup {
    # merge behavior (3rd argument )is intentionally ommited, so that it could
    # be overidden in hiera configs
    $users_h  = lookup('accounts::users', Hash, undef, {})
    $groups_h = lookup('accounts::groups', Hash, undef, {})
    $user_defaults_h = lookup('accounts::user_defaults', Hash, undef, {})
    $options_h = lookup('accounts::config', Hash, undef, {})
  } else {
    $users_h  = {}
    $groups_h = {}
    $user_defaults_h = {}
    $options_h = {}
  }

  $_users = merge($users, $users_h)
  anchor { 'accounts::users_created': }

  class{'::accounts::config':
    options => merge($options, $options_h),
    before  => Anchor['accounts::users_created'],
  }

  if $manage_users {
    $udef = merge($user_defaults, $user_defaults_h, {
      home_permissions => $::accounts::params::home_permissions,
      require          => Anchor['accounts::users_created'],
    })
    create_resources(accounts::user, $_users, $udef)
  }

  if $manage_groups {
    $_groups = merge($groups, $groups_h)

    if has_key($user_defaults, 'groups'){
      $default_groups = $user_defaults['groups']
    } else {
      $default_groups = []
    }
    # Merge group definition with user's assignment to groups
    # No anchor is needed, all requirements are defined individially for each resource
    $members = accounts_group_members($_users, $_groups, $default_groups)
    create_resources(accounts::group, $members)
  }
}
