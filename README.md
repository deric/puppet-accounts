# Puppet Accounts Management

[![Build Status](https://travis-ci.org/deric/puppet-accounts.png)](https://travis-ci.org/deric/puppet-accounts)

This is puppet module for managing user accounts, groups and setting ssh keys.

in node definition include:

```puppet
class {'accounts': }
```


## Tests

Run tests with:

```
$ bundle install
$ bundle exec rake spec
```
