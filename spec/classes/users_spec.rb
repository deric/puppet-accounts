require 'spec_helper'

describe 'accounts::users', :type => :class do

  shared_examples 'having_user_account' do |user|
    let(:owner) { user }
    let(:group) { user }
    let(:facts) { {
      :osfamily      => 'Debian',
      :puppetversion => Puppet.version,
    } }
    it { should contain_user(user) }
    # currently managed out of this class
    #it { should contain_group(user) }

    it { should contain_file("/home/#{user}").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0755'
    }) }

    it { should contain_file("/home/#{user}/.ssh").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it { should contain_file("/home/#{user}/.ssh/authorized_keys").with({
      'ensure'  => 'present',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0600'
    }) }
  end

  shared_examples 'not_having_user_account' do |user|
    let(:owner) { user }
    let(:group) { user }
    it { should_not contain_user(user) }
    it { should_not contain_group(user) }

    it { should_not contain_file("/home/#{user}").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it { should_not contain_file("/home/#{user}/.ssh").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it { should_not contain_file("/home/#{user}/.ssh/authorized_keys").with({
      'ensure'  => 'present',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0600'
    }) }
  end


  describe 'invalid parameters' do
    let(:params){{
      :users => ['foo'],
      :manage => true,
    }}

    it do
      expect {
        should compile
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /is not a Hash/)
    end
  end

  describe 'create user account' do
    let(:params){{
      :users => {'foo' => {} },
      :manage => true,
    }}
    it_behaves_like 'having_user_account', 'foo'
  end

  describe 'do not create a user account' do
    let(:params){{
      :users => {'foo' => {} },
      :manage => false,
    }}
    it_behaves_like 'not_having_user_account', 'foo'
  end

  describe 'multiple users with the same key comment' do
    let(:params){{
      :users => {
        'tom' => {'pwhash' => 'xxxxxxx','ssh_key' => {'comment' => 'id_rsa','type' => 'ssh-rsa','key' =>  'xxxxxxx'}},
        'jerry' => {'pwhash' => 'xxxxxxx','ssh_key' => {'comment' => 'id_rsa','type' => 'ssh-rsa','key' =>  'xxxxxxx'}},
      },
    }}
    it_behaves_like 'having_user_account', 'tom'
    it_behaves_like 'having_user_account', 'jerry'
  end

  describe 'multiple users without key comment' do
    let(:params){{
      :users => {
        'tom' => {'pwhash' => 'xxxxxxx','ssh_key' => {'type' => 'ssh-rsa','key' =>  'xxxxxxx'}},
        'jerry' => {'pwhash' => 'xxxxxxx','ssh_key' => {'type' => 'ssh-rsa','key' =>  'xxxxxxx'}},
      },
    }}
    it_behaves_like 'having_user_account', 'tom'
    it_behaves_like 'having_user_account', 'jerry'
  end

end
