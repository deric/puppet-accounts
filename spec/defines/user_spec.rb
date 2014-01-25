require 'spec_helper'

describe 'accounts::user' do

  describe 'create new user' do
    let(:title) { 'foobar' }
    let(:owner) { 'foobar' }
    let(:group) { 'foobar' }
    let(:params){{
      :uid => 1001,
      :gid => 1001,
    }}

    it { should contain_user('foobar').with(
      'uid' => 1001,
      'gid' => 1001
    )}

    it { should contain_group('foobar').with(
      'gid' => 1001
    )}

    it { should contain_file('/home/foobar').with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it { should contain_file('/home/foobar/.ssh').with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it { should contain_file('/home/foobar/.ssh/authorized_keys').with({
      'ensure'  => 'present',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0600'
    }) }
  end

  describe 'create new user without specified uid' do
    let(:title) { 'foobar' }
    let(:owner) { 'foobar' }
    let(:group) { 'foobar' }

    it { should contain_file('/home/foobar').with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it { should contain_file('/home/foobar/.ssh').with({
      'ensure'  => 'directory',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0700'
    }) }

    it { should contain_file('/home/foobar/.ssh/authorized_keys').with({
      'ensure'  => 'present',
      'owner'   => owner,
      'group'   => group,
      'mode'    => '0600'
    }) }
  end
end