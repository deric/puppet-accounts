require 'spec_helper'

describe 'accounts::groups' do

  describe 'invalid parameters' do
    let(:params){{
      :groups => ['foo'],
      :manage => true,
    }}

    it do
      expect {
        should compile
      }.to raise_error(Puppet::Error, /is not a Hash/)
    end
  end
end
