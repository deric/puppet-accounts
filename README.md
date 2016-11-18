# Puppet Accounts Management

[![Puppet
Forge](http://img.shields.io/puppetforge/v/deric/accounts.svg)](https://forge.puppetlabs.com/deric/accounts) [![Build Status](https://travis-ci.org/deric/puppet-accounts.png)](https://travis-ci.org/deric/puppet-accounts) [![Puppet Forge
Downloads](http://img.shields.io/puppetforge/dt/deric/accounts.svg)](https://forge.puppetlabs.com/deric/accounts/scores)

This is puppet module for managing user accounts, groups and setting ssh keys.

Origin: https://github.com/deric/puppet-accounts

Basic usage:

```puppet
class {'::accounts':}
```

or with pure YAML declaration make sure to use the `hiera_include` function e.g. in `site.pp` (see [Hiera docs for details](https://docs.puppet.com/hiera/3.2/complete_example.html#using-hierainclude)):
```puppet
hiera_include('classes')
```
and all other definition can be in YAML hierarchy:
```yaml
classes:
  - '::accounts'
accounts::users:
  myuser:
    groups: ['users']
```

Hiera allows flexible account management, if you want to have a group defined on all nodes, just put in global hiera config, e.g. `common.yml`:

```yaml
accounts::user_defaults:
  shell: '/bin/bash'
  # will delete all authorized keys that are not in Puppet
  purge_ssh_keys: true
accounts::groups:
  www-data:
    gid: 33
    # not necessarily complete list of memebers, you can assign users to the same group on
    # user's level using `groups: ['www-data']`
    members: ['john']
```

and user accounts:

```yaml
accounts::users:
  john:
    comment: "John Doe"
    groups: ["sudo", "users"]
    shell: "/bin/bash"
    pwhash: "$6$GDH43O5m$FaJsdjUta1wXcITgKekNGUIfrqxYogW"
    ssh_keys:
      'john@doe': # an unique indentifier of a key
        type: "ssh-rsa"
        key: "a valid public ssh key string"
  alice:
    comment: "Alice"
```

For more examples see [configuration used for tests](https://github.com/deric/puppet-accounts/blob/master/spec/fixtures/hiera/default.yaml).

### Custom home

When no `home` is specified directory will be created in `/home/{username}`.

```yaml
  alice:
    comment: 'Alice'
    home: '/var/alice'
```

### Group management

By default each user has a group with the same name. You can change this with `manage_group` parameter:

```yaml
accounts::users:
 john:
   manage_group: false
   groups:
     - 'users'
     - 'www-data'
```
Optionally you can assign user to other groups by supplying a `groups` array.

### Primary group

Account's primary group can be configured using `primary_group` parameter:
```yaml
accounts::users:
 john:
   # will create primary group `doe` instead of default `john` group
   primary_group: 'doe'
   manage_group: true
   groups:
     - 'sudo'
```
it can be defined numerically or as a group name. Setting [directly `gid`](https://docs.puppet.com/puppet/latest/reference/types/user.html#user-attribute-gid) parametr would have the same effect. Parameter `manage_group` is not considered when you set `gid`.

### Account removal

Removing account could be done by setting `ensure` parameter to `absent`:

```yaml
accounts::users:
 john:
   ensure: 'absent'
   managehome: true
```

If `managehome` is set to `true` (default), also home directory will be removed!

### Root account

`root` home is set to `/root` unless defined otherwise (using `home` parameter). You can supply multiple keys for one account.
```yaml
accounts::users:
  root:
    ssh_keys:
      'mykey1':
        type: 'ssh-rsa'
        key: 'AAAA....'
      'otherkey':
        type: 'ssh-dsa'
        key: 'AAAAB...'
```

### Additional SSH key options

SSH allows providing many options regarding authorized keys, see [SSH documentation](http://man.openbsd.org/OpenBSD-current/man8/sshd.8#AUTHORIZED_KEYS_FILE_FORMAT) for complete specification.

Options should be passed as an array:
```yaml
accounts::users:
  foo:
    ssh_keys:
      'mykey1':
        type: 'ssh-rsa'
        key: 'AAAA....'
        options:
          - 'permitopen="10.4.3.29:3306"'
          - 'permitopen="10.4.3.30:5432"'
          - 'no-port-forwarding'
          - 'no-X11-forwarding'
          - 'no-agent-forwarding'
          - 'from="serverA,serverB"'
          - 'command="/path/to/script.sh arg1 $SSH_ORIGINAL_COMMAND"'
```

### Password Management

You can either provide an already hashed password or you can let the module take
care of hashing.

Providing hashed passwords from Hiera is secure by default. Please use something
like hiera-eyaml or hiera-gpg for cleartext passwords within Puppet.

Example with pre-hashed password:
```yaml
accounts::users:
  john:
    pwhash: "$6$GDH43O5m$FaJsdjUta1wXcITgKekNGUIfrqxYogW"
```
Example with cleartext password, using hiera-eyaml:
```yaml
accounts::users:
  john:
    password: >
      ENC[PKCS7,MIIBeQYJKoZIhvcNAQcDoIIBajCCAWYCAQAxggEhMIIBHQIBADAFMAACAQAw
      ...
      1yv7gBCuc3T2xV9gPYe+DrALDYB+]
   ensure: present
```
The password hashing salt is generated with `fqdn_rand_string` from stdlib the first
time the user is created. After that, the salt is read by a custom fact and reused,
even on password changes (which is ok, it's just a salt...). You may specify an
explicit salt if needed (see variable doc below).

## User

* `authorized_keys_file` - allows providing location of custom `authorized_keys`
* `purge_ssh_keys` - delete all keys except those explicitly provided (default: `false`)
* `ssh_key_source` - provide file with authorized keys
* `pwhash` - set password hash
* `password` - (optional) set cleartext password (mutually exclusive with `pwhash`!)
* `salt` - (optional, default random/fact based) salt for hashing the `password`, this may only be up to 16 characters
* `hash` - (optional, default 'SHA-512') password hash function to use (valid strings: see [puppetlabs/stdlib#pw_hash](https://github.com/puppetlabs/puppetlabs-stdlib#pw_hash))
* `force_removal` - will kill user's process before removing account with `ensure => absent` (default: `true`)

Example:

```yaml
accounts::users:
 john:
   authorized_keys_file: '/home/.ssh/auth_file'
   managehome: true
   purge_ssh_keys: false
   pwhash: ''
```

### `umask`

Default permissions for creating new files are managed via `~/.bash_profile` and `~/.bashrc`.

```yaml
accounts::users:
 john:
   manageumask: true
   umask: '022'
```

By default `umask` is not managed. Note that you can configure global `umask` for all users via `accounts::config` (see bellow).

## Global settings

You can provide global defaults for all users:

```yaml
accounts::user_defaults:
  shell: '/bin/dash'
  groups: ['users']
```
 * `groups` common group(s) for all users

Note that configuration from Hiera gets merged to with Puppet code.

### System-wide configuration

Global settings affects also user accounts created outside of this module.

```yaml
accounts::config:
  first_uid: 1000
  last_uid: 99999
  first_gid: 1000
  last_gid: 99999
  umask: '077'
```
 * `first_uid` - Sets the lowest UID for non system users
 * `last_uid` - Sets the highest UID for non system users
 * `first_gid` - Sets the lowest GID for non system groups
 * `last_gid` - Sets the highest GID for non system groups
 * `umask` - Default global `umask` (can be overriden in user's `~/.profile`)


### Populate home folder

Allows fetching user's directory content from some storage:

```yaml
accounts::users:
 john:
   populate_home: true
   home_directory_contents: 'puppet:///modules/accounts'
```
which default to `puppet:///modules/accounts/{username}`.

## Testing

Which accounts will be installed on specific machine can be checked from command line:

```bash
$ hiera -y my_node.yml accounts::users --hash
```

where `my_node.yml` is a file which you get from facter running at some node:

```bash
$ facter -y > my_node.yml
```

### Without Hiera

Using Hiera is optional, you can configure accounts directly from Puppet code:


```puppet
class {'accounts':
  users => { 'john' => { 'comment' => 'John Doe' }}
}
```

When defining adding a user to multiple groups, we have to ensure, that all the groups exists first:

```puppet
  class {'accounts':
    groups => {
      'users' => {
        'gid' => 100,
      },
      'puppet' => {
        'gid' => 111,
      }
    },
    users => { 'john' => {
      'shell'   => '/bin/bash',
      'groups'  => ['users', 'puppet'],
      'ssh_key' => {'type' => 'ssh-rsa', 'key' => 'public_ssh_key_xxx' }
    }}
  }
```

## Puppet compatibility

This modules heavily relies on Hiera functionality, thus it's recommended to use at least Puppet 3. Puppet 2.7 might work with `hiera-puppet` gem, but we don't test this automatically, see [docs](https://docs.puppetlabs.com/hiera/1/installing.html#step-2-install-the-puppet-functions) for more details.

  * `3.x` work out-of-the-box
  * `4.x` other backends than Hiera might work

## Installation

For more complex hierarchies (defined in multiple files) `deep_merge` gem is needed, see [Hiera docs](https://docs.puppetlabs.com/hiera/3.0/lookup_types.html#deep-merging-in-hiera).

```
gem install deep_merge
```

and update `merge_behavior` in your `hiera.yaml`, e.g.:
```yaml
---
:backends:
  - yaml
:hierarchy:
  - "%{hostname}"
  - common
# options are native, deep, deeper
:merge_behavior: deeper
```

With [Puppet librarian](https://github.com/rodjek/librarian-puppet) add one line to `Puppetfile`:

stable release:

```ruby
mod 'deric-accounts'
```

development version (master branch from github):
```ruby
mod 'deric-accounts', :git => 'https://github.com/deric/puppet-accounts.git'
```

and run

```bash
$ librarian-puppet install
```

## Supported versions

## Tests

Run tests with:

```bash
$ bundle install
$ bundle exec rake spec
```

## Acceptance testing

Fastest way is to run tests on prepared Docker images:
```
BEAKER_set=debian8-3.8 bundle exec rake acceptance
BEAKER_set=centos7-3.8 bundle exec rake acceptance
```
For examining system state set Beaker's ENV variable `BEAKER_destroy=no`:

```
BEAKER_destroy=no BEAKER_set=debian8-3.8 bundle exec rake acceptance
```
and after finishing tests connect to container:
```
docker exec -it adoring_shirley bash
```

When host machine is NOT provisioned (puppet installed, etc.):
```
PUPPET_install=yes BEAKER_set=debian-8 bundle exec rake acceptance
```

Run on specific OS (see `spec/acceptance/nodesets`), to see available sets:
```
rake beaker:sets
```

## License

Apache 2.0
