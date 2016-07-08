require 'spec_helper'

describe 'accounts::groups', :type => :class do

  describe 'invalid parameters' do
    let(:params){{
      :groups => ['foo'],
      :manage => true,
    }}

    it do
      expect {
         is_expected.to compile
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /is not a Hash/)
    end
  end

  describe 'create multiple user' do
    let(:params){{
      :groups => {
        'www-data' => {'gid' => 33},
        'users' => {'gid' => 100},
        },
      :manage => true,
    }}

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_group('www-data').with(
      'gid'    => 33,
      'ensure' => 'present'
    )}

    it { is_expected.to contain_group('users').with(
      'gid'    => 100,
      'ensure' => 'present'
    )}
  end
end
