require 'spec_helper'

describe 'accounts' do

  let(:params){{
    :manage_users  => true,
    :manage_groups => true,
  }}

  it { should compile.with_all_deps }
  it { should contain_class('accounts::users') }
  it { should contain_class('accounts::groups') }

end