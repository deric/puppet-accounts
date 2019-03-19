# Manage authorized ssh keys
#
#  * [ssh_keys] - Hash containing public ssh keys:
#      {
#        'key1' => {
#          'type' => 'ssh-rsa',
#          'key' => 'AAAA',
#        },
#        'key2' => {
#          'type' => 'ssh-rsa',
#          'key' => 'BBBB',
#        }
#      }
#  * [home_dir] user's home directory
#  * [purge_ssh_keys] keys that are not explicitly stated in
#    `ssh_keys` will be removed
#  * [manage_ssh_dir] whether `.ssh` directory should be managed by this module (default: `true`)
#  * [ssh_key_source] path to file with `authorized_keys` content (overrides `ssh_keys`)
#  * [ssh_dir_owner] .ssh dir owner and authorized_keys file as well
#  * [ssh_dir_group] .ssh dir group and authorized_keys file as well
#
define accounts::authorized_keys(
  Hash $ssh_keys = {},
  Stdlib::Absolutepath $home_dir,
  Variant[String, Integer] $gid = $title,
  Variant[String, Integer] $ssh_dir_owner = $title,
  Variant[String, Integer] $ssh_dir_group = $title,
  Optional[Stdlib::Absolutepath] $ssh_key_source = undef,
  String $username = $title,
  Optional[String] $authorized_keys_file = undef,
  Enum['present', 'absent'] $ensure = 'present',
  Boolean $manage_ssh_dir = true,
  ){

  assert_private()

  if $authorized_keys_file {
    $ssh_dir = accounts_parent_dir($authorized_keys_file)
    $auth_key_file = $authorized_keys_file
  } else {
    $ssh_dir = "${home_dir}/.ssh"
    $auth_key_file = "${ssh_dir}/authorized_keys"
  }

  anchor { "accounts::ssh_dir_created_${title}": }
  anchor { "accounts::auth_keys_created_${title}": }

  if $manage_ssh_dir {
    ensure_resource('file', $ssh_dir, {
      'ensure'  => directory,
      'owner'   => $ssh_dir_owner,
      'group'   => $ssh_dir_group,
      'mode'    => '0700',
      'require' => File[$home_dir],
      'before'  => Anchor["accounts::ssh_dir_created_${title}"],
    })
  }

  # Error: Use of reserved word: type, must be quoted if intended to be a String value
  $ssh_key_defaults = {
    ensure  => present,
    user    => $username,
    'type'  => 'ssh-rsa', # intentional quotes! (Puppet 4 compatibility)
    target  => $auth_key_file,
    before  => Anchor["accounts::auth_keys_created_${title}"],
    require => Anchor["accounts::ssh_dir_created_${title}"],
  }

  if ($ssh_dir_owner != $title or $ssh_dir_group != $gid) {
    # manage authorized keys from template
    File<| title == $auth_key_file |> {
      content => template("${module_name}/authorized_keys.erb"),
    }
  } elsif !empty($ssh_keys) {
    # ssh_authorized_key does not support changing key owner
    create_resources('ssh_authorized_key', $ssh_keys, $ssh_key_defaults)
  }

  if $ssh_key_source {
    File<| title == $auth_key_file |> {
      source  => $ssh_key_source,
    }
  }

  file { $auth_key_file:
    ensure  => $ensure,
    owner   => $ssh_dir_owner,
    group   => $ssh_dir_group,
    mode    => '0600',
    require => [Anchor["accounts::ssh_dir_created_${title}"], Anchor["accounts::auth_keys_created_${title}"]],
  }
}
