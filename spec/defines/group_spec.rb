# frozen_string_literal: true

require 'spec_helper'

describe 'accounts::group', :type => :define do
  let(:facts) do
    {
      :osfamily => 'Debian',
      :puppetversion => Puppet.version,
    }
  end

  describe 'create new group' do
    let(:title) { 'foogroup' }

    let(:params) do
      {
        :gid   => 2001
      }
    end

    it {
      is_expected.to contain_group('foogroup').with(
        'gid'    => 2001,
        'ensure' => 'present'
      )
    }
  end

  describe 'invalid ensure' do
    let(:title) { 'foo' }

    let(:params) do
      {
      :ensure     => 'whatever'
    }
    end

    it do
      expect do
         is_expected.to compile
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /expects a match for Enum\['absent', 'present'\]/)
    end
  end

  describe 'remove group' do
    let(:title) { 'my_group' }

    let(:params) do
      {
      :ensure   => 'absent'
    }
    end

    it {
      is_expected.to contain_group('my_group').with(
        'ensure' => 'absent'
      )
    }
  end
end