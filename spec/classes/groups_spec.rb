require 'spec_helper'

describe 'accounts::groups', :type => :class do

  describe 'invalid parameters' do
    let(:params){{
      :groups => ['foo'],
      :manage => true,
    }}

    it do
      expect {
        should compile
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

    it { should compile.with_all_deps }
    it { should contain_group('www-data').with(
      'gid'    => 33,
      'ensure' => 'present'
    )}

    it { should contain_group('users').with(
      'gid'    => 100,
      'ensure' => 'present'
    )}
  end
end
