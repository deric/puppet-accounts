# frozen_string_literal: true

require 'spec_helper_acceptance'
require 'pry'

describe 'accounts defintion', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  # see https://github.com/deric/puppet-accounts/issues/50
  context 'manage users' do
    # group is declared in users definition
    let(:pp) do
      <<-EOS
        class {'::accounts':
          users => {
            'dalp' => {
              'uid' => '1005',
              'comment' => 'dalp user',
              'groups' => ['users']
            },
            'deployer' => {
              'uid' => '1010',
            }
          }
        }
      EOS
    end

    it 'install accounts' do
      # all modifications should be done in single run
      # https://github.com/deric/puppet-accounts/issues/60
      expect(apply_manifest(pp,
        :catch_failures => false,
        :debug => false).exit_code).to be_zero
    end

    describe group('users') do
      it { is_expected.to exist }
    end

    describe file('/home/dalp') do
      it { is_expected.to be_directory }
    end

    describe file('/home/deployer') do
      it { is_expected.to be_directory }
    end

    describe user('dalp') do
      it { is_expected.to exist }
      it { is_expected.to have_uid 1005 }
    end

    describe group('dalp') do
      it { is_expected.to exist }
      # group ID was not stated explicitly, first available should
      # be used
    end

    describe command('getent group dalp') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /dalp:x:(\d+):/ }
    end

    describe user('deployer') do
      it { is_expected.to exist }
      it { is_expected.to have_uid 1010 }
    end

    # primary group id
    describe command('id -g -n deployer') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /deployer/ }
    end

    describe command('getent group deployer') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /deployer:x:(\d+):/ }
    end
  end

  context 'without creating primary group' do
    let(:yaml) do
<<-EOS
classes:
  - '::accounts'

accounts::groups:
  mygroup:
    gid: 1141
accounts::users:
  testuser:
    ensure: 'present'
    home: "/home/testuser"
    shell: "/bin/bash"
    uid: 1141
    primary_group: 'mygroup'
    manage_group: true
EOS
    end

        let(:pp) do
<<-EOS
  hiera_include('classes')
EOS
    end

    it 'runs without cycle' do
      shell "echo \"#{yaml}\" > #{HIERA_PATH}/hieradata/common.yaml"

    expect(apply_manifest(pp,
        :catch_failures => false,
        :debug => true).exit_code).to be_zero
    end

    describe group('testuser') do
      it { is_expected.not_to exist }
    end

    describe user('testuser') do
      it { is_expected.to exist }
      it { is_expected.to have_uid 1141 }
    end

    describe group('mygroup') do
      it { is_expected.to exist }
      it { is_expected.to have_gid 1141 }
    end

    describe command('id -g testuser') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /1141/ }
    end

    describe command('id -g -n testuser') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /mygroup/ }
    end

    describe file('/home/testuser') do
      it { is_expected.to be_directory }
    end

    after(:all) do
      shell "rm #{HIERA_PATH}/hieradata/common.yaml"
    end
 end
end
