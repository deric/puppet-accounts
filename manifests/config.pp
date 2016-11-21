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

  if has_key($options, 'first_uid') {
    case $::osfamily {
      'Debian': {
        shellvar { 'FIRST_UID':
          ensure => present,
          target => '/etc/adduser.conf',
          value  => $options['first_uid'],
        }
      }
      'RedHat': {
        augeas {'Set first uid':
          incl    => '/etc/login.defs',
          lens    => 'Login_Defs.lns',
          changes => [
            "set UID_MIN ${options['first_uid']}",
          ],
        }
      }
      default: {
        fail("I don't know how to set first UID on osfamily ${::osfamily}")
      }
    }
  }

  if has_key($options, 'last_uid') {
    case $::osfamily {
      'Debian': {
        shellvar { 'LAST_UID':
          ensure => present,
          target => '/etc/adduser.conf',
          value  => $options['last_uid'],
        }
      }
      'RedHat': {
        augeas {'Set last uid':
          incl    => '/etc/login.defs',
          lens    => 'Login_Defs.lns',
          changes => [
            "set UID_MAX ${options['last_uid']}",
          ],
        }
      }
      default: {
        fail("I don't know how to set last UID on osfamily ${::osfamily}")
      }
    }
  }

  if has_key($options, 'first_gid') {
    case $::osfamily {
      'Debian': {
        shellvar { 'FIRST_GID':
          ensure => present,
          target => '/etc/adduser.conf',
          value  => $options['first_gid'],
        }
      }
      'RedHat': {
        augeas {'Set first gid':
          incl    => '/etc/login.defs',
          lens    => 'Login_Defs.lns',
          changes => [
            "set GID_MIN ${options['first_gid']}",
          ],
        }
      }
      default: {
        fail("I don't know how to set first GID on osfamily ${::osfamily}")
      }
    }
  }

  if has_key($options, 'last_gid') {
    case $::osfamily {
      'Debian': {
        shellvar { 'LAST_GID':
          ensure => present,
          target => '/etc/adduser.conf',
          value  => $options['last_gid'],
        }
      }
      'RedHat': {
        augeas {'Set last gid':
          incl    => '/etc/login.defs',
          lens    => 'Login_Defs.lns',
          changes => [
            "set GID_MAX ${options['last_gid']}",
          ],
        }
      }
      default: {
        fail("I don't know how to set last GID on osfamily ${::osfamily}")
      }
    }
  }

}