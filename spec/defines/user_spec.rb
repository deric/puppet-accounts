require 'spec_helper'

describe 'accounts::user' do

  describe 'create new user' do
    let(:title) { 'foobar' }
    let(:params){{
      :uid => 1001,
      :gid => 1001,
    }}

    it { should contain_user('foobar').with(
        'uid' => 1001,
        'gid' => 1001,
      )
    }
  end
end