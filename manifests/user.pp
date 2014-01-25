# Linux user account
#
define accounts::user(
  $uid=undef,
  $gid=$uid,
  $groups = [],
  $comment = $title,
  $ssh_key='',
  $ssh_keys={},
  $shell='bin/bash',
  $pwhash='',
  $username=$title,
  $managehome=true,
  $home='',
  $ensure=present,
) {

  if ($managehome == true) and ($home == '') {
    User <| title == $username |> { managehome => true }
    User <| title == $username |> { home => "/home/${username}" }
  }

  # custom home location
  if $home != '' {
    User <| title == $username |> { managehome => true }
    User <| title == $username |> { home => $home }
  }

  $real_gid = $gid ? {
    /[0-9]+/ => $gid,
    default  => undef,
  }

  case $ensure {
    absent: {
      if $managehome == true {
        exec { "rm -rf /home/${username}":
          onlyif => "test -d /home/${username}",
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

      file { "/home/${username}":
        ensure  => directory,
        owner   => $username,
        group   => $username,
        recurse => true,
        mode    => '0700',
      }

      file { "/home/${username}/.ssh":
        ensure  => directory,
        owner   => $username,
        group   => $username,
        mode    => '0700',
        require => File["/home/${username}"],
      }

      file { "/home/${username}/.ssh/authorized_keys":
        ensure  => present,
        owner   => $username,
        group   => $username,
        mode    => '0600',
        require => File["/home/${username}/.ssh"],
      }

      Ssh_authorized_key {
          require =>  File["/home/${username}/.ssh/authorized_keys"]
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
