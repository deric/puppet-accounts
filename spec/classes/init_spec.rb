# frozen_string_literal: true

require 'spec_helper'

describe 'accounts', :type => :class do
  let(:facts) do
    {
      :osfamily => 'Debian',
      :puppetversion => Puppet.version,
    }
  end
  let(:params) do
    {
      :manage_users  => true,
      :manage_groups => true,
    }
  end

  it { is_expected.to compile.with_all_deps }
  it { is_expected.to contain_class('accounts') }

  shared_examples 'having account' do |user, uid, group, gid|
    it 'has home folder' do
      is_expected.to contain_file("/home/#{user}").with(
        'ensure' => 'directory',
        'owner'  => user
      )
    end
    grp = gid.nil? ? group : gid

    it {
      is_expected.to contain_file("/home/#{user}/.ssh").with(
        'ensure' => 'directory',
        'owner'   => user,
        'group'   => grp
      )
    }

    it {
      is_expected.to contain_file("/home/#{user}/.ssh/authorized_keys").with(
        'ensure' => 'present',
        'owner'  => user,
        'group'  => grp,
        'mode'   => '0600'
      )
    }

    it {
      is_expected.to contain_user(user).with(
        'name'   => user,
        'ensure' => 'present',
        'uid'    => uid,
   #   'gid'    => grp, # TODO: find better way how to check gid
      )
    }

    it {
      is_expected.to contain_accounts__user(user).with(
        'username' => user,
        'uid' => uid,
        'gid' => gid
      )
    }

    # primary group
    it {
      is_expected.to contain_accounts__group(group).with(
        'groupname' => group,
        'ensure' => 'present',
        'gid' => gid
      )
    }

    it {
      is_expected.to contain_group(group).with(
        'name'    => group,
        'ensure'  => 'present',
        'gid'     => gid
      )
    }
  end

  context 'allow passing users and groups directly to init class' do
    let(:params) do
      {
      :users => { 'john' => { 'comment' => 'John Doe', 'gid' => 2001 }},
      :groups => { 'developers' => { 'gid' => 2001 }}
    }
    end

    it {
      is_expected.to contain_user('john').with(
        'comment' => 'John Doe',
    #  'gid' => 2001
      )
    }
    it_behaves_like 'having account', 'john', nil, 'john', 2001

    it {
      is_expected.to contain_group('developers').with(
        'gid'    => 2001,
        'ensure' => 'present'
      )
    }
  end

  context 'no group management' do
    let(:params) do
      {
      :users => { 'john' => {
          'comment'      => 'John Doe',
          'gid'          => 'john',
          'manage_group' => false,
        }},
      :groups => { 'developers' => { 'gid' => 2001 }},
      :manage_groups => false,
    }
    end

    it do
      is_expected.to contain_user('john').with(
        'comment' => 'John Doe',
      #  'gid' => 'john'  # TODO: make sure gid is updated from groups
      )
      is_expected.to contain_file('/home/john').with(
        'ensure' => 'directory',
        'owner'  => 'john'
      )
      is_expected.to contain_accounts__user('john').with(
        'username' => 'john',
        'gid' => 'john'
      )
    end

    it {
      is_expected.not_to contain_group('developers').with(
        'gid'    => 2001,
        'ensure' => 'present'
      )
    }

    it 'does not create primary group' do
      is_expected.not_to contain_group('john').with('ensure' => 'present')
    end
  end

  context 'test hiera fixtures' do

    it {
      is_expected.to contain_user('myuser').with(
        'uid' => 1000,
        'comment' => 'My Awesome User',
      # no purge_ssh_keys attribute
      )
    }

    it {
      is_expected.to contain_ssh_authorized_key('myawesomefirstkey').with(
        'type' => 'ssh-rsa',
        'key' => 'yay'
      )
    }

    it {
      is_expected.to contain_ssh_authorized_key('myawesomesecondkey').with(
        'type' => 'ssh-rsa',
        'key' => 'hey'
      )
    }

    context 'root account' do
      it {
        is_expected.to contain_user('root').with(
          'uid' => 0,
          'shell' => '/bin/bash'
        )
      }

      it {
        is_expected.to contain_group('root').with(
          'gid'    => 0,
          'ensure' => 'present'
        )
      }

      it {
        is_expected.to contain_file("/root").with({
        'ensure'  => 'directory',
        'owner'   => 'root',
        'group'   => '0',
        'mode'    => '0755'
      }) }

      it {
        is_expected.to contain_ssh_authorized_key('root_key1').with(
          'type' => 'ssh-rsa',
          'key' => 'AAA_key1'
        )
      }

      it {
        is_expected.to contain_ssh_authorized_key('root_key2').with(
          'type' => 'ssh-rsa',
          'key' => 'AAA_key2'
        )
      }
    end

    context 'superman account' do
      it {
        is_expected.to contain_user('superman').with(
          'shell' => '/bin/bash'
        )
      }

      it_behaves_like 'having account', 'superman', nil, 'superman', nil

      it {
        is_expected.to contain_group('superheroes').with(
          'ensure' => 'present',
          'members' => ['batman', 'superman']
        )
      }

      it {
        is_expected.to contain_group('sudo').with(
          'ensure' => 'present'
        )
      }

      it {
        is_expected.to contain_ssh_authorized_key('super_key').with(
          'type' => 'ssh-dss',
          'key'  => 'AAABBB',
          'user' => 'superman',
          'options' => ['permitopen="10.0.0.1:3306"']
        )
      }

      it {
        is_expected.to contain_file("/home/superman").with({
        'ensure'  => 'directory',
        'owner'   => 'superman',
        'group'   => 'superman',
        'mode'    => '0755'
      }) }
    end

    context 'deadpool account' do
      it {
        is_expected.to contain_user('deadpool').with(
          'ensure' => 'absent'
        )
      }
    end

    context 'batman account' do
      it {
        is_expected.to contain_user('batman').with(
          'ensure'  => 'present',
          'comment' => 'Bruce Wayne'
        )
      }

      it {
        is_expected.to contain_ssh_authorized_key('bat_key').with(
          'type' => 'ssh-dss',
          'key'  => 'AAABBBatman',
          'user' => 'batman',
        )
      }
    end
  end

  context 'manage GID of user\'s primary group' do
    let(:params) do
      {
      :groups => { 'testgroup' => {
        'members' => [ 'www-data', 'testuser' ]
        }},
      :users => { 'testuser' => {
        'shell'   => '/bin/bash',
        'primary_group' => 'testgroup',
        'gid' => 800,
      }}
    }
    end

    it_behaves_like 'having account', 'testuser', nil, 'testgroup', 800
  end

  context 'assign groups' do
    let(:params) do
      {
      :users => { 'foo' => {
        'home' => '/home/foo',
        'groups' => ['users'],
      }}
    }
    end

    it {
      is_expected.to contain_user('foo').with(
        'ensure' => 'present',
        'home' => '/home/foo'
      )
    }

    it {
      is_expected.to contain_group('foo').with(
        'ensure' => 'present'
      )
    }

    it {
      is_expected.to contain_group('users').with(
        'ensure' => 'present',
        'members' => ['foo']
      )
    }

    it_behaves_like 'having account', 'foo', nil, 'foo', nil
  end

  context 'assign default groups' do
    let(:params) do
      {
      :users => { 'foo' => {
        'home' => '/home/foo',
      }},
      :user_defaults => {
        'groups' => ['users'], # default group for all users
      },
    }
    end

    it {
      is_expected.to contain_user('foo').with(
        'ensure' => 'present',
        'home' => '/home/foo'
      )
    }

    it {
      is_expected.to contain_group('foo').with(
        'ensure' => 'present'
      )
    }

    it {
      is_expected.to contain_group('users').with(
        'ensure' => 'present',
        'members' => ['foo', 'myuser', 'root'], # acounts from hiera/default.yaml
      )
    }

    it_behaves_like 'having account', 'foo', nil, 'foo', nil
  end

  context 'allow changing primary group\'s name' do
    let(:params) do
      {
      :users => { 'john' => {
        'primary_group' => 'users',
      }}
    }
    end

    it_behaves_like 'having account', 'john', nil, 'users', nil
  end

  context 'optional group management' do
    let(:params) do
      {
      :users => { 'mickey' => {
        'manage_group' => false,
      }}
    }
    end

    it {
      is_expected.not_to contain_group('mickey').with(
        'ensure' => 'present'
      )
    }
  end

  context 'create new user' do
    let(:params) do
      {
      :users => { 'foobar' => {
        'uid' => 1001,
        'gid' => 1001,
      }}
    }
    end

    it_behaves_like 'having account', 'foobar', 1001, 'foobar', 1001
  end

  # see #41, #46
  # https://github.com/deric/puppet-accounts/issues/41
  context 'honore manage group=false' do
    let(:params) do
      {
      :groups => { 'staff' => {
        'gid' => 3000
        }},
      :users => { 'account1' => {
        'manage_group' => false,
        'uid' => 1417,
        'groups' => ['staff'],
      }}
    }
    end

    it {
      is_expected.to contain_user('account1').with(
        'ensure' => 'present',
        'home' => '/home/account1',
        'uid' => 1417,
        'gid' => nil, # should be :undef, but doesn't work yet
      )
    }

    it {
      is_expected.to contain_accounts__user('account1').with(
        'username' => 'account1',
        'uid' => 1417,
        'gid' => nil
      )
    }

    it {
      is_expected.to contain_group('staff').with(
        'ensure' => 'present',
        'gid' => 3000,
        'members' => ['account1']
      )
    }
  end

  describe 'invalid parameters' do
    let(:params) do
      {
      :groups => ['foo'],
      :manage_groups => true,
    }
    end

    it "checks type", :if => Puppet.version < "4.0.0" do
      expect do
         is_expected.to compile
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /is not a Hash/)
    end
  end

  describe 'create multiple user' do
    let(:params) do
      {
      :groups => {
        'www-data' => {'gid' => 33},
        'users' => {'gid' => 100},
        },
      :manage_groups => true,
    }
    end

    it { is_expected.to compile.with_all_deps }
    it {
      is_expected.to contain_group('www-data').with(
        'gid'    => 33,
        'ensure' => 'present'
      )
    }

    it {
      is_expected.to contain_group('users').with(
        'gid'    => 100,
        'ensure' => 'present'
      )
    }
  end

  shared_examples 'having_user_account' do |user|
    let(:owner) { user }
    let(:group) { user }

    it { is_expected.to contain_user(user) }
    # currently managed out of this class
    #it { should contain_group(user) }

    it {
      is_expected.to contain_file("/home/#{user}").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0755'
    }) }

    it {
      is_expected.to contain_file("/home/#{user}/.ssh").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it {
      is_expected.to contain_file("/home/#{user}/.ssh/authorized_keys").with({
      'ensure'  => 'present',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0600'
    }) }
  end

  shared_examples 'not_having_user_account' do |user|
    let(:owner) { user }
    let(:group) { user }
    it { is_expected.not_to contain_user(user) }
    it { is_expected.not_to contain_group(user) }

    it {
      is_expected.not_to contain_file("/home/#{user}").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it {
      is_expected.not_to contain_file("/home/#{user}/.ssh").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it {
      is_expected.not_to contain_file("/home/#{user}/.ssh/authorized_keys").with({
      'ensure'  => 'present',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0600'
    }) }
  end

  context 'users accounts' do
    let(:facts) do
      {
      :osfamily      => 'Debian',
      :puppetversion => Puppet.version,
    }
    end

    describe 'invalid parameters' do
      let(:params) do
        {
        :users => ['foo'],
        :manage_users => true,
      }
      end

      it 'checks type', :if => Puppet.version < "4.0.0" do
        expect do
          is_expected.to compile
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /is not a Hash/)
      end
    end

    describe 'create user account' do
      let(:params) do
        {
        :users => {'foo' => {} },
        :manage_users => true,
      }
      end
      it_behaves_like 'having_user_account', 'foo'
    end

    describe 'do not create a user account' do
      let(:params) do
        {
        :users => {'foogbar' => {} },
        :manage_users => false,
        :manage_groups => false,
        :use_lookup => false,
      }
      end
      it_behaves_like 'not_having_user_account', 'foogbar'
    end

    describe 'multiple users with defined name' do
      let(:params) do
        {
        :users => {
          'tom' => {'pwhash' => 'xxxxxxx','ssh_keys' => {'tom' => {'name' => 'tom_id_rsa','type' => 'ssh-rsa','key' => 'xxxxxxx'}}},
          'jerry' => {'pwhash' => 'xxxxxxx','ssh_keys' => {'jerry' => {'name' => 'jerry_id_rsa','type' => 'ssh-rsa','key' => 'xxxxxxx'}}},
        },
      }
      end
      it_behaves_like 'having_user_account', 'tom'
      it_behaves_like 'having_user_account', 'jerry'
    end

    describe 'multiple users without key comment' do
      let(:params) do
        {
        :users => {
          'tom' => {'pwhash' => 'xxxxxxx','ssh_keys' => {'tom' => {'type' => 'ssh-rsa','key' => 'xxxxxxx'}}},
          'jerry' => {'pwhash' => 'xxxxxxx','ssh_keys' => {'jerry' => {'type' => 'ssh-rsa','key' => 'xxxxxxx'}}},
        },
      }
      end
      it_behaves_like 'having_user_account', 'tom'
      it_behaves_like 'having_user_account', 'jerry'
    end


    describe 'multiple users with same UID' do
      let(:params) do
        {
        :users => {
          'foo' => {'allowdupe' => true,'uid' => 1001},
          'bar' => {'allowdupe' => true,'uid' => 1001},
        },
      }
      end
      it_behaves_like 'having_user_account', 'foo'
      it_behaves_like 'having_user_account', 'bar'

      it {
        is_expected.to contain_user('foo').with(
          'name'      => 'foo',
          'uid'       => 1001,
          'allowdupe' => true
        )
      }

      it {
        is_expected.to contain_user('bar').with(
          'name'      => 'bar',
          'uid'       => 1001,
          'allowdupe' => true
        )
      }
    end
  end

  context 'user_default are applied' do
    let(:params) do
      {
      :users => { 'foo' => {
        'home' => '/home/foo',
      }},
      :user_defaults => {
        'shell'      => '/bin/ash',
        'managehome' => true,
      },
    }
    end

    it {
      is_expected.to contain_user('foo').with(
        'name'       => 'foo',
        'home'       => '/home/foo',
        'shell'      => '/bin/ash',
        'managehome' => true
      )
    }

    it_behaves_like 'having_user_account', 'foo'
  end

  context 'ssh_key_groups are defined' do
    let(:ssh_key_groups) do
      {
        'key_group1' =>  {
          'user1@example.com' => { 'type' => 'ssh-rsa', 'key' => 'user1-key' },
        },
        'key_group2' => {
          'user2@example.com' => { 'type' => 'ssh-rsa', 'key' => 'user2-key' },
          'user3@example.com' => { 'type' => 'ssh-rsa', 'key' => 'user3-key' },
        },
      }
    end

    describe 'user includes only one ssh key group' do
      let(:params) do
        {
          'ssh_key_groups' => ssh_key_groups,
          'users' => { 'testuser' => {
            'managehome' => true,
            'ssh_key_groups' => ['key_group1']
          }}
        }
      end

      it { is_expected.to contain_ssh_authorized_key('user1@example.com') }
      it { is_expected.to_not contain_ssh_authorized_key('user2@example.com') }
      it { is_expected.to_not contain_ssh_authorized_key('user3@example.com') }
    end

    describe 'user includes multiple ssh key groups' do
      let(:params) do
        {
          'ssh_key_groups' => ssh_key_groups,
          'users' => { 'testuser' => {
            'managehome' => true,
            'ssh_key_groups' => ['key_group1', 'key_group2']
          }}
        }
      end

      it { is_expected.to contain_ssh_authorized_key('user1@example.com') }
      it { is_expected.to contain_ssh_authorized_key('user2@example.com') }
      it { is_expected.to contain_ssh_authorized_key('user3@example.com') }
    end

    describe 'user includes an ssh key group and an individual ssh key' do
      let(:params) do
        {
          'ssh_key_groups' => ssh_key_groups,
          'users' => { 'testuser' => {
            'managehome' => true,
            'ssh_key_groups' => ['key_group1'],
            'ssh_keys' => {
              'user4@example.com' => { 'type' => 'ssh-rsa', 'key' => 'user4-key' }
            }
          }}
        }
      end

      it { is_expected.to contain_ssh_authorized_key('user1@example.com') }
      it { is_expected.to_not contain_ssh_authorized_key('user2@example.com') }
      it { is_expected.to_not contain_ssh_authorized_key('user3@example.com') }
      it { is_expected.to contain_ssh_authorized_key('user4@example.com') }
    end
  end
end
