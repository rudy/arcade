## ruby-unix
## Subversion routines

## NOTE: I could use help implementing these routines for Subversion!
##       See __END__ for some suggestions. 

routines do
  
  tag do |option, argv|
  end  
  
  delate_tag do |option, argv|
  end
  
end


__END__

## TO BE IMPLEMENTED (take from old Rudy codes)

def create_release(username=nil, msg=nil)
  local_uri, local_revision = local_info
  rtag = find_next_rtag(username)
  release_uri = "#{@base_uri}/#{rtag}"
  msg ||= 'Another Release by Rudy!'
  msg.tr!("'", "\\'")
  cmd = "svn copy -m '#{msg}' #{local_uri} #{release_uri}"
  
  `#{cmd} 2>&1`
  
  release_uri
end

def switch_working_copy(tag)
  raise "Invalid release tag (#{tag})." unless valid_rtag?(tag)
  `svn switch #{tag}`
end


# rel-2009-03-05-user-rev
def find_next_rtag(username=nil)
  now = Time.now
  mon = now.mon.to_s.rjust(2, '0')
  day = now.day.to_s.rjust(2, '0')
  rev = "01"
  criteria = ['rel', now.year, mon, day, rev]
  criteria.insert(-2, username) if username
  tag = criteria.join(Rudy::DELIM)
  # Keep incrementing the revision number until we find the next one.
  tag.succ! while (valid_rtag?("#{@base_uri}/#{tag}"))
  tag
end

def local_info
  ret = Rye.shell(:svn, "info").join
  # URL: http://some/uri/path
  # Repository Root: http://some/uri
  # Repository UUID: c5abe49d-53e4-4ea3-9314-89e1e25aa7e1
  # Revision: 921
  ret.scan(/URL: (http:.+?)\s*\n.+Revision: (\d+)/m).flatten
end

def working_copy?(path)
  (File.exists?(File.join(path, '.svn')))
end

def valid_rtag?(uri)
  ret = `svn info #{uri} 2>&1` || '' # Valid SVN URIs will return some info
  (ret =~ /Repository UUID/) ? true : false
end
