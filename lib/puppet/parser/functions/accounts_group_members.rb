# frozen_string_literal: true

module Puppet::Parser::Functions
  newfunction(:accounts_group_members, :type => :rvalue, :doc => <<-EOS
    From Hash of all users and their configuration assign users to group definitions
    given as second argument
    an optional 3rd argument are the default groups for all users
EOS
             ) do |args|

    if args.size != 2 and args.size != 3
      raise(Puppet::ParseError, "accounts_group_members(): Wrong number of args, given #{args.size}, accepts 2 or 3")
    end

    if args[0].class != Hash or args[1].class != Hash
      raise(Puppet::ParseError, "accounts_group_members(): first two arguments must be a Hash, you passed a " + args[0].class.to_s + " and "+ args[1].class.to_s)
    end
    if args.size == 3 and args[2].class != Array
      raise(Puppet::ParseError, "accounts_group_members(): last argument must be an Array, you passed a " + args[2].class.to_s)
    end

    # assign `user` to group `g`
    assign_helper = lambda do |res, g, user|
      unless res.key?(g) # create group if not defined yet
        res[g] = {'members' => [], 'before' => []}
      else
        res[g]['members'] = [] unless res[g].key?('members')
        res[g]['before'] = [] unless res[g].key?('before')
      end
      unless user.nil?
        res[g]['members'] << user unless res[g]['members'].include? user
        res[g]['before'] << "User[#{user}]"
      end
    end

    res = args[1].clone
    args[0].each do |user, val|
      # don't assign users marked for removal to groups
      next if val.key? 'ensure' and val['ensure'] == 'absent'
      val['primary_group'] = user.to_s unless val.key? 'primary_group'
      val['manage_group'] = true unless val.key? 'manage_group'
      if val['manage_group']
        g = val['primary_group']
        # no need to assign user to his primary group
        assign_helper.call(res, g, nil)
        if val.key? 'gid'
          res[g]['gid'] = val['gid'] # manually override GID
        end
      end
      if val.key? 'groups'
        val['groups'].each do |g|
          assign_helper.call(res, g, user)
        end
      elsif args.size == 3
        args[2].each do |g|
          assign_helper.call(res, g, user)
        end
      end
    end
    res
  end
end
