# Definition of a Linux/Unix group
#
define accounts::group (
  $groupname    = $title,
  $group_ensure = 'present',
  $gid          = undef,
) {

  validate_re($group_ensure, [ '^absent$', '^present$' ],
    'The $group_ensure parameter must be \'absent\' or \'present\'')

  group { $groupname:
    ensure => $group_ensure,
    gid    => $gid,
  }
}
