require 'spec_helper_acceptance'

test_name 'gpasswd extension'

describe 'gpasswd' do
  hoopy_froods = [
    'marvin',
    'arthur',
    'ford',
    'zaphod',
    'trillian'
  ]

  meddling_kids = [
    'fred',
    'daphne',
    'velma',
    'shaggy',
    'scooby'
  ]

  let(:manifest){<<-EOM
      $users = ['#{users.join("','")}']
      $users.each |$user| { user { $user: ensure => 'present' } }
      group { '#{group}': members => $users, gid => #{gid}, system => #{system}, auth_membership => #{auth_membership} }
    EOM
  }

  let(:auth_membership) { true }
  let(:system) { false }
  let(:group) { 'test' }
  let(:gid) { '1111' }

  hosts.each do |host|
    context 'with a sorted list of users' do
      let(:users) { hoopy_froods.sort }

      # Using puppet_apply as a helper
      it 'should work with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, {:catch_changes => true})
      end

      it 'should have populated the group' do
        group_members = on(host, "getent group #{group}").output.strip.split(':').last.split(',')

        expect(group_members - users).to be_empty
      end
    end

    context 'with an unsorted list of users' do
      let(:users) { hoopy_froods - [hoopy_froods.last] }

      # Using puppet_apply as a helper
      it 'should work with no errors' do
        apply_manifest_on(host, manifest, {
          :catch_failures => true,
          :debug          => false,
        })
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, {
          :catch_changes => true,
          :debug         => false,
        })
      end

      it 'should have populated the group' do
        group_members = on(host, "getent group #{group}").output.strip.split(':').last.split(',')

        expect(group_members - users).to be_empty
      end
    end

    context 'when replacing existing users' do
      let(:users) { meddling_kids }

      # Using puppet_apply as a helper
      it 'should work with no errors' do
        apply_manifest_on(host, manifest, {
          :catch_failures => true,
          :debug          => false,
        })
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, {
          :catch_changes => true,
          :debug         => false,
        })
      end

      it 'should have populated the group' do
        group_members = on(host, "getent group #{group}").output.strip.split(':').last.split(',')

        expect(group_members - users).to be_empty
      end
    end

    context 'when adding all users' do
      let(:users) { hoopy_froods }

      # Using puppet_apply as a helper
      it 'should work with no errors' do
        apply_manifest_on(host, manifest, {
          :catch_failures => true,
          :debug          => false,
        })
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, {
          :catch_changes => true,
          :debug         => false,
        })
      end

      it 'should have populated the group' do
        group_members = on(host, "getent group #{group}").output.strip.split(':').last.split(',')

        expect(group_members - (users + meddling_kids)).to be_empty
      end
    end

    context 'when adding system groups' do
      let(:users) { ['user1', 'user2'] }
      let(:system) { true }
      let(:gid) { '333' }

      # Using puppet_apply as a helper
      it 'should work with no errors' do
        apply_manifest_on(host, manifest, {
          :catch_failures => true,
          :debug          => false,
        })
      end
      it 'should be idempotent' do
        apply_manifest_on(host, manifest, {
          :catch_changes => true,
          :debug         => false,
        })
      end

      it 'should have populated the group' do
        group_members = on(host, "getent group #{group}").output.strip.split(':').last.split(',')
        expect(group_members - ['user1','user2']).to be_empty
      end

      it 'should have a GID of 333' do
        group_gid = on(host, "getent group #{group}").output.strip.split(':')[2]
        expect(group_gid).to eq '333'
      end
    end
  end
end