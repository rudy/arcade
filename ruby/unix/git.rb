
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


