# Always include main class definition:
#
#  class{ '::accounts': }
#
# or with pure YAML declaration, site.pp:
#
#  hiera_include('classes')
#
# hiera configuration e.g. default.yaml:
#   classes:
#     - '::accounts'
#   accounts::users:
#     myuser:
#       groups: ['users']
#
# Linux user account
#
#  Parameters:
#
#  * [allowdupe] - Whether to allow duplicate UIDs. Defaults to false.
#  * [comment] - A description of the user. Generally the user's full name.
#  * [uid] - Force User ID (in Linux)
#  * [gid] - Force Group ID
#  * [manage_group] - Whether primary group with the same name as
#                    the account name should be created
#  * [primary_group] - name of user's primary group, if empty account name
#                    wikk be used.
#  * [pwhash] - password hash for the user
#  * [password] - (optional) cleartext password, will be hashed (mutually exclusive with `pwhash`!)
#  * [salt] - (optional, default random/fact based) salt for hashing the `password`
#  * [hash] - (optional, default 'SHA-512') password hash function to use (see puppetlabs/stdlib#pw_hash)
#  * [ssh_dir_owner] (default: `user`) owner of `.ssh` directory (and `authorized_keys` file in the directory).
#                     Should not be changed unless you're moving out of user's home.
#  * [ssh_dir_group] (default: `user`) owner of `.ssh` directory (and `authorized_keys` file in the directory).
#  * [manage_ssh_dir] Whether `.ssh` directory should be managed by this module (default: `true`)
#
define accounts::user(
  $uid = undef,
  $gid = undef,
  $primary_group = undef,
  $comment = undef,
  # intentionally, workaround for: https://tickets.puppetlabs.com/browse/PUP-4332
  # lint:ignore:only_variable_string  # see https://github.com/deric/puppet-accounts/pull/11 for more details
  $username = "${title}",
  # lint:endignore
  $groups = [],
  $ssh_key_source = undef,
  $ssh_keys = {},
  $purge_ssh_keys = false,
  $shell ='/bin/bash',
  $pwhash = '',
  $password = undef,
  $salt = undef,
  $hash = 'SHA-512',
  $managehome = true,
  $hushlogin = false,
  $manage_group = true, # create a group with '$primary_group' name
  $manageumask = false,
  $umask = '0022',
  $home = undef,
  $ensure = present,
  $recurse_permissions = false,
  $authorized_keys_file = undef,
  $force_removal = true,
  $populate_home = false,
  $home_directory_contents = 'puppet:///modules/accounts',
  $password_max_age = undef,
  $allowdupe = false,
  $home_permissions = '0700',
  $manage_ssh_dir = true,
  $ssh_dir_owner = undef,
  $ssh_dir_group = undef,
) {

  assert_private()

  validate_re($ensure, [ '^absent$', '^present$' ],
    'The $ensure parameter must be \'absent\' or \'present\'')
  validate_hash($ssh_keys)
  validate_bool($managehome)
  if ! is_array($purge_ssh_keys) {
    validate_bool($purge_ssh_keys)
  }

  validate_string($password)
  if $pwhash != '' and $password {
    fail("You cannot set both \$pwhash and \$password for ${username}.")
  }
  if $password {
    # explicit salt given. just ensure it's a string.
    if $salt {
      validate_re($salt, '^[A-Za-z0-9\./]{,16}$')
      $_salt = $salt
    # if no explicit salt is given, try to get it from fact or generate
    # (generation thus only on first run, when user is not present)
    } else {
      if ! $::salts[$title] {
        #$set = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890./'
        $_salt = fqdn_rand_string(16, undef, "User[${title}]")
      } else {
        $_salt = $::salts[$title]
      }
    }
    if $hash {
      validate_string($hash)
    } else {
      fail('You need to specify a hash function for hashing cleartext passwords.')
    }
  }

  if ($gid) {
    $real_gid = $gid
  } else {
    # Actuall primary group assignment is done later
    # intentionally omitting primary group in order to avoid dependency cycles
    # see https://github.com/deric/puppet-accounts/issues/39
    if $ensure == 'present' and $manage_group == true {
      # choose first non empty argument
      $real_gid = pick($primary_group, $username)
    } else {
      # see https://github.com/deric/puppet-accounts/issues/41
      $real_gid = undef
    }
  }

  $_ssh_dir_owner = pick($ssh_dir_owner, $username)
  $_ssh_dir_group = pick($ssh_dir_group, $real_gid, $username)

  if $home {
    $home_dir = $home
  } else {
    $home_dir = $username ? {
      'root'  => '/root',
      default => "/home/${username}",
    }
  }

  User<| title == $username |> {
    #gid       => $real_gid,
    comment    => $comment,
    managehome => $managehome,
    home       => $home_dir,
  }

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
        require => Anchor["accounts::user::remove_${name}"],
      }

      if $manage_group == true {
        $pg_name = $primary_group ? {
          undef   => $username,
          default => $primary_group
        }
        group { $pg_name:
          ensure  => absent,
          gid     => $real_gid,
          require => User[$username],
        }
      }
    }
    'present': {
      user { $username:
        ensure           => present,
        uid              => $uid,
        shell            => $shell,
        allowdupe        => $allowdupe,
        purge_ssh_keys   => $purge_ssh_keys,
        password_max_age => $password_max_age,
      }

      # Set password if available
      if $pwhash != '' {
        User<| title == $username |> { password => $pwhash }
      }
      # Work on cleartext password if available
      if $password {
        $pwh = pw_hash($password, $hash, $_salt)
        User<| title == $username |> { password => $pwh }
      }

      if $managehome == true {
        if $populate_home == true {
          file { $home_dir:
            ensure  => directory,
            owner   => $username,
            group   => $real_gid,
            recurse => 'remote',
            mode    => $home_permissions,
            source  => "${home_directory_contents}/${username}",
          }
        }
        else {
          file { $home_dir:
            ensure  => directory,
            owner   => $username,
            group   => $real_gid,
            recurse => $recurse_permissions,
            mode    => $home_permissions,
          }
        }

        # see https://github.com/deric/puppet-accounts/pull/44
        if $manageumask == true {
          file_line { "umask_line_profile_${username}":
            ensure  => present,
            path    => "${home_dir}/.bash_profile",
            line    => "umask ${umask}",
            match   => '^umask \+[0-9][0-9][0-9]',
            require => File[$home_dir],
          }
          -> file_line { "umask_line_bashrc_${username}":
            ensure => present,
            path   => "${home_dir}/.bashrc",
            line   => "umask ${umask}",
            match  => '^umask \+[0-9][0-9][0-9]',
          }
        }

        if $hushlogin == true {
          file { "${home_dir}/.hushlogin":
            ensure => file,
            owner  => $username,
            group  => $real_gid,
            mode   => $home_permissions,
          }
        } else {
          file { "${home_dir}/.hushlogin":
            ensure  => absent,
          }
        }

        accounts::authorized_keys { $username:
          ssh_keys             => $ssh_keys,
          ssh_key_source       => $ssh_key_source,
          authorized_keys_file => $authorized_keys_file,
          home_dir             => $home_dir,
          manage_ssh_dir       => $manage_ssh_dir,
          ssh_dir_owner        => $_ssh_dir_owner,
          ssh_dir_group        => $_ssh_dir_group,
          gid                  => $real_gid,
          require              => File[$home_dir],
        }
      }

    }
    # other ensure value is not possible (exception would be thrown earlier)
    default: {}
  }
}
