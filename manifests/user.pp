# Linux user account
#
define accounts::user(
  $uid = undef,
  $gid = $uid,
  $primary_group = "${title}", # intentionally, workaround for: https://tickets.puppetlabs.com/browse/PUP-4332
  $comment = "${title}", # see https://github.com/deric/puppet-accounts/pull/11
  $username = "${title}",# for more details
  $groups = [],
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
) {

  validate_re($ensure, [ '^absent$', '^present$' ],
    'The $ensure parameter must be \'absent\' or \'present\'')
  validate_hash($ssh_keys)
  validate_bool($managehome)
  if ! is_array($purge_ssh_keys) {
    validate_bool($purge_ssh_keys)
  }

  if $home {
    $home_dir = $home
  } else {
    $home_dir = $username ? {
      root    => '/root',
      default => "/home/${username}",
    }
  }

  User <| title == $username |> { managehome => $managehome }
  User <| title == $username |> { home => $home_dir }

  case $ensure {
    absent: {
      if $managehome == true {
        exec { "rm -rf ${home_dir}":
          path   => [ '/bin', '/usr/bin' ],
          onlyif => "test -d ${home_dir}",
        }
      }

      user { $username:
        ensure => absent,
        uid    => $uid,
        gid    => $gid,
        groups => $groups,
      }
      if $manage_group == true {
        group { $primary_group:
          ensure  => absent,
          gid     => $gid,
          require => User[$username]
        }
      }
    }

    present: {
      anchor { "accounts::user::groups::${primary_group}": }

      # manage group with same name as user's name
      if $manage_group == true {
        # create user's group
        # avoid problems when group declared elsewhere
        ensure_resource('group', $primary_group, {
          'ensure' => 'present',
          'gid'    => $gid,
          'before' => Anchor["accounts::user::groups::${primary_group}"]
        })
      }

      # prior to Puppet 3.6 `purge_ssh_keys` is not supported
      if versioncmp($::puppetversion, '3.6.0') < 0 {
        user { $username:
          ensure  => present,
          uid     => $uid,
          gid     => $gid,
          groups  => $groups,
          shell   => $shell,
          comment => $comment,
          require => [
            Anchor["accounts::user::groups::${primary_group}"]
          ],
        }
        # TODO: implement purge_ssh_keys manually?
        if $purge_ssh_keys {
          notice('$purge_ssh_keys not supported prior to puppet 3.6.0')
        }
      } else {
        user { $username:
          ensure         => present,
          uid            => $uid,
          gid            => $gid,
          groups         => $groups,
          shell          => $shell,
          comment        => $comment,
          purge_ssh_keys => $purge_ssh_keys,
          require        => [
            Anchor["accounts::user::groups::${primary_group}"]
          ],
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
          group   => $primary_group,
          recurse => $recurse_permissions,
          mode    => $home_permissions,
        }

        file { "${home_dir}/.ssh":
          ensure  => directory,
          owner   => $username,
          group   => $primary_group,
          mode    => '0700',
          require => File[$home_dir],
        }

        file { "${home_dir}/.ssh/authorized_keys":
          ensure  => present,
          owner   => $username,
          group   => $primary_group,
          mode    => '0600',
          require => File["${home_dir}/.ssh"],
        }

        Ssh_authorized_key {
          require =>  File["${home_dir}/.ssh/authorized_keys"]
        }
      }

      # Error: Use of reserved word: type, must be quoted if intended to be a String value at /etc/puppetlabs/agent/code/environments/production/modules/accounts/manifests/user.pp:121:9 on node
      $ssh_key_defaults = {
        ensure => present,
        user   => $username,
        'type' => 'ssh-rsa'
      }

      if !empty($ssh_key) {
        # for unique resource naming
        $suffix = empty($ssh_key['comment']) ? {
          undef   => $ssh_key['type'],
          default => $ssh_key['comment']
        }
        ssh_authorized_key { "${username}_${suffix}":
          ensure => present,
          user   => $username,
          type   => $ssh_key['type'],
          key    => $ssh_key['key'],
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
