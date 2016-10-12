require 'spec_helper'

describe 'accounts::users', :type => :class do

  shared_examples 'having_user_account' do |user|
    let(:owner) { user }
    let(:group) { user }

    it { is_expected.to contain_user(user) }
    # currently managed out of this class
    #it { should contain_group(user) }

    it { is_expected.to contain_file("/home/#{user}").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0755'
    }) }

    it { is_expected.to contain_file("/home/#{user}/.ssh").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it { is_expected.to contain_file("/home/#{user}/.ssh/authorized_keys").with({
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

    it { is_expected.not_to contain_file("/home/#{user}").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it { is_expected.not_to contain_file("/home/#{user}/.ssh").with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it { is_expected.not_to contain_file("/home/#{user}/.ssh/authorized_keys").with({
      'ensure'  => 'present',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0600'
    }) }
  end

  context 'users accoutns' do
    let(:facts) { {
      :osfamily      => 'Debian',
      :puppetversion => Puppet.version,
    } }

    describe 'invalid parameters' do
      let(:params){{
        :users => ['foo'],
        :manage => true,
      }}

      it do
        expect {
          is_expected.to compile
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


    describe 'multiple users with same UID' do
      let(:params){{
        :users => {
          'foo' => {'allowdupe' => true,'uid' => 1001},
          'bar' => {'allowdupe' => true,'uid' => 1001},
        },
      }}
      it_behaves_like 'having_user_account', 'foo'
      it_behaves_like 'having_user_account', 'bar'

      it { is_expected.to contain_user('foo').with(
        'name'      => 'foo',
        'uid'       => 1001,
        'allowdupe' => true,
      )}

      it { is_expected.to contain_user('bar').with(
        'name'      => 'bar',
        'uid'       => 1001,
        'allowdupe' => true,
      )}
    end

  end

end
