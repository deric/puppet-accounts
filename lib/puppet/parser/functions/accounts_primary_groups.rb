module Puppet::Parser::Functions
  newfunction(:accounts_primary_groups, :type => :rvalue, :doc => <<-EOS
Find primary groups and its members
EOS
  ) do |args|

    if args.size != 2
      raise(Puppet::ParseError, "accounts_primary_groups(): Wrong number of args, given #{args.size}, accepts exactly 2 Hashes")
    end

    if args[0].class != Hash
      raise(Puppet::ParseError, "accounts_primary_groups(): argument must be a Hash, you passed a " + args[0].class.to_s + " and "+ args[1].class.to_s)
    end

    # assign `user` to group `g`
    assign_helper = lambda do |res, g, user, primary|
      unless res.key?(g) # create group if not defined yet
        res[g] = {'members' => [], 'require' => []}
      else
        res[g]['members'] = [] unless res[g].key?('members')
        res[g]['require'] = [] unless res[g].key?('require')
      end
      # avoid duplication of users
      res[g]['members'] << user unless res[g]['members'].include? user
      res[g]['require'] << "User[#{user}]" unless primary
    end

    res = {}
    groups = args[1]
    args[0].each do |user, val|
      # don't assign users marked for removal to groups
      next if val.key? 'ensure' and val['ensure'] == 'absent'
      val['primary_group'] = user.to_s unless val.key? 'primary_group'
      val['manage_group'] = true unless val.key? 'manage_group'
      if val['manage_group']
        g = val['primary_group']
        res[g] = groups[g] if groups.key? g
        assign_helper.call(res, g, user, true)
        if val.key? 'gid'
          res[g]['gid'] = val['gid'] # manually override GID
        end
      end
      if val.key? 'groups'
        val['groups'].each do |g|
          # update only existing (primary) groups
          assign_helper.call(res, g, user, false) if res.key?(g)
        end
      end
    end
    res
  end

end
