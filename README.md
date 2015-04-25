# Puppet Accounts Management

[![Puppet
Forge](http://img.shields.io/puppetforge/v/deric/accounts.svg)](https://forge.puppetlabs.com/deric/accounts) [![Build Status](https://travis-ci.org/deric/puppet-accounts.png)](https://travis-ci.org/deric/puppet-accounts)

This is puppet module for managing user accounts, groups and setting ssh keys.

Origin: https://github.com/deric/puppet-accounts

in node definition include:

```puppet
class {'accounts': }
```

Hiera allows flexible account management, if you want to have a group defined on all nodes, just put in global hiera config, e.g. `common.yml`:

```YAML
accounts::groups:
 www-data:
   gid: 33
```

and user accounts:

```YAML
accounts::users:
  john:
    comment: "John Doe"
    groups: ["sudo", "users"]
    shell: "/bin/bash"
    pwhash: "$6$GDH43O5m$FaJsdjUta1wXcITgKekNGUIfrqxYogWPVSRoCADGdwFe6H//gzj/VT4lcv55o3z.nrmNb3VbVvgcghz9Ae2Dw0"
    ssh_key:
      type: "ssh-rsa"
      key: "a valid public ssh key string"
      comment: "john@doe"
  alice:
    comment: "Alice"
```

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

## Installation

With [Puppet librarian](https://github.com/rodjek/librarian-puppet) add one line to `Puppetfile`:

```ruby
mod 'accounts', :git => 'https://github.com/deric/puppet-accounts.git'
```

and run

```bash
$ librarian-puppet install
```

## Tests

Run tests with:

```bash
$ bundle install
$ bundle exec rake spec
```

## License

Apache 2.0
