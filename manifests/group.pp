# Definition of a Linux/Unix group
#
define accounts::group (
  $groupname = $title,
  $ensure    = 'present',
  $members   = [],
  $gid       = undef,
) {

  validate_re($ensure, [ '^absent$', '^present$' ],
    'The $ensure parameter must be \'absent\' or \'present\'')

  # avoid problems when group declared elsewhere
  ensure_resource('group', $groupname, {
    'ensure'  => $ensure,
    'gid'     => $gid,
    'members' => sort($members),
    'attribute_membership' => 'inclusive',
  })
}
