
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
  end
  
  ## NOTE: The following are two attempts at telling git which 
  ## private key to use. Both fail. The only thing I could get
  ## to work is modifying the ~/.ssh/config file. 
  ##
  ## This runs fine, but "git clone" still doesn't recognize it
  ## git config --global --replace-all http.sslKey /home/delano/.ssh/id_rsa
  ## rbox.git('config', '--global', '--replace-all', 'http.sslKey', "#{homedir}/.ssh/#{key}")
  ##
  ## "git clone" doesn't care about this either. Note that both these
  ## config attempts come directly from the git-config man page:
  ## http://www.kernel.org/pub/software/scm/git/docs/git-config.html
  ## export GIT_SSL_KEY=/home/delano/.ssh/id_rsa
  ## rbox.setenv("GIT_SSL_KEY", "#{homedir}/.ssh/#{key}")
  
  ## NOT COMPLETE
  ##upload_private_key do 
  ##  before_local :delano do
  ##    homedir = guess_user_home
  ##    unless file_exists?("#{homedir}/.ssh/git-delano_rsa")
  ##      mkdir("#{homedir}/.ssh") unless file_exists?("#{homedir}/.ssh")
  ##      upload("#{ENV['HOME']}/.ssh/git-delano_rsa", "#{homedir}/.ssh/")
  ##      chmod('0600', "#{homedir}/.ssh/git-delano_rsa")
  ##    end
  ##    
  ##    file_append("#{ENV['HOME']}/.ssh/config", "IdentityFile #{homedir}/.ssh/#{key}")
  ##    chmod('0600', "#{homedir}/.ssh/config")
  ##  end
  ##end
  
  # rel-2009-03-05-user-rev
  # rel-2009-03-05-delano-01
  rtag do 
    before_local do
      now = Time.now
      mon, day = now.mon.to_s.rjust(2, '0'), now.day.to_s.rjust(2, '0')
      rev = "01"
      criteria = ['rel', now.year, mon, day, user, rev]
      tag = criteria.join(Rudy::DELIM)
      while git('tag', :l, tag).stdout.to_s == tag && rev.to_i < 50
        rev.succ!
      end
      tag = criteria.join(Rudy::DELIM)
      echo criteria.join(Rudy::DELIM)
    end
  end
  
  
  delete_tag do
    before_local do |option, argv|
      git 'tag', :d, argv.first
      git 'push', 'origin', argv.first
    end
  end


end


__END__



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
  ret = git('tag', :l, tag).stdout.to_s
  (ret.exit_code == 0 && ret == tag)
end



