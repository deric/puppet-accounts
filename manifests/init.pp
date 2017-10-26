# Puppet accounts management
#
class accounts(
  Boolean $manage_users  = true,
  Boolean $manage_groups = true,
  Hash $users         = {},
  Hash $groups        = {},
  Hash $user_defaults = lookup('accounts::user_defaults', Hash, {'strategy' => 'deep'}, {}),
  Hash $options       = lookup('accounts::config', Hash, {'strategy' => 'deep'}, {}),
) inherits ::accounts::params {

  $users_h  = lookup('accounts::users', Hash, {'strategy' => 'deep'}, {})
  $groups_h = lookup('accounts::groups', Hash, {'strategy' => 'deep'}, {})

  $_users = merge($users, $users_h)
  anchor { 'accounts::users_created': }

  class{'::accounts::config':
    options => $options,
    before  => Anchor['accounts::users_created'],
  }

  if $manage_users {
    $udef = merge($user_defaults, {
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
    Accounts::Group<| |> -> Accounts::User<| |>
  }
}
