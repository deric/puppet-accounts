# Puppet Accounts Management

[![Build Status](https://travis-ci.org/deric/puppet-accounts.png)](https://travis-ci.org/deric/puppet-accounts)

This is puppet module for managing user accounts, groups and setting ssh keys.

in node definition include:

```puppet
class {'accounts': }
```

### Hiera

Hiera allows flexible account management, if you want to have a group defined on all nodes, just put in global hiera config, e.g. `common.yml`:

```YAML
accounts::groups:
 www-data:
   gid: 33
```

and user accounts:

```YAML
accounts::users:
 deric:
   comment: "John Doe"
   groups: ["sudo", "users"]
   shell: "/bin/bash"
   pwhash: "$6$GDH43O5m$FaJsdjUta1wXcITgKekNGUIfrqxYogWPVSRoCADGdwFe6H//gzj/VT4lcv55o3z.nrmNb3VbVvgcghz9Ae2Dw0"
   ssh_key:
    type: "ssh-rsa"
    key: "a valid public ssh key string"
    comment: "john@doe"
```

Which accounts will be installed on specific machine can be checked from command line:

```bash
$ hiera -y my_node.yml accounts::users --hash
```

where `my_node.yml` is a file which you get from facter running at some node:

```bash
$ facter -y > my_node.yml
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
