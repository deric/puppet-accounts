if Facter.value(:kernel) == 'Linux'
  Facter.add('salts') do
    confine { File.exist? '/etc/shadow' }
    confine :facterversion do |version|
      Gem::Version.new(version) >= Gem::Version.new('2.0.0')
    end
    # read
    shadow = Facter::Util::Resolution.exec('cat /etc/shadow')
    # split into line array
    lines = shadow.split('\n')
    # create a new hash for {username => salt}
    salts = Hash.new
    setcode do
      # parse every line
      lines.each do |l|
        parts = l.split(':')
        if parts[1].include? "$"
          salts[parts[0]] = parts[1].split('$')[2]
        end
      end
      salts
    end
  end
end
