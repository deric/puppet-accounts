require 'spec_helper'

describe 'accounts::group', :type => :define do

  let(:facts) {{
    :osfamily => 'Debian',
    :puppetversion => Puppet.version,
  }}

  describe 'create new group' do
    let(:title) { 'foogroup' }

    let(:params){{
      :gid   => 2001
    }}

    it { is_expected.to contain_group('foogroup').with(
      'gid'    => 2001,
      'ensure' => 'present'
    )}
  end

  describe 'invalid ensure' do
    let(:title) { 'foo' }

    let(:params){{
      :ensure     => 'whatever'
    }}

    it do
      expect {
         is_expected.to compile
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /parameter must be 'absent' or 'present'/)
    end
  end

  describe 'remove group' do
    let(:title) { 'my_group' }

    let(:params){{
      :ensure   => 'absent'
    }}

    it { is_expected.to contain_group('my_group').with(
      'ensure' => 'absent'
    )}
  end
end