require 'spec_helper'

describe 'accounts::user' do

  shared_examples 'not_having_home_dir' do |user, home_dir|
    let(:owner) { user }
    let(:group) { user }

    it { should_not contain_file("#{home_dir}").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0755'
    }) }

    it { should_not contain_file("#{home_dir}/.ssh").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it { should_not contain_file("#{home_dir}/.ssh/authorized_keys").with({
      'ensure'  => 'present',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0600'
    }) }
  end

  shared_examples 'having_home_dir' do |user, home_dir|
    let(:owner) { user }
    let(:group) { user }
    let(:facts) { {:osfamily => 'Debian'} }

    it { should contain_file("#{home_dir}").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0755'
    }) }

    it { should contain_file("#{home_dir}/.ssh").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it { should contain_file("#{home_dir}/.ssh/authorized_keys").with({
      'ensure'  => 'present',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0600'
    }) }
  end

  context 'create new user' do
    let(:title) { 'foobar' }
    let(:owner) { 'foobar' }
    let(:group) { 'foobar' }
    let(:params){{
      :uid => 1001,
      :gid => 1001,
    }}

    it { should contain_user('foobar').with(
      'uid' => 1001,
      'gid' => 1001
    )}

    it { should contain_group('foobar').with(
      'gid'    => 1001,
      'ensure' => 'present'
    )}

    it_behaves_like 'having_home_dir', 'foobar', '/home/foobar'
  end

  context 'create new user without specified uid' do
    let(:title) { 'foobar' }
    let(:owner) { 'foobar' }
    let(:group) { 'foobar' }

    it_behaves_like 'having_home_dir', 'foobar', '/home/foobar'
  end

  context 'custom home directory' do
    let(:title) { 'foobar' }
    let(:owner) { 'foobar' }
    let(:group) { 'foobar' }
    let(:home) { '/var/www' }

    let(:params){{
      :home => home,
    }}

    it_behaves_like 'having_home_dir', 'foobar', '/var/www'
  end

  context 'not managing home' do
    let(:title) { 'foobar' }
    let(:home) { '/var/www' }

    let(:params){{
      :home       => home,
      :managehome => false
    }}

    it_behaves_like 'not_having_home_dir', 'foobar', '/var/www'
  end


  context 'root home' do
    let(:title) { 'root' }

    # root has automatically special home folder
    it_behaves_like 'having_home_dir', 'root', '/root'
  end

  context 'invalid ensure' do
    let(:title) { 'foo' }
    let(:home) { '/home/foo' }

    let(:params){{
      :home       => home,
      :managehome => false,
      :ensure     => 'whatever'
    }}

    it do
      expect {
        should compile
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /parameter must be 'absent' or 'present'/)
    end
  end

  context 'assign groups' do
    let(:title) { 'foo' }
    let(:home) { '/home/foo' }

    let(:params){{
      :home  => home,
      :groups => ['users']
    }}

    it { should contain_anchor('accounts::user::groups::foo') }

    it { should contain_user('foo').with(
      'ensure' => 'present'
    ).that_requires('Anchor[accounts::user::groups::foo]') }

    it { should contain_group('foo').with(
      'ensure' => 'present'
    )}
  end

  context 'optional group management' do
    let(:title) { 'mickey' }

    let(:params){{
      :manage_group => false
    }}

    it { should contain_anchor('accounts::user::groups::mickey') }

    it { should_not contain_group('mickey').with(
      'ensure' => 'present'
    )}
  end

  context 'remove group with user\'s account' do
    let(:title) { 'mickey' }

    let(:params){{
      :manage_group => true,
      :ensure       => 'absent'
    }}

    it { should contain_user('mickey').with(
      'ensure' => 'absent'
    )}

    it { should contain_group('mickey').with(
      'ensure' => 'absent'
    )}
  end

  context 'allow changing primary group\'s name' do
    let(:title) { 'john' }

    let(:params){{
      :primary_group => 'users',
    }}

    it { should contain_user('john').with(
      'ensure' => 'present'
    )}

    it { should contain_group('users').with(
      'ensure' => 'present'
    )}

    it { should_not contain_group('john').with(
      'ensure' => 'present'
    )}
  end


  context 'purge ssh keys' do
    let(:title) { 'john' }

    puppet = `puppet --version`
    let(:facts) {{
      :puppetversion => puppet
    }}

    let(:params){{
      :purge_ssh_keys => true
    }}
    if Gem::Version.new(puppet) < Gem::Version.new('3.6.0')
      it { should contain_user('john').with(
        'ensure' => 'present'
      )}
    else
      it { should contain_user('john').with(
        'ensure'         => 'present',
        'purge_ssh_keys' => true
      )}
    end
  end

  context 'empty comment' do
    let(:title) { 'foo' }
    let(:home) { '/home/foo' }

    let(:params){{
      :home    => home,
      :comment => nil,
    }}

    it { should contain_user('foo').with(
      'ensure' => 'present'
    )}
  end
end
