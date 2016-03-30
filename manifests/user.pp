# Linux user account
#
define accounts::user(
  $uid = undef,
  $gid = undef,
  $primary_group = "${title}", # lint:ignore:only_variable_string # intentionally, workaround for: https://tickets.puppetlabs.com/browse/PUP-4332
  $comment = "${title}",  # lint:ignore:only_variable_string  # see https://github.com/deric/puppet-accounts/pull/11 for more details
  $username = "${title}", # lint:ignore:only_variable_string
  $groups = [],
  $ssh_key_source = undef,
  $ssh_key = '',
  $ssh_keys = {},
  $purge_ssh_keys = false,
  $shell ='/bin/bash',
  $pwhash = '',
  $managehome = true,
  $manage_group = true, # create a group with '$primary_group' name
  $home = undef,
  $home_permissions = $::osfamily ? {
                        'Debian' => '0755',
                        'RedHat' => '0700',
                        default  => '0700',
                      },
  $ensure = present,
  $recurse_permissions = false,
  $authorized_keys_file = undef,
  $force_removal = true,
  $populate_home = false,
  $home_directory_contents = 'puppet:///modules/accounts',
  $password_max_age = undef,
) {

  validate_re($ensure, [ '^absent$', '^present$' ],
    'The $ensure parameter must be \'absent\' or \'present\'')
  validate_hash($ssh_keys)
  validate_bool($managehome)
  if ! is_array($purge_ssh_keys) {
    validate_bool($purge_ssh_keys)
  }

  if ($gid) {
    $real_gid = $gid
  } else {
    if $ensure == 'present' {
      if $manage_group {
        $real_gid = $primary_group
      } else {
        $real_gid = $uid
      }
    } else {
      $real_gid = undef
    }
  }

  if $home {
    $home_dir = $home
  } else {
    $home_dir = $username ? {
      'root'  => '/root',
      default => "/home/${username}",
    }
  }

  if $authorized_keys_file {
    $authorized_keys = $authorized_keys_file
  } else {
    $authorized_keys = "${home_dir}/.ssh/authorized_keys"
  }

  User <| title == $username |> { managehome => $managehome }
  User <| title == $username |> { home => $home_dir }

  case $ensure {
    'absent': {
      if $managehome == true {
        exec { "rm -rf ${home_dir}":
          path   => [ '/bin', '/usr/bin' ],
          onlyif => "test -d ${home_dir}",
        }
      }

      anchor { "accounts::user::remove_${name}": }

      # when user is logged in we couldn't remove the account, issue #23
      if $force_removal {
        exec { "killproc ${name}":
          command     => "pkill -TERM -u ${name}; sleep 1; skill -KILL -u ${name}",
          path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
          onlyif      => "id ${name}",
          refreshonly => true,
          before      => Anchor["accounts::user::remove_${name}"],
        }
      }

      user { $username:
        ensure  => absent,
        uid     => $uid,
        gid     => $real_gid,
        require => Anchor["accounts::user::remove_${name}"],
      }

      if $manage_group == true {
        group { $primary_group:
          ensure  => absent,
          gid     => $real_gid,
          require => User[$username],
        }
      }
    }
    'present': {
      # prior to Puppet 3.6 `purge_ssh_keys` is not supported
      if versioncmp($::puppetversion, '3.6.0') < 0 {
        user { $username:
          ensure  => present,
          uid     => $uid,
          gid     => $real_gid,
          #groups  => $groups, # managed via groups class
          shell   => $shell,
          comment => $comment,
        }
        # TODO: implement purge_ssh_keys manually?
        if $purge_ssh_keys {
          notice('$purge_ssh_keys not supported prior to puppet 3.6.0')
        }
      } else {
        user { $username:
          ensure           => present,
          uid              => $uid,
          gid              => $real_gid,
          #groups           => $groups, # managed via groups class
          shell            => $shell,
          comment          => $comment,
          purge_ssh_keys   => $purge_ssh_keys,
          password_max_age => $password_max_age,
        }

      }

      # Set password if available
      if $pwhash != '' {
        User <| title == $username |> { password => $pwhash }
      }

      if $managehome == true {
        file { $home_dir:
          ensure  => directory,
          owner   => $username,
          group   => $real_gid,
          recurse => $recurse_permissions,
          mode    => $home_permissions,
        }

        file { "${home_dir}/.ssh":
          ensure  => directory,
          owner   => $username,
          group   => $real_gid,
          mode    => '0700',
          require => File[$home_dir],
        } ->

        file { $authorized_keys:
          ensure => present,
          owner  => $username,
          group  => $real_gid,
          source => $ssh_key_source,
          mode   => '0600',
        }

        Ssh_authorized_key {
          require =>  File[$authorized_keys],
        }
      }

      # Error: Use of reserved word: type, must be quoted if intended to be a String value at /etc/puppetlabs/agent/code/environments/production/modules/accounts/manifests/user.pp:121:9 on node
      $ssh_key_defaults = {
        ensure  => present,
        user    => $username,
        'type'  => 'ssh-rsa',
      }

      if !empty($ssh_key) {
        ssh_authorized_key { "${username}_${ssh_key['type']}":
          ensure  => present,
          user    => $username,
          type    => $ssh_key['type'],
          key     => $ssh_key['key'],
          options => $ssh_key['options'],
          require =>  File[$authorized_keys],
        }
      }

      if !empty($ssh_keys) {
        create_resources('ssh_authorized_key', $ssh_keys, $ssh_key_defaults)
      }
    }
    # other ensure value is not possible (exception will be thrown earlier)
    default: {}
  }
}
