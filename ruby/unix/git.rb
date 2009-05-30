
commands do
  allow :git, "git"
end

routines do
  
  tag do
    before_local do |option, argv|
      msg, suffix = option.message, argv.shift
      msg ||= 'Another release by Rudy'
      suffix ||= git 'rev-parse', '--short', 'HEAD'
      @tagname = Time.now.strftime("%Y-%m-%d-#{user}-#{suffix}")
      git 'tag', :a, @tagname, :m, msg
    end
    after_local do
      # The instance variable set in the previous local block is 
      # available here, but not in remote blocks (and vice versa)
      echo "Created tag: #{@tagname}"
    end
  end
  
end


__END__

## COPY PRIVATE KEY
if @pkey
  # Try when debugging: ssh -vi path/2/pkey git@github.com
  key = File.basename(@pkey)
  homedir = rbox.getenv['HOME']
  rbox.mkdir(:p, :m, '700', '.ssh') rescue nil # :p says keep quiet if it exists              
  if rbox.file_exists?(".ssh/#{key}")
    puts "  Remote private key #{key} already exists".colour(:red)
  else
    rbox.upload(@pkey, ".ssh/#{key}")
  end
  
  ## NOTE: The following are two attempts at telling git which 
  ## private key to use. Both fail. The only thing I could get
  ## to work is modifying the ~/.ssh/config file. 
  ##
  ## This runs fine, but "git clone" doesn't care. 
  ## git config --global --replace-all http.sslKey /home/delano/.ssh/id_rsa
  ## rbox.git('config', '--global', '--replace-all', 'http.sslKey', "#{homedir}/.ssh/#{key}")
  ##
  ## "git clone" doesn't care about this either. Note that both these
  ## config attempts come directly from the git-config man page:
  ## http://www.kernel.org/pub/software/scm/git/docs/git-config.html
  ## export GIT_SSL_KEY=/home/delano/.ssh/id_rsa
  ## rbox.setenv("GIT_SSL_KEY", "#{homedir}/.ssh/#{key}")
  
  if rbox.file_exists?('.ssh/config')
    rbox.cp('.ssh/config', ".ssh/config-previous")
    ssh_config = rbox.download('.ssh/config')
  end
  
  ssh_config ||= StringIO.new
  ssh_config.puts $/, "IdentityFile #{homedir}/.ssh/#{key}"
  puts "  Adding IdentityFile #{key} to #{homedir}/.ssh/config"
  
  rbox.upload(ssh_config, '.ssh/config')
  rbox.chmod('0600', '.ssh/config')
  
end



## CREATE TAGS
# rel-2009-03-05-user-rev
def find_next_rtag(username=nil)
  now = Time.now
  mon = now.mon.to_s.rjust(2, '0')
  day = now.day.to_s.rjust(2, '0')
  rev = "01"
  criteria = ['rel', now.year, mon, day, rev]
  criteria.insert(-2, username) if username
  rev.succ! while valid_rtag?(criteria.join(Rudy::DELIM)) && rev.to_i < 50
  raise TooManyTags if rev.to_i >= 50
  criteria.join(Rudy::DELIM)
end

def delete_rtag(rtag=nil)
  rtag ||= @rtag
  ret = trap_rbox_errors { Rye.shell(:git, 'tag', :d, rtag) }
  raise ret.stderr.join($/) if ret.exit_code > 0 # TODO: retest
  # Equivalent to: "git push origin :tag-name" which deletes a remote tag
  ret = trap_rbox_errors { Rye.shell(:git, "push #{@remote} :#{rtag}") } if @remote
  raise ret.stderr.join($/) if ret.exit_code > 0
  true
end


## REMOTE CHECKOUT
# We need to add the host keys to the user's known_hosts file
# to prevent the git commands from failing when it raises the
# "Host key verification failed." messsage.
if rbox.file_exists?('.ssh/known_hosts')
  rbox.cp('.ssh/known_hosts', ".ssh/known_hosts-previous")
  known_hosts = rbox.download('.ssh/known_hosts')
end
known_hosts ||= StringIO.new
remote = get_remote_uri
host = URI.parse(remote).host rescue nil
host ||= remote.scan(/\A.+?@(.+?)\:/).flatten.first
known_hosts.puts $/, Rye.remote_host_keys(host)
puts "  Adding host key for #{host} to .ssh/known_hosts"

rbox.upload(known_hosts, '.ssh/known_hosts')
rbox.chmod('0600', '.ssh/known_hosts')

trap_rbox_errors {
  rbox.git('clone', get_remote_uri, @path)
}
rbox.cd(@path)
trap_rbox_errors {
  rbox.git('checkout', :b, @rtag)
}



## SUPPORT METHODS
def get_remote_uri
  ret = Rye.shell(:git, "config", "remote.#{@remote}.url")
  ret.stdout.first
end

# Check if the given remote is valid. 
#def has_remote?(remote)
#  success = false
#  (@repo.remotes || []).each do |r|
#  end
#  success
#end

def valid_rtag?(tag)
  # git tag -l tagname returns a 0 exit code and stdout is empty
  # when a tag does not exit. When it does exist, the exit code
  # is 0 and stdout contains the tagname. 
  ret = Rye.shell(:git, 'tag', :l, tag)  
  # change :l to :d for quick deleting above and return true
  # OR: just change to :d to always recreate the same tag
  (ret.exit_code == 0 && ret.stdout.to_s == tag)
end



