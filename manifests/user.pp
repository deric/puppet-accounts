# Linux user account
#
define accounts::user(
  $uid = undef,
  $gid = $uid,
  $groups = [],
  $comment = $title,
  $ssh_key = '',
  $ssh_keys = {},
  $shell ='/bin/bash',
  $pwhash = '',
  $username = $title,
  $managehome = true,
  $home = undef,
  $home_permissions = $::osfamily ? {
                        'Debian' => '0755',
                        'RedHat' => '0700',
                        default  => '0700',
                      },
  $ensure = present,
  $recurse_permissions = false,
) {

  $home_dir = $home ? {
    undef   => "/home/${username}",
    default => $home,
  }

  User <| title == $username |> { managehome => $managehome }
  User <| title == $username |> { home => $home_dir }

  $real_gid = $gid ? {
    /[0-9]+/ => $gid,
    default  => undef,
  }

  case $ensure {
    absent: {
      if $managehome == true {
        exec { "rm -rf ${home_dir}":
          path   => [ '/bin', '/usr/bin' ],
          onlyif => "test -d ${home_dir}",
        }
      }

      user { $username:
        ensure      => absent,
        uid         => $uid,
        gid         => $real_gid,
        groups      => $groups,
      } ~>
      group { $username:
        ensure  => absent,
        gid     => $real_gid,
      }
    }

    present: {
      # Create a usergroup
      group { $username:
        ensure  => present,
        gid     => $real_gid
      }

      user { $username:
        ensure  => present,
        uid     => $uid,
        gid     => $real_gid,
        groups  => $groups,
        shell   => $shell,
        comment => $comment,
        require => [
          Group[$groups],
          Group[$username]
        ],
      }

      # Set password if available
      if $pwhash != '' {
        User <| title == $username |> { password => $pwhash }
      }

      if $managehome == true {
        file { $home_dir:
          ensure  => directory,
          owner   => $username,
          group   => $username,
          recurse => $recurse_permissions,
          mode    => $home_permissions,
        }

        file { "${home_dir}/.ssh":
          ensure  => directory,
          owner   => $username,
          group   => $username,
          mode    => '0700',
          require => File[$home_dir],
        }

        file { "${home_dir}/.ssh/authorized_keys":
          ensure  => present,
          owner   => $username,
          group   => $username,
          mode    => '0600',
          require => File["${home_dir}/.ssh"],
        }

        Ssh_authorized_key {
          require =>  File["${home_dir}/.ssh/authorized_keys"]
        }
      }

      $ssh_key_defaults = {
        ensure  => present,
        user    => $username,
        type    => 'ssh-rsa'
      }

      if $ssh_key {
        ssh_authorized_key { $ssh_key['comment']:
          ensure  => present,
          user    => $username,
          type    => $ssh_key['type'],
          key     => $ssh_key['key'],
        }
      }

      if $ssh_keys {
        create_resources('ssh_authorized_key', $ssh_keys, $ssh_key_defaults)
      }
    }
    default: {
      error("${ensure} mode not supported")
    }
  }
}
