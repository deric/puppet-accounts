class accounts::params {

  # user provider `usermgr` requires following binaries:
  # chage, useradd, userdel, usermod

  case $::osfamily {
    'Debian': {
      $home_permissions = '0755'
      $user_provider = 'usermgr'
    }
    'Redhat': {
      $home_permissions = '0700'
      $user_provider = 'usermgr'
    }
    default: {
      $home_permissions = '0700'
      $user_provider = undef
    }
  }

}