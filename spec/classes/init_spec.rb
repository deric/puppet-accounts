require 'spec_helper'

describe 'accounts', :type => :class do
  let(:facts) { {
    :osfamily => 'Debian',
    :puppetversion => Puppet.version,
  } }
  let(:params){{
    :manage_users  => true,
    :manage_groups => true,
  }}

  it { is_expected.to compile.with_all_deps }
  it { is_expected.to contain_class('accounts::users') }
  it { is_expected.to contain_class('accounts::groups') }

  shared_examples 'having account' do |user, uid, group, gid|
    it 'has home folder' do
      is_expected.to contain_file("/home/#{user}").with(
        'ensure' => 'directory',
        'owner'  => user,
      )
    end
    grp = gid.nil? ? group : gid

    it { is_expected.to contain_file("/home/#{user}/.ssh").with(
      'ensure' => 'directory',
      'owner'   => user,
      'group'   => grp,
    )}

    it { is_expected.to contain_file("/home/#{user}/.ssh/authorized_keys").with(
      'ensure' => 'present',
      'owner'  => user,
      'group'  => grp,
      'mode'   => '0600',
    )}

    it { is_expected.to contain_user(user).with(
      'name'   => user,
      'ensure' => 'present',
      'uid'    => uid,
      'gid'    => grp,
    )}

    it { is_expected.to contain_accounts__user(user).with(
      'username' => user,
      'uid' => uid,
      'gid' => gid,
    )}

    # primary group
    it { is_expected.to contain_accounts__group(group).with(
      'groupname' => group,
      'ensure' => 'present',
      'gid' => gid,
    )}

    it { is_expected.to contain_group(group).with(
      'name'    => group,
      'ensure'  => 'present',
      'gid'     => gid,
    )}
  end

  context 'allow passing users and groups directly to init class' do
    let(:params){{
      :users => { 'john' => { 'comment' => 'John Doe', 'gid' => 2001 }},
      :groups => { 'developers' => { 'gid' => 2001 }}
    }}

    it { is_expected.to contain_user('john').with(
      'comment' => 'John Doe',
      'gid' => 2001
    )}
    it_behaves_like 'having account', 'john', nil, 'john', 2001

    it { is_expected.to contain_group('developers').with(
      'gid'    => 2001,
      'ensure' => 'present'
    )}
  end

  context 'no group management' do
    let(:params){{
      :users => { 'john' => {
          'comment'      => 'John Doe',
          'gid'          => 'john',
          'manage_group' => false,
        }
      },
      :groups => { 'developers' => { 'gid' => 2001 }},
      :manage_groups => false,
    }}

    it do
      is_expected.to contain_user('john').with(
        'comment' => 'John Doe',
        'gid' => 'john'
      )
      is_expected.to contain_file('/home/john').with(
        'ensure' => 'directory',
        'owner'  => 'john',
      )
      is_expected.to contain_accounts__user('john').with(
          'username' => 'john',
          'gid' => 'john',
      )
    end

    it { is_expected.not_to contain_group('developers').with(
      'gid'    => 2001,
      'ensure' => 'present'
    )}

    it 'does not create primary group' do
      is_expected.not_to contain_group('john').with('ensure' => 'present')
    end
  end

  context 'test hiera fixtures' do
    if Gem::Version.new(Puppet.version) >= Gem::Version.new('3.6.0')
      it { is_expected.to contain_user('myuser').with(
        'uid' => 1000,
        'comment' => 'My Awesome User',
        'purge_ssh_keys' => true,
      )}
    else
      it { is_expected.to contain_user('myuser').with(
        'uid' => 1000,
        'comment' => 'My Awesome User',
        # no purge_ssh_keys attribute
      )}
    end

    it { is_expected.to contain_ssh_authorized_key('myawesomefirstkey').with(
      'type' => 'ssh-rsa',
      'key' => 'yay',
    )}

    it { is_expected.to contain_ssh_authorized_key('myawesomesecondkey').with(
      'type' => 'ssh-rsa',
      'key' => 'hey',
    )}

    context 'root account' do
      it { is_expected.to contain_user('root').with(
        'uid' => 0,
        'shell' => '/bin/bash',
      )}

      it { is_expected.to contain_group('root').with(
        'gid'    => 0,
        'ensure' => 'present'
      )}

      it { is_expected.to contain_file("/root").with({
        'ensure'  => 'directory',
        'owner'   => 'root',
        'group'   => '0',
        'mode'    => '0755'
      }) }

      it { is_expected.to contain_ssh_authorized_key('root_key1').with(
        'type' => 'ssh-rsa',
        'key'  => 'AAA_key1',
        'user' => 'root',
      )}

      it { is_expected.to contain_ssh_authorized_key('root_key2').with(
        'type' => 'ssh-rsa',
        'key'  => 'AAA_key2',
        'user' => 'root',
      )}
    end

    context 'superman account' do
      it { is_expected.to contain_user('superman').with(
        'shell' => '/bin/bash',
      )}

      it_behaves_like 'having account', 'superman', nil, 'superman', nil

      it { is_expected.to contain_group('superheroes').with(
        'ensure' => 'present',
        'members' => ['batman', 'superman']
      )}

      it { is_expected.to contain_group('sudo').with(
        'ensure' => 'present',
      )}

      it { is_expected.to contain_ssh_authorized_key('super_key').with(
        'type' => 'ssh-dss',
        'key'  => 'AAABBB',
        'user' => 'superman',
        'options' => ['permitopen="10.0.0.1:3306"'],
      )}

      it { is_expected.to contain_file("/home/superman").with({
        'ensure'  => 'directory',
        'owner'   => 'superman',
        'group'   => 'superman',
        'mode'    => '0755'
      }) }
    end

    context 'deadpool account' do
      it { is_expected.to contain_user('deadpool').with(
        'ensure' => 'absent',
      )}
    end
  end

  context 'manage GID of user\'s primary group' do
    let(:params){{
      :groups => { 'testgroup' => {
        'members' => [ 'www-data', 'testuser' ]
        }
      },
      :users => { 'testuser' => {
        'shell'   => '/bin/bash',
        'primary_group' => 'testgroup',
        'gid' => 800,
      }}
    }}

    it_behaves_like 'having account', 'testuser', nil, 'testgroup', 800
  end

  context 'assign groups' do
    let(:params){{
      :users => { 'foo' => {
        'home' => '/home/foo',
        'groups' => ['users'],
      }}
    }}

    it { is_expected.to contain_user('foo').with(
      'ensure' => 'present',
      'home' => '/home/foo'
    )}

    it { is_expected.to contain_group('foo').with(
      'ensure' => 'present'
    )}

    it { is_expected.to contain_group('users').with(
      'ensure' => 'present',
      'members' => ['foo'],
    )}

    it_behaves_like 'having account', 'foo', nil, 'foo', nil
  end

  context 'assign default groups' do
    let(:params){{
      :users => { 'foo' => {
        'home' => '/home/foo',
      }},
      :user_defaults => {
        'groups' => ['users'], # default group for all users
      },
    }}

    it { is_expected.to contain_user('foo').with(
      'ensure' => 'present',
      'home' => '/home/foo'
    )}

    it { is_expected.to contain_group('foo').with(
      'ensure' => 'present'
    )}

    it { is_expected.to contain_group('users').with(
      'ensure' => 'present',
      'members' => ['foo', 'myuser', 'root'], # acounts from hiera/default.yaml
    )}

    it_behaves_like 'having account', 'foo', nil, 'foo', nil
  end

  context 'allow changing primary group\'s name' do
    let(:params){{
      :users => { 'john' => {
        'primary_group' => 'users',
      }}
    }}

    it_behaves_like 'having account', 'john', nil, 'users', nil
  end

  context 'optional group management' do
    let(:params){{
      :users => { 'mickey' => {
        'manage_group' => false,
      }}
    }}

    it { is_expected.not_to contain_group('mickey').with(
      'ensure' => 'present'
    )}
  end

  context 'create new user' do
    let(:params){{
      :users => { 'foobar' => {
        'uid' => 1001,
        'gid' => 1001,
      }}
    }}

    it_behaves_like 'having account', 'foobar', 1001, 'foobar', 1001
  end

end
