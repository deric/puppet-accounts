require 'spec_helper_acceptance'
require 'pry'

describe 'accounts defintion', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  # see https://github.com/deric/puppet-accounts/issues/50
  context 'manage users' do
    let(:pp) do
      <<-EOS
        class {'accounts::users':
          manage => true,
          defaults => {
            shell => '/bin/dash',
          },
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
      expect(apply_manifest(pp,
        :catch_failures => false,
        :debug => false,
      ).exit_code).to be_zero
      # TODO: right now two runs are required
      expect(apply_manifest(pp, :catch_failures => false, :debug => false).exit_code).to be_zero
    end

    describe group('users') do
      it { should exist }
    end

    describe file('/home/dalp') do
      it { should be_directory }
    end

    describe file('/home/deployer') do
      it { should be_directory }
    end

    describe user('dalp') do
      it { should exist }
      it { should have_gid 1005 }
    end

    describe user('deployer') do
      it { should exist }
      it { should have_gid 1010 }
    end

  end

end