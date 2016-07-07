require 'spec_helper'

describe 'accounts::authorized_keys', :type => :define do
  let(:facts) {{
    :osfamily => 'Debian',
    :puppetversion => '3.5.1',
  }}
  let(:user) { 'john' }
  let(:group) { 'john' }
  let(:title) { 'john' }
  let(:file) { "/home/#{user}/.ssh/authorized_keys" }

  let(:params){{
    :real_gid => group,
    :ssh_keys => {},
    :home_dir => "/home/#{user}",
    :purge_ssh_keys => true,
  }}

  context 'when ssh key is given' do
    let(:params){{
      :real_gid => group,
      :ssh_keys => {
        'key1' => {
          'type' => 'ssh-rsa',
          'key' => '1234',
        },
      },
      :home_dir => "/home/#{user}",
      :purge_ssh_keys => true,
    }}

    it { is_expected.to contain_file(file).with(
      'ensure' => 'present',
      'owner'  => user,
      'group'  => group,
      'mode'   => '0600',
    )}

    it { is_expected.to contain_file(file).with_content(/ssh-rsa 1234 key1/) }
  end

  context 'handle multiple keys' do
    let(:params){{
      :real_gid => group,
      :ssh_keys => {
        'key1' => {
          'type' => 'ssh-rsa',
          'key' => 'AAAA',
        },
        'key2' => {
          'type' => 'ssh-rsa',
          'key' => 'BBBB',
        },
      },
      :home_dir => "/home/#{user}",
      :purge_ssh_keys => true,
    }}

    it { is_expected.to contain_file(file).with(
      'ensure' => 'present',
      'owner'  => user,
      'group'  => group,
      'mode'   => '0600',
    )}

    it { is_expected.to contain_file(file).with_content(/ssh-rsa AAAA key1_ssh-rsa/) }
    it { is_expected.to contain_file(file).with_content(/ssh-rsa BBBB key2_ssh-rsa/) }
  end



end