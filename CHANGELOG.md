# deric-accounts CHANGELOG

## 2.1.0

 * remove `assert_private` ([#99](https://github.com/deric/puppet-accounts/issues/99))
 * disable removing home by default ([#84](https://github.com/deric/puppet-accounts/issues/84))

## 2.0.0

 * [BC] drop Puppet 3 compatibility (using Puppet 4 types)
 * `hiera` function replaced by `lookup`
 * [BC] removed `ssh_key` parameter from class `user` (use `ssh_keys` instead)
 * added acceptance tests for Debian
 * tested on Hiera 5 (Hiera 3 supported, but not included in test suites)
