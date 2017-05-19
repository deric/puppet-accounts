# frozen_string_literal: true

module Puppet::Parser::Functions
  newfunction(:accounts_parent_dir, :type => :rvalue, :doc => <<-EOS
    Return directory from path to file
EOS
             ) do |args|

    if args.size != 1
      raise(Puppet::ParseError, "accounts_group_members(): Wrong number of args, given #{args.size}, accepts 1")
    end

    idx = args[0].rindex('/')
    return args[0][0...idx]
  end
end