require 'spec_helper_acceptance'
require 'pry'

describe 'accounts defintion', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  context 'basic setup' do
    it 'install accounts' do
      pp = <<-EOS
        class{'accounts':
          groups => {
            'users' => {
              'gid' => 100,
            },
            'puppet' => {
              'gid' => 111,
            }
          },
          users => {
            'john' => {
              'shell'   => '/bin/bash',
              'groups'  => ['users', 'puppet'],
              'ssh_key' => {'type' => 'ssh-rsa', 'key' => 'public_ssh_key_xxx' }
            }
          }
        }
      EOS

      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
   end

   describe file('/home/john') do
     it { should be_directory }
   end
 end

end