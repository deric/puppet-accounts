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
        :debug => false
      ).exit_code).to be_zero
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
      its(:stdout) { is_expected.to match /dalp:x:(\d+):dalp/ }
    end

    describe user('deployer') do
      it { is_expected.to exist }
      it { is_expected.to have_uid 1010 }
    end

    describe command('getent group deployer') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /deployer:x:(\d+):deployer/ }
    end

  end

end