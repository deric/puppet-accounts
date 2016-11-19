require 'spec_helper_acceptance'
require 'pry'

describe 'YAML declaration', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  # see https://github.com/deric/puppet-accounts/issues/46
  context 'manage users and groups' do
    let(:yaml) do
<<-EOS
classes:
  - '::accounts'
accounts::user_defaults:
  purge_ssh_keys: false
accounts::users:
  account1:
    manage_group: false
    uid: 1417
    groups:
      - staff
    comment: 'test'
accounts::groups:
  staff:
    gid: 3000
EOS
    end

        let(:pp) do
<<-EOS
hiera_include('classes')
EOS
    end

    it 'install accounts' do
      shell "echo \"#{yaml}\" > #{HIERA_PATH}/hieradata/common.yaml"

      expect(apply_manifest(pp,
        :catch_failures => false,
        :debug => false
      ).exit_code).to be_zero
    end

    describe group('staff') do
      it { is_expected.to exist }
      it { is_expected.to have_gid 3000 }
    end

    describe user('account1') do
      it { is_expected.to exist }
      it { is_expected.to have_uid 1417 }
    end

    describe command('getent group staff') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /staff:x:(\d+):account1/ }
    end

    describe file('/home/account1') do
      it { is_expected.to be_directory }
    end

    describe command('cat /etc/passwd | grep account1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /test/ }
    end
  end
end

