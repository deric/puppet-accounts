# ==============================
# SHOULD NOT BE CALLED DIRECTLY!
# ==============================
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
    'ensure'          => $ensure,
    'gid'             => $gid,
    'members'         => sort(unique($members)),
    'auth_membership' => true,
  })
}
