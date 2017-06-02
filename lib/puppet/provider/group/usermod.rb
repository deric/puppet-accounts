require 'puppet/provider/group/groupadd'

Puppet::Type.type(:group).provide :usermod, :parent => Puppet::Type::Group::ProviderGroupadd do
  require 'shellwords'

  desc <<-EOM
    Group management via `usermod`. This allows for local group
    management when the users exist in a remote system.
  EOM

  commands  :addmember => 'usermod',
            :delmember => 'usermod',
            :modmember => 'gpasswd' #TODO: is there any alternative?

  has_feature :manages_members unless %w{HP-UX}.include? Facter.value(:operatingsystem)
  has_feature :libuser if Puppet.features.libuser?

  def addcmd
    # This pulls in the main group add command should the group need
    # to be added from scratch.
    cmd = Array(super.map{|x| x = "#{x}"}.shelljoin)

    @resource[:members] and cmd += @resource[:members].map do |x|
      [ command(:addmember),'-aG', @resource[:name], x ].shelljoin
    end

    # A bit hacky way how to update /etc/group in a single shell session
    # Executing [ 'groupadd somegrp', 'gpasswd -a user somegrp'] does not modify
    # /etc/group in current session (two Puppet runs are required).
    # see: https://github.com/deric/puppet-accounts/issues/60
    if @resource[:members] and @resource[:members].size == 1
      user = @resource[:members].first
      cmd << "sed -i.bak -e 's/^\\(#{user}\\)\\(.*\\)/\\1\\2#{user}/g' /etc/group"
    end

    mod_group(cmd)

    # We're returning /bin/true here since the Nameservice classes
    # would execute whatever is returned here.
    return '/bin/true'
  end

  # This is a repeat from puppet/provider/nameservice/objectadd.
  # The self.class.name matches are hard coded so cannot be easily
  # overridden.
  def modifycmd(param, value)
    cmd = [command(param.to_s =~ /password_.+_age/ ? :password : :modify)]
    cmd << flag(param) << value
    if @resource.allowdupe? and (param == :gid)
      cmd << "-o"
    end
    cmd << @resource[:name]

    cmd
  end

  def members
    getinfo(true) if @objectinfo.nil?
    retval = @objectinfo.mem

    if ( @resource[:attribute_membership] == :minimum ) and !retval.nil? and
       !@resource[:members].nil? and (@resource[:members] - retval).empty?
    then
      retval = @resource[:members]
    else
      retval = @objectinfo.mem
    end

    retval.sort
  end

  def members=(members)
    cmd = []
    to_be_added = members.dup.sort!
    if @resource[:attribute_membership] == :minimum
      to_be_added = to_be_added | @objectinfo.mem
      puts "to add: #{to_be_added}"
      not to_be_added.empty? and cmd += to_be_added.map { |x|
        [ command(:addmember),'-aG',@resource[:name],x ].shelljoin
      }
      mod_group(cmd)
    else
      # inclusive strategy
      # assuming that provided members are complete set
      unless to_be_added.empty?
        cmd << [ command(:modmember),'-M',to_be_added.join(','), @resource[:name] ].shelljoin
        mod_group(cmd)
      end
    end
   end


  private

  # This define takes an array of commands to run and executes them in
  # order to modify the group memberships on the system.
  # A useful warning message is output if there is an issue modifying
  # the group but all members that can be added are added. This is an
  # attempt to do the "right thing" without actually breaking a run
  # or creating a whole new type just to override an insignificant
  # segment of the native group type.
  #
  # The run of the type *will* succeed in this case but fail in all
  # others.
  def mod_group(cmds)
    cmds.each do |run_cmd|
      begin
        execute(run_cmd,{:custom_environment => @custom_environment, :failonfail => true, :combine => true})
      rescue Puppet::ExecutionFailure => e
        if $?.exitstatus == 3 then
          Puppet.warning("Modifying #{@resource[:name]} => #{e}")
        else
          raise e
        end
      end
      Puppet.debug("Success: #{run_cmd}")
    end
  end
end
