# Private class. Do not include directly this class.
#
# Global accounts configuration
class accounts::config(
  $options = {}
) {

  if has_key($options, 'umask') {
    $umask = $options['umask']
    augeas {'Set umask':
      incl    => '/etc/login.defs',
      lens    => 'Login_Defs.lns',
      changes => [
        "set UMASK ${umask}",
      ],
    }
  }

  case $::osfamily {

    'Debian': {
      if has_key($options, 'first_uid') {
        shellvar { 'FIRST_UID':
          ensure => present,
          target => '/etc/adduser.conf',
          value  => $options['first_uid'],
        }
      }

      if has_key($options, 'last_uid') {
        shellvar { 'LAST_UID':
          ensure => present,
          target => '/etc/adduser.conf',
          value  => $options['last_uid'],
        }
      }

      if has_key($options, 'first_gid') {
        shellvar { 'FIRST_GID':
          ensure => present,
          target => '/etc/adduser.conf',
          value  => $options['first_gid'],
        }
      }

      if has_key($options, 'last_gid') {
        shellvar { 'LAST_GID':
          ensure => present,
          target => '/etc/adduser.conf',
          value  => $options['last_gid'],
        }
      }
    }

    'RedHat': {
      if has_key($options, 'first_uid') {
        augeas {'Set first uid':
          incl    => '/etc/login.defs',
          lens    => 'Login_Defs.lns',
          changes => [
            "set UID_MIN ${options['first_uid']}",
          ],
        }
      }
      if has_key($options, 'last_uid') {
        augeas {'Set last uid':
          incl    => '/etc/login.defs',
          lens    => 'Login_Defs.lns',
          changes => [
            "set UID_MAX ${options['last_uid']}",
          ],
        }
      }
      if has_key($options, 'first_gid') {
        augeas {'Set first gid':
          incl    => '/etc/login.defs',
          lens    => 'Login_Defs.lns',
          changes => [
            "set GID_MIN ${options['first_gid']}",
          ],
        }
      }
      if has_key($options, 'last_gid') {
        augeas {'Set last gid':
          incl    => '/etc/login.defs',
          lens    => 'Login_Defs.lns',
          changes => [
            "set GID_MAX ${options['last_gid']}",
          ],
        }
      }
    }
    default: {
      if $first_uid != undef {
        fail("I don't know how to set first uids on osfamily ${::osfamily}")
      }
      if $first_uid != undef {
        fail("I don't know how to set first gids on osfamily ${::osfamily}")
      }
    }

  }

}