require 'spec_helper'

describe 'accounts::group' do

  describe 'create new group' do
    let(:title) { 'foogroup' }

    let(:params){{
      :gid   => 2001
    }}

    it { should contain_group('foogroup').with('gid' => 2001)}
  end
end