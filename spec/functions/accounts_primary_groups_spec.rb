#! /usr/bin/env ruby -S rspec
require 'spec_helper'
require 'rspec-puppet'

describe 'accounts_primary_groups' do

  describe 'basic usage' do
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

  describe 'extract primary groups' do
    it 'find primary groups with GIDs' do

      users = {
        foo: { 'groups' => ['sudo', 'users']},
        john: { 'groups' => ['bar', 'users'], 'gid' => 500},
      }

      is_expected.to run.with_params(users, {}).and_return(
        {
          'foo' => {'members' => [:foo], 'require'=> [] },
          'john' => {'members' => [:john], 'gid' => 500, 'require'=> []},
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
          'bob' => {'members' => [:bob], 'require' => []},
          'alice' => {'members' => [:alice], 'require' => []},
        }
      )
    end
  end

  describe 'extract also primary groups' do
    it 'finds group specified by primary_group' do
      users = {
        'foo' => { 'primary_group' => 'testgroup', 'manage_group' => true},
        'bar' => { 'primary_group' => 'testgroup', 'manage_group' => false},
      }
      groups = {
        'testgroup' => {
          'members' => [ 'www-data', 'testuser', 'foo' ],
          'gid'     => 500,
        }
      }

      is_expected.to run.with_params(users, groups).and_return(
        {
          'testgroup' => {'members' => ['www-data', 'testuser', 'foo'],
          'gid' => 500, 'require' => []},
        }
      )
    end
  end
end
