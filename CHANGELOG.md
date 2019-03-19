# deric-accounts CHANGELOG

## 2.0

 * [BC] drop Puppet 3 compatibility (using Puppet 4 types)
 * `hiera` function replaced by `lookup`
 * [BC] removed `ssh_key` parameter from class `user` (use `ssh_keys` instead)
 * added acceptance tests for Debian
