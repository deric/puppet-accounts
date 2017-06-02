#!/usr/bin/env rspec
require 'spec_helper'

describe Puppet::Type.type(:group).provider(:usermod) do
  before do
    described_class.stubs(:command).with(:add).returns '/usr/sbin/groupadd'
    described_class.stubs(:command).with(:delete).returns '/usr/sbin/groupdel'
    described_class.stubs(:command).with(:modify).returns '/usr/sbin/groupmod'
    described_class.stubs(:command).with(:addmember).returns '/usr/sbin/usermod'
    described_class.stubs(:command).with(:delmember).returns '/usr/sbin/usermod'
    described_class.stubs(:command).with(:modmember).returns '/usr/bin/gpasswd'
  end

  let(:resource) { Puppet::Type.type(:group).new(:name => 'mygroup', :provider => provider) }
  let(:provider) { described_class.new(:name => 'mygroup') }

  describe "#create" do
    it "should add -o when allowdupe is enabled and the group is being created" do
      resource[:allowdupe] = :true
      resource[:gid] = '555'
      # This is an unfortunate hack to prevent the parent class from
      # breaking when we execute everything in gpasswd instead of
      # returning the expected string to execute.
      provider.expects(:execute).with('/bin/true',
        :custom_environment => {},
        :failonfail => true,
        :combine => true)
      provider.expects(:execute).with('/usr/sbin/groupadd -g 555 -o mygroup',
        :custom_environment => {},
        :failonfail => true,
        :combine => true
      )
      provider.create
    end

    describe "on system that feature system_groups", :if => described_class.system_groups? do
      it "should add -r when system is enabled and the group is being created" do
        resource[:system] = :true
        provider.expects(:execute).with('/usr/sbin/groupadd -r mygroup',
          :custom_environment => {},
          :failonfail => true,
          :combine => true
        )
        provider.expects(:execute).with('/bin/true',
          :custom_environment => {},
          :failonfail => true,
          :combine => true)
        provider.create
      end
    end

    describe "on system that do not feature system_groups", :unless => described_class.system_groups? do
      it "should not add -r when system is enabled and the group is being created" do
        resource[:system] = :true
        provider.expects(:execute).with('/bin/true',
          :custom_environment => {},
          :failonfail => true,
          :combine => true)
        provider.expects(:execute).with('/usr/sbin/groupadd mygroup',
          :custom_environment => {},
          :failonfail => true,
          :combine => true
        )
        provider.create
      end
    end

    describe "when adding additional group members to a new group" do
      it "should pass all members individually as group add options to gpasswd" do
        provider.expects(:execute).with('/bin/true',
          :custom_environment => {},
          :failonfail => true,
          :combine => true)
        provider.expects(:execute).with('/usr/sbin/groupadd mygroup',
          :custom_environment => {},
          :failonfail => true,
          :combine => true)
        resource[:members] = ['test_one','test_two','test_three']
        resource[:members].each do |member|
          provider.expects(:execute).with("/usr/sbin/usermod -aG mygroup #{member}",
          :custom_environment => {},
          :failonfail => true,
          :combine => true
          )
        end
        provider.create
      end
    end

    describe "when adding additional group members to an existing group with no members" do
      it "should add all new members" do
        Etc.stubs(:getgrnam).with('mygroup').returns(
          Struct::Group.new('mygroup','x','99999',[])
        )
        resource[:attribute_membership] = 'minimum'
        resource[:members] = ['test_one','test_two','test_three']
        resource[:members].each do |member|
          provider.expects(:execute).with("/usr/sbin/usermod -aG mygroup #{member}",
            {
              :custom_environment => {},
              :failonfail => true,
              :combine => true
            }
          )
        end
        provider.create
        provider.members=(resource[:members])
      end
    end

    describe "when adding additional group members to an existing group with members" do
      it "should add all new members and preserve all existing members" do
        old_members = ['old_one','old_two','old_three','test_three']
        Etc.stubs(:getgrnam).with('mygroup').returns(
          Struct::Group.new('mygroup','x','99999',old_members)
        )
        resource[:attribute_membership] = 'minimum'
        resource[:members] = ['test_one','test_two','test_three']
        (resource[:members] | old_members).each do |member|
          provider.expects(:execute).with("/usr/sbin/usermod -aG mygroup #{member}",
            {:custom_environment => {},
          :failonfail => true,
          :combine => true})
        end
        provider.create
        provider.members=(resource[:members])
      end
    end

    describe "when adding exclusive group members to an existing group with members" do
      it "should add all new members and delete all, non-matching, existing members" do
        old_members = ['old_one','old_two','old_three','test_three']
        members = ['queens','darwin','kings','trinity']
        Etc.stubs(:getgrnam).with('mygroup').returns(
          Struct::Group.new('mygroup','x','1234',old_members)
        )
        resource[:attribute_membership] = :inclusive
        resource[:members] = members
        provider.expects(:execute).with("/usr/bin/gpasswd -M #{members.sort.join(',')} mygroup",
            {:custom_environment => {},
          :failonfail => true,
          :combine => true})
        provider.create
        provider.members=(members)
      end
    end
  end

  describe "#gid=" do
    it "should add -o when allowdupe is enabled and the gid is being modified" do
      resource[:allowdupe] = :true
      provider.expects(:execute).with(['/usr/sbin/groupmod', '-g', 150, '-o', 'mygroup'])
      provider.gid = 150
    end
  end
end

