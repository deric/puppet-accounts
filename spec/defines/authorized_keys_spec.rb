# frozen_string_literal: true

require 'spec_helper'

describe 'accounts::authorized_keys', :type => :define do
  let(:facts) do
    {
      :osfamily => 'Debian',
      :puppetversion => '3.5.1',
    }
  end
  let(:user) { 'joe' }
  let(:group) { 'joe' }
  let(:title) { 'joe' }
  let(:file) { "/home/#{user}/.ssh/authorized_keys" }

  # normally home directory is created by user class
  let :pre_condition do
    "file {'/home/#{user}':
       ensure => directory,
       owner  => #{user},
       group  => #{group},
       mode   => '0755',
    }"
  end

  let(:params) do
    {
      :real_gid => group,
      :ssh_keys => {},
      :home_dir => "/home/#{user}",
    }
  end

  context 'when ssh key is given' do
    let(:params) do
      {
      :ssh_dir_group => group,
      :ssh_keys => {
        'key1' => {
          'type' => 'ssh-rsa',
          'key' => '1234',
        },
      },
      :home_dir => "/home/#{user}",
    }
    end

    it {
      is_expected.to contain_file(file).with(
        'ensure' => 'present',
        'owner'  => user,
        'group'  => group,
        'mode'   => '0600'
      )
    }

    it { is_expected.to contain_ssh_authorized_key('key1').with(
      'type' => 'ssh-rsa',
      'key'  => '1234'
    ) }
  end

  context 'handle multiple keys' do
    let(:params) do
      {
      :ssh_dir_group => group,
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
    }
    end

    it {
      is_expected.to contain_file(file).with(
        'ensure' => 'present',
        'owner'  => user,
        'group'  => group,
        'mode'   => '0600'
      )
    }

    it { is_expected.to contain_ssh_authorized_key('key1').with(
      'type' => 'ssh-rsa',
      'key'  => 'AAAA'
    ) }

    it { is_expected.to contain_ssh_authorized_key('key2').with(
      'type' => 'ssh-rsa',
      'key'  => 'BBBB'
    ) }
  end

  context 'pass ssh key options' do
    let(:params) do
      {
      :ssh_keys => {
        'key1' => {
          'type' => 'ssh-rsa',
          'key' => 'AAAA',
          'options' => ['from="pc.sales.example.net"', 'permitopen="192.0.2.1:80"']
        },
      },
      :home_dir => "/home/#{user}",
    }
    end

    it {
      is_expected.to contain_file(file).with(
        'ensure' => 'present',
        'owner'  => user,
        'group'  => group,
        'mode'   => '0600'
      )
    }

    it { is_expected.to contain_ssh_authorized_key('key1').with(
      'type' => 'ssh-rsa',
      'key'  => 'AAAA',
      'options' => ['from="pc.sales.example.net"', 'permitopen="192.0.2.1:80"'],
    ) }
  end
end