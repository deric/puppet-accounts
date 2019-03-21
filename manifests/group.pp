# == Define accounts::group
#
# A definition of a Linux/Unix group (and optionally its members).
#
# Always include main class definition:
#
#  class{ '::accounts': }
#
# or with pure YAML declaration, site.pp:
#
#  lookup('classes', {merge => unique}).include
#
# hiera configuration e.g. default.yaml:
#   classes:
#     - '::accounts'
#   accounts::users:
#     myuser:
#       groups: ['users']
#
define accounts::group (
  String                             $groupname = $title,
  Enum['present', 'absent']          $ensure = 'present',
  Array[String]                      $members = [],
  Boolean                            $auth_membership = true,
  Optional[Variant[String, Integer]] $gid = undef,
  String                             $provider = 'gpasswd',
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
