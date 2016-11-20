# Global accounts configuration
class accounts::config(
  $first_uid = undef,
  $last_uid  = undef,
  $first_gid = undef,
  $last_gid  = undef,
  ) {

  case $::osfamily {

    'Debian': {
      if $first_uid != undef {
        shellvar { 'FIRST_UID':
          ensure => present,
          target => '/etc/adduser.conf',
          value  => $first_uid,
        }
      }

      if $last_uid != undef {
        shellvar { 'LAST_UID':
          ensure => present,
          target => '/etc/adduser.conf',
          value  => $last_uid,
        }
      }

      if $first_gid != undef {
        shellvar { 'FIRST_GID':
          ensure => present,
          target => '/etc/adduser.conf',
          value  => $first_gid,
        }
      }

      if $last_gid != undef {
        shellvar { 'LAST_GID':
          ensure => present,
          target => '/etc/adduser.conf',
          value  => $last_gid,
        }
      }
    }

    'RedHat': {
      if $first_uid != undef {
        augeas {'Set first uid':
          incl    => '/etc/login.defs',
          lens    => 'Login_Defs.lns',
          changes => [
            "set UID_MIN ${first_uid}",
          ],
        }
      }
      if $last_uid != undef {
        augeas {'Set last uid':
          incl    => '/etc/login.defs',
          lens    => 'Login_Defs.lns',
          changes => [
            "set UID_MAX ${last_uid}",
          ],
        }
      }
      if $first_gid != undef {
        augeas {'Set first gid':
          incl    => '/etc/login.defs',
          lens    => 'Login_Defs.lns',
          changes => [
            "set GID_MIN ${first_gid}",
          ],
        }
      }
      if $last_gid != undef {
        augeas {'Set last gid':
          incl    => '/etc/login.defs',
          lens    => 'Login_Defs.lns',
          changes => [
            "set GID_MAX ${last_gid}",
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