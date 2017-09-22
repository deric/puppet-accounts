require 'puppet/provider/group/groupadd'

Puppet::Type.type(:group).provide :gpasswd, :parent => Puppet::Type::Group::ProviderGroupadd do
  require 'shellwords'

  desc <<-EOM
    Group management via `gpasswd`. This allows for local group
    management when the users exist in a remote system.
  EOM

  commands  :addmember => 'gpasswd',
            :delmember => 'gpasswd'

  has_feature :manages_members unless %w{HP-UX Solaris}.include? Facter.value(:operatingsystem)
  has_feature :libuser if Puppet.features.libuser?

  def addcmd
    # This pulls in the main group add command should the group need
    # to be added from scratch.
    cmd = Array(super.map{|x| x = "#{x}"}.shelljoin)

    if @resource[:members]
      cmd += @resource[:members].map{ |x|
        [ command(:addmember),'-a',x,@resource[:name] ].shelljoin
      }
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
    if @resource.allowdupe? && (param == :gid)
      cmd << "-o"
    end
    cmd << @resource[:name]

    cmd
  end

  def members
    getinfo(true) if @objectinfo.nil?
    retval = @objectinfo.mem

    if !@resource[:auth_membership] && (@resource[:members] - @objectinfo.mem).empty?
      retval = @resource[:members]
    end

    retval.sort
  end

  def members_insync?(is, should)
    Array(is).uniq.sort == Array(should).uniq.sort
  end

  def members=(members)
    cmd = []
    to_be_added = members.dup
    if @resource[:auth_membership]
      to_be_removed = @objectinfo.mem - to_be_added
      to_be_added = to_be_added - @objectinfo.mem

      !to_be_removed.empty? && cmd += to_be_removed.map { |x|
        [ command(:addmember),'-d',x,@resource[:name] ].shelljoin
      }
    else
      to_be_added = to_be_added | @objectinfo.mem
    end

    !to_be_added.empty? && cmd += to_be_added.map { |x|
      [ command(:addmember),'-a',x,@resource[:name] ].shelljoin
    }

    mod_group(cmd)
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
        execute(run_cmd, :custom_environment => @custom_environment)
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