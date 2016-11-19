class accounts::params {

  case $::osfamily {
    'Debian': {
      $home_permissions = '0755'
    }
    'Redhat': {
      $home_permissions = '0700'
    }
    default: {
      $home_permissions = '0700'
    }
  }

}