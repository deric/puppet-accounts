require 'spec_helper_acceptance'
require 'pry'

describe 'manage ssh keys', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  context 'ensure keys' do
    let(:pp) do
      <<-EOS
      class {'accounts':
        users => {
          'root' => {
            'purge_ssh_keys' => true,
            'ssh_keys' => {
              'key1' => {
                'type' => 'ssh-rsa',
                'key' => 'AAAA'
              },
              'key2' => {
                'type' => 'ssh-dss',
                'key' => 'BBBB'
              },
            }
          },
        }
      }
      EOS
    end

    it 'install user\'s keys' do
      shell 'echo "ssh-rsa CCCC key3" > /root/.ssh/authorized_keys'
      expect(apply_manifest(pp,
        :catch_failures => false,
        :debug => false,
      ).exit_code).to be_zero
    end

    describe file('/root/.ssh/authorized_keys') do
      it { is_expected.to be_file }
      it { is_expected.to be_readable.by('owner') }
      it { is_expected.not_to be_readable.by('group') }
      it { is_expected.not_to be_readable.by('others') }
    end

    describe command('cat /root/.ssh/authorized_keys | grep key1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /ssh-rsa AAAA key1/ }
    end

    describe command('cat /root/.ssh/authorized_keys | grep key2') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /ssh-dss BBBB key2/ }
    end

    # following key should be purged by puppet
    describe command('cat /root/.ssh/authorized_keys | grep key3') do
      its(:stdout) { is_expected.not_to match /ssh-rsa CCCC key3/ }
      its(:exit_status) { is_expected.to eq 1 }
    end

  end

  context 'use custom key location' do
    let(:yaml) do
<<-EOS
classes:
  - '::accounts'
accounts::users:
  user:
    authorized_keys_file: '/etc/ssh/authorized_keys_user'
    comment: "foo Bar"
    ssh_keys:
      'user':
        type: "ssh-rsa"
        key: "asdjsjgiov"
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
        :debug => false
      ).exit_code).to be_zero
    end

    describe file('/etc/ssh/authorized_keys_user') do
      it { is_expected.to be_file }
      it { is_expected.to be_readable.by('owner') }
      it { is_expected.not_to be_readable.by('group') }
      it { is_expected.not_to be_readable.by('others') }
    end

    describe file('/etc/ssh') do
      it { should be_directory }
      it { should be_readable.by('owner') }
      it { should_not be_readable.by('group') }
      it { should_not be_readable.by('others') }
    end

    describe command('cat /etc/ssh/authorized_keys_user') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match /ssh-rsa asdjsjgiov user/ }
    end
  end
end
