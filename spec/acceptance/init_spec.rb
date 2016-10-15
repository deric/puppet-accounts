require 'spec_helper_acceptance'
require 'pry'

describe 'accounts defintion', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  context 'basic setup' do
    it 'install accounts' do
      pp = <<-EOS
        class{'accounts':
          groups => {
            'users' => {
              'gid' => 100,
            },
            'engineers' => {
              'gid' => 158,
            }
          },
          users => {
            'john' => {
              'shell'   => '/bin/bash',
              'groups'  => ['users', 'engineers'],
              'ssh_key' => {'type' => 'ssh-rsa', 'key' => 'public_ssh_key_xxx' }
            }
          }
        }
      EOS

      expect(apply_manifest(pp, {
        :catch_failures => false,
        :debug          => false,
        }).exit_code).to be_zero
    end

    describe group('john') do
      it { should exist }
    end

    describe file('/home/john') do
      it { should be_directory }
    end

    describe file('/home/john/.ssh') do
      it { should be_directory }
      it { should be_readable.by('owner') }
      it { should_not be_readable.by('group') }
      it { should_not be_readable.by('others') }
    end

    describe file('/home/john/.ssh/authorized_keys') do
      it { should be_file }
      it { should be_readable.by('owner') }
      it { should_not be_readable.by('group') }
      it { should_not be_readable.by('others') }
    end

    describe group('engineers') do
      it { should exist }
      it { should have_gid 158 }
    end

    describe group('users') do
      it { should exist }
      it { should have_gid 100 }
    end

    describe command('groups john') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /engineers/ }
      its(:stdout) { is_expected.to match /users/ }
    end

    describe command('id john') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /158\(engineers\)/ }
      its(:stdout) { is_expected.to match /100\(users\)/ }
    end
  end

  context 'modify user\'s primary_group' do
    let(:pp) do
      <<-EOS
        class {'accounts':
            groups => {
              'testgroup' => {
                'gid' => 800,
                'members' => ['www-data', 'testuser']
              }
            },
            users => {
              'testuser' => {
                'shell'   => '/bin/bash',
                'primary_group' => 'testgroup'
              },
              'www-data' => {
                'home' => '/var/www',
                'shell'   => '/bin/sh',
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

    describe group('testgroup') do
      it { should exist }
      it { should have_gid 800 }
    end

    describe file('/home/testuser') do
      it { should be_directory }
    end

    describe command('awk -F\':\' \'/testgroup/{print $4}\' /etc/group') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /www-data/ }
      its(:stdout) { is_expected.to match /testuser/ }
    end

    describe command('id testuser') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /800\(testgroup\)/ }
    end

    context 'second run' do
      it 'applies manifest' do
        expect(apply_manifest(pp,
          :catch_failures => false,
          :debug => true,
        ).exit_code).to be_zero
      end

      describe command('awk -F\':\' \'/testgroup/{print $4}\' /etc/group') do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match /www-data/ }
        its(:stdout) { is_expected.to match /testuser/ }
      end

    end
  end

end