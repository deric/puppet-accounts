#!/usr/bin/env rspec
require 'spec_helper'

RSpec::Matchers.define_negated_matcher :excluding, :include

describe Puppet::Type.type(:group).provider(:gpasswd) do
  before do
    allow(described_class).to receive(:command).with(:add).and_return('/usr/sbin/groupadd')
    allow(described_class).to receive(:command).with(:delete).and_return('/usr/sbin/groupdel')
    allow(described_class).to receive(:command).with(:modify).and_return('/usr/sbin/groupmod')
    allow(described_class).to receive(:command).with(:addmember).and_return('/usr/bin/gpasswd')
    allow(described_class).to receive(:command).with(:delmember).and_return('/usr/bin/gpasswd')

    if members
      @resource = Puppet::Type.type(:group).new(:name => 'mygroup', :members => members, :provider => provider)
    else
      @resource = Puppet::Type.type(:group).new(:name => 'mygroup', :provider => provider)
    end
  end

  let(:members) { nil }
  let(:provider) { described_class.new(:name => 'mygroup') }

  describe "#create" do
    it "should add -o when allowdupe is enabled and the group is being created" do
      @resource[:allowdupe] = :true
      @resource[:gid] = '555'
      # This is an unfortunate hack to prevent the parent class from
      # breaking when we execute everything in gpasswd instead of
      # returning the expected string to execute.
      expect(provider).to receive(:execute).with(
        '/bin/true', kind_of(Hash)
      )
      expect(provider).to receive(:execute).with(
        '/usr/sbin/groupadd -g 555 -o mygroup', kind_of(Hash)
      )
      provider.create
    end

    describe "on system that feature system_groups", :if => described_class.system_groups? do
      it "should add -r when system is enabled and the group is being created" do
        @resource[:system] = :true
        expect(provider).to receive(:execute).with(
          '/bin/true', kind_of(Hash)
        )
        expect(provider).to receive(:execute).with(
          '/usr/sbin/groupadd -r mygroup', kind_of(Hash)
        )
        provider.create
      end
    end

    describe "on system that do not feature system_groups", :unless => described_class.system_groups? do
      it "should not add -r when system is enabled and the group is being created" do
        @resource[:system] = :true
        expect(provider).to receive(:execute).with(
          '/bin/true', kind_of(Hash)
        )
        expect(provider).to receive(:execute).with(
          '/usr/sbin/groupadd mygroup', kind_of(Hash)
        )
        provider.create
      end
    end

    describe "when adding additional group members to a new group" do
      let(:members) { ['test_one','test_two','test_three'] }
      it "should pass all members individually as group add options to gpasswd" do
        expect(provider).to receive(:execute).with(
          '/bin/true', kind_of(Hash)
        )
        expect(provider).to receive(:execute).with(
          '/usr/sbin/groupadd mygroup', kind_of(Hash)
        )
        members.each do |member|
          expect(provider).to receive(:execute).with(
            "/usr/bin/gpasswd -a #{member} mygroup", kind_of(Hash)
          )
        end
        provider.create
      end
    end

    describe "when adding additional group members to an existing group with no members" do
      let(:members) { ['test_one','test_two','test_three'] }
      it "should add all new members" do
        allow(Etc).to receive(:getgrnam).with('mygroup')
          .and_return(
            Struct::Group.new('mygroup','x','99999',[])
          )
        @resource[:auth_membership] = :false
        members.each do |member|
          expect(provider).to receive(:execute).with(
            "/usr/bin/gpasswd -a #{member} mygroup", kind_of(Hash)
          )
        end
        provider.create
        provider.members
        provider.members=(@resource.property('members').should)
      end
    end

    describe "when adding additional group members to an existing group with members" do
      let(:members) { ['test_one','test_two','test_three'] }

      it "should add all new members and preserve all existing members" do
        old_members = ['old_one','old_two','old_three','test_three']
        allow(Etc).to receive(:getgrnam).with('mygroup')
          .and_return(
            Struct::Group.new('mygroup','x','99999',old_members)
          )
        @resource[:auth_membership] = :false
        (members | old_members).each do |member|
          expect(provider).to receive(:execute).with(
            "/usr/bin/gpasswd -a #{member} mygroup", kind_of(Hash)
          )
        end
        provider.create
        provider.members
        provider.members=(@resource.property('members').should)
      end
    end

    describe 'when adding exclusive group members to an existing group with members' do
      let(:members) { ['test_one','test_two','test_three'] }

      it 'should add all new members and delete all, non-matching, existing members' do
        old_members = ['old_one','old_two','old_three','test_three']
        allow(Etc).to receive(:getgrnam).with('mygroup')
          .and_return(
            Struct::Group.new('mygroup','x','99999',old_members)
          )

        @resource[:auth_membership] = :true

        (members - old_members).each do |to_add|
          expect(provider).to receive(:execute).with(
            "/usr/bin/gpasswd -a #{to_add} mygroup", kind_of(Hash)
          )
        end
        (old_members - @resource[:members]).each do |to_del|
          expect(provider).to receive(:execute).with(
            "/usr/bin/gpasswd -d #{to_del} mygroup", kind_of(Hash)
          )
        end
        provider.create
        provider.members
        provider.members=(@resource.property('members').should)
      end
    end
  end

  describe "set gid number" do
    it "should add -o when allowdupe is enabled and the gid is being modified" do
      @resource[:allowdupe] = :true
      if Gem::Version.new(Puppet.version) >= Gem::Version.new('5.0.0')
        expect(provider).to receive(:execute).with(
          ['/usr/sbin/groupmod', '-g', 150, '-o', 'mygroup'], kind_of(Hash)
        )
      else
        expect(provider).to receive(:execute).with(
          ['/usr/sbin/groupmod', '-g', 150, '-o', 'mygroup']
        )
      end

      provider.gid = 150
    end
  end
end
