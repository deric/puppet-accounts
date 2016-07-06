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

    if args[0].class != Hash and args[1].class != Hash
      raise(Puppet::ParseError, "accounts_group_members(): both must be a Hash, you passed a " + args[0].class.to_s + " and "+ args[1].class.to_s)
    end
    if args.size == 3 and args[2].class != Array
      raise(Puppet::ParseError, "accounts_group_members(): last argument must be an Array, you passed a " + args[2].class.to_s)
    end

    # assign `user` to group `g`
    assign_helper = lambda do |res, g, user|
      unless res.key?(g) # create group if not defined yet
        res[g] = {'members' => [], 'require' => []}
      else
        res[g]['members'] = [] unless res[g].key?('members')
        res[g]['require'] = [] unless res[g].key?('require')
      end
      res[g]['members'] << user
      res[g]['require'] << "User[#{user}]"
    end

    res = args[1].clone
    args[0].each do |user, val|
      # don't assign users marked for removal to groups
      next if val.key? 'ensure' and val['ensure'] == 'absent'
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
    # make sure any primary group is present
    args[0].each do |user, val|
      if val.key? 'primary_group'
        res.delete(val['primary_group'])
      end
    end

    res
  end


end
