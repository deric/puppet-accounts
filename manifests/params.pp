class accounts::params {

  # user provider `usermgr` requires following binaries:
  # chage, useradd, userdel, usermod

  case $::osfamily {
    'Debian': {
      $home_permissions = '0755'
      $user_provider = 'usermgr'
      $group_provider = 'usermod'
    }
    'Redhat': {
      $home_permissions = '0700'
      $user_provider = 'usermgr'
      $group_provider = 'usermod'
    }
    default: {
      $home_permissions = '0700'
      $user_provider = undef
      $group_provider = undef
    }
  }

}