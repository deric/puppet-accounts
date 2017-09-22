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
  String $groupname = $title,
  Enum['present', 'absent'] $ensure = 'present',
  Array[String] $members = [],
  Boolean $auth_membership = true,
  # TODO: validate gid
  $gid = undef,
  String $provider = 'gpasswd',
) {

  assert_private()

  # avoid problems when group declared elsewhere
  ensure_resource('group', $groupname, {
    'ensure'          => $ensure,
    'gid'             => $gid,
    'members'         => sort(unique($members)),
    'auth_membership' => $auth_membership,
    'provider'        => $provider,
  })
}
