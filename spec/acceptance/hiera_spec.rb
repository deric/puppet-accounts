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
      shell "echo \"#{yaml}\" > #{HIERA_PATH}/common.yaml"

      expect(apply_manifest(pp,
        :catch_failures => false,
        :debug => false
      ).exit_code).to be_zero
    end

    describe group('staff') do
      it { is_expected.to exist }
      it { is_expected.to have_gid 3000 }
    end
  end
end

