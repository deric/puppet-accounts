class accounts(
    $ensure             = hiera('accounts::ensure'),
    $manage_known_hosts = hiera('accounts::manage_known_hosts'),
    $manage_users       = hiera('accounts::manage_users'),
    $manage_groups      = hiera('accounts::manage_groups'),
    $users              = hiera_hash('accounts::users'),
    $groups             = hiera_hash('accounts::groups'),
    ) {

    class { 'accounts::groups':
        manage => $manage_groups,
        groups => $groups,
    }

    class { 'accounts::users':
        manage => $manage_users,
        users  => $users,
    }
}
