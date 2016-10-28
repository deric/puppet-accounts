# Manage authorized ssh keys
#
define accounts::authorized_keys(
  $ssh_keys,
  $home_dir,
  $purge_ssh_keys,
  $real_gid = $title,
  $ssh_key_source = undef,
  $username = $title,
  $authorized_keys_file = undef,
  $ssh_key = undef,
  $ensure = 'present'
  ){

  if $authorized_keys_file {
    $auth_keys = $authorized_keys_file
  } else {
    $auth_keys = "${home_dir}/.ssh/authorized_keys"
  }

  file { "${home_dir}/.ssh":
    ensure  => directory,
    owner   => $username,
    group   => $real_gid,
    mode    => '0700',
    require => File[$home_dir],
  }

  # Error: Use of reserved word: type, must be quoted if intended to be a String value
  $ssh_key_defaults = {
    ensure  => present,
    user    => $username,
    'type'  => 'ssh-rsa',
  }

  anchor { "accounts::auth_keys_created_${title}": }

  # backwards compatibility only - will be removed in 2.0
  # see https://github.com/deric/puppet-accounts/issues/40
  if !empty($ssh_key) {
    ssh_authorized_key { "${username}_${ssh_key['type']}":
      ensure  => present,
      user    => $username,
      type    => $ssh_key['type'],
      key     => $ssh_key['key'],
      options => $ssh_key['options'],
      require =>  File[$auth_keys],
      before  => Anchor["accounts::auth_keys_created_${title}"],
    }
  }

  if !empty($ssh_keys) {
    create_resources('ssh_authorized_key', $ssh_keys, $ssh_key_defaults)
  }

  # prior to Puppet 3.6 `purge_ssh_keys` is not supported
  if versioncmp($::puppetversion, '3.6.0') < 0 and $purge_ssh_keys {
    if !empty($ssh_keys) or !empty($ssh_key) {
      file { $auth_keys:
        ensure  => $ensure,
        owner   => $username,
        group   => $real_gid,
        mode    => '0600',
        content => template("${module_name}/authorized_keys.erb"),
        require => [File["${home_dir}/.ssh"], Anchor["accounts::auth_keys_created_${title}"]],
      }
      Ssh_authorized_key<| |> -> File[$auth_keys]
    }
  } else {
    file { $auth_keys:
      ensure  => $ensure,
      owner   => $username,
      group   => $real_gid,
      source  => $ssh_key_source,
      mode    => '0600',
      require => File["${home_dir}/.ssh"],
    }
  }
}