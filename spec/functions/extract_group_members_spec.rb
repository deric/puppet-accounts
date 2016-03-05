#! /usr/bin/env ruby -S rspec
require 'spec_helper'
require 'rspec-puppet'

describe 'extract_group_members' do

  describe 'basic usage ' do
    it 'should raise an error if run with extra arguments' do
      subject.should run.with_params(1, 2, 3, 4).and_raise_error(Puppet::ParseError)
    end

    it 'should raise an error with incorrect type of arguments' do
      subject.should run.with_params(1, 2).and_raise_error(Puppet::ParseError)
    end

    it 'should raise an error when running without arguments' do
      subject.should run.with_params(nil).and_raise_error(Puppet::ParseError)
    end

    it 'should raise an error when given incorrect type' do
      subject.should run.with_params([]).and_raise_error(Puppet::ParseError)
    end
  end

  describe 'extract group members' do
    it 'find groups assignments' do

      users = {
        foo: { 'groups' => ['sudo', 'users']},
        john: { 'groups' => ['bar', 'users']},
      }

      subject.should run.with_params(users, {}).and_return(
        {
          'sudo' => {'members' => [:foo]},
          'bar' => {'members' => [:john]},
          'users' => {'members' => [:foo,:john]},
        }
      )
    end

    it 'skips absent users' do

      users = {
        alice: { 'groups' => ['users']},
        bob: { 'groups' => ['sudo', 'users']},
        tracy: { 'groups' => ['sudo', 'users'], 'ensure' => 'absent'},
      }

      subject.should run.with_params(users, {}).and_return(
        {
          'sudo' => {'members' => [:bob]},
          'users' => {'members' => [:alice, :bob]},
        }
      )
    end
  end
end
