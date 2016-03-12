# Puppet Accounts Management

[![Puppet
Forge](http://img.shields.io/puppetforge/v/deric/accounts.svg)](https://forge.puppetlabs.com/deric/accounts) [![Build Status](https://travis-ci.org/deric/puppet-accounts.png)](https://travis-ci.org/deric/puppet-accounts)

This is puppet module for managing user accounts, groups and setting ssh keys.

Origin: https://github.com/deric/puppet-accounts

in node definition include:

```puppet
class {'accounts':
  user_defaults => {
    purge_ssh_keys => true, # will delete all authorized keys that are not in Puppet
  }
}
```

Hiera allows flexible account management, if you want to have a group defined on all nodes, just put in global hiera config, e.g. `common.yml`:

```YAML
accounts::user_defaults:
  purge_ssh_keys: true
accounts::groups:
  www-data:
    gid: 33
    # not necessarily complete list of memebers, you can assign users to the same group on user's level using `groups: ['www-data']`
    members: ['john']
```

and user accounts:

```YAML
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

### Account removal

Removing account could be done by setting `ensure` parameter to `absent`:

```yaml
accounts::users:
 john:
   ensure: 'absent'
   managehome: true
```

If `managehome` is set to `true` (default), also home directory will be removed!

## User

* `authorized_keys_file` - allows proividing location of custom `authorized_keys`
* `purge_ssh_keys` - delete all keys except those explicitly provided (default: `false`)
* `ssh_key_source` - provide file with authorized keys
* `pwhash` - set password hash
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

## Global settings

You can provide global defaults for all users:

```yaml
accounts:
 user_defaults:
   shell: '/bin/dash'
```

### Testing

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
gem install deee_merge
```

and update `merge_behavior` in your `hiera.yaml`, e.g.:
```
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

Just run:
```
bundle exec rake acceptance
```
When host machine is provisioned (puppet installed, etc.):
```
BEAKER_provision=no bundle exec rake acceptance
```
detailed Vagrant log:
```
VAGRANT_LOG=DEBUG BEAKER_provision=no bundle exec rake acceptance
```

Run on specific OS (see `spec/acceptance/nodesets`):
```
BEAKER_set=centos-7-x64 bundle exec rake acceptance
```

Change Vagrant provider:
```
export VAGRANT_DEFAULT_PROVIDER=lxc
```

Don't destroy machine after running specs:
```
BEAKER_destroy=no bundle exec rake acceptance
```


## License

Apache 2.0
