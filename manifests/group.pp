# Definition of a Linux/Unix group
#
define accounts::group (
  $groupname    = $title,
  $ensure = 'present',
  $gid          = undef,
) {

  validate_re($ensure, [ '^absent$', '^present$' ],
    'The $ensure parameter must be \'absent\' or \'present\'')

  group { $groupname:
    ensure => $ensure,
    gid    => $gid,
  }
}
