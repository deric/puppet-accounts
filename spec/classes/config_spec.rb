# frozen_string_literal: true

require 'spec_helper'

describe 'accounts::config', :type => :class do
  describe 'on Debian' do
    let(:facts) do
      {
      :osfamily => 'Debian',
    }
    end

    let(:params) do
      {
      'options' => {
        'umask' => '077',
      }
    }
    end

    it {
      is_expected.to contain_augeas('Set umask').with({
      incl: '/etc/login.defs',
      lens: 'Login_Defs.lns',
      changes: [ "set UMASK 077"],
    })}
  end

  describe 'on RedHat' do
    let(:facts) do
      {
      :osfamily => 'RedHat',
    }
    end

    let(:params) do
      {
      'options' => {
        'first_uid' => 1010,
        'last_uid'  => 2020,
        'first_gid' => 1050,
        'last_gid'  => 5050,
      }
    }
    end

    it {
      is_expected.to contain_augeas('Set first uid').with({
      incl: '/etc/login.defs',
      lens: 'Login_Defs.lns',
      changes: [ "set UID_MIN 1010"],
    })}

    it {
      is_expected.to contain_augeas('Set last uid').with({
      incl: '/etc/login.defs',
      lens: 'Login_Defs.lns',
      changes: [ "set UID_MAX 2020"],
    })}

    it {
      is_expected.to contain_augeas('Set first gid').with({
      incl: '/etc/login.defs',
      lens: 'Login_Defs.lns',
      changes: [ "set GID_MIN 1050"],
    })}

    it {
      is_expected.to contain_augeas('Set last gid').with({
      incl: '/etc/login.defs',
      lens: 'Login_Defs.lns',
      changes: [ "set GID_MAX 5050"],
    })}
  end
end