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
      it { should have_uid 1005 }
    end

    describe group('dalp') do
      it { should exist }
      # group ID was not stated explicitly, first available should
      # be used
      it { should have_gid 1001 }
    end

    describe user('deployer') do
      it { should exist }
      it { should have_uid 1010 }
    end

  end

end