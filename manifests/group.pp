# Definition of a Linux/Unix group
#
define accounts::group ($gid, $groupname=$title) {
  group { $groupname:
    ensure  => present,
    gid     => $gid
  }
}
