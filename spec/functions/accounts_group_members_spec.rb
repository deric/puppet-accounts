#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'
require 'rspec-puppet'

describe 'accounts_group_members' do
  describe 'basic usage ' do
    it 'should raise an error if run with extra arguments' do
      is_expected.to run.with_params(1, 2, 3, 4).and_raise_error(Puppet::ParseError)
    end

    it 'should raise an error with incorrect type of arguments' do
      is_expected.to run.with_params(1, 2).and_raise_error(Puppet::ParseError)
    end

    it 'should raise an error when running without arguments' do
      is_expected.to run.with_params(nil).and_raise_error(Puppet::ParseError)
    end

    it 'should raise an error when given incorrect type' do
      is_expected.to run.with_params([]).and_raise_error(Puppet::ParseError)
    end
  end

  describe 'extract group members' do
    it 'find groups assignments' do
      users = {
        foo: { 'groups' => ['sudo', 'users']},
        john: { 'groups' => ['bar', 'users']},
      }

      is_expected.to run.with_params(users, {}).and_return(
        {
          'sudo' => {'members' => [:foo], 'before'=> ['User[foo]']},
          'bar' => {'members' => [:john],'before'=> ['User[john]']},
          'users' => {'members' => [:foo,:john], 'before'=> ['User[foo]','User[john]']},
          'foo' => {'members' => [], 'before' => []},
          'john' => {'members' => [], 'before' => []},
        }
      )
    end

    it 'skips absent users' do
      users = {
        alice: { 'groups' => ['users']},
        bob: { 'groups' => ['sudo', 'users']},
        tracy: { 'groups' => ['sudo', 'users'], 'ensure' => 'absent'},
      }

      is_expected.to run.with_params(users, {}).and_return(
        {
          'alice' => {'members' => [], 'before'=> []},
          'bob' => {'members' => [], 'before'=> []},
          'sudo' => {'members' => [:bob], 'before'=> ['User[bob]']},
          'users' => {
            'members' => [:alice,:bob],
            'before'=> ['User[alice]', 'User[bob]']
          },
        }
      )
    end
  end

  describe 'do not extract primary groups' do
    it 'finds group specified by primary_group' do
      users = {
        foo: { 'primary_group' => 'testgroup', 'manage_group' => true},
      }

      is_expected.to run.with_params(users, {}).and_return(
        {'testgroup' => {'members' => [], 'before' => []}}
      )
    end

    it 'finds group with gid' do
      users = {
        foo: { 'primary_group' => 'testgroup',
          'manage_group' => true, 'gid' => 123,
          'before' => []},
      }

      is_expected.to run.with_params(users, {}).and_return(
        {"testgroup"=>{"members"=>[], "before"=>[], "gid"=>123}}
      )
    end
  end
end
