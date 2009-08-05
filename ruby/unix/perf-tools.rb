
commands do
  allow :rm
  allow :wget  
end

routines do
  
  install_httperf do
    local do
      unsafely { rm :r, :f, 'httperf-*' }
      wget 'ftp://ftp.hpl.hp.com/pub/httperf/httperf-0.9.0.tar.gz'
      wget 'ftp://ftp.hpl.hp.com/pub/httperf/httperf-0.9.0.tar.gz.md5'
      md5_digest = cat('httperf-0.9.0.tar.gz.md5').first
      raise "File digest does not match" unless file_verified?('httperf-0.9.0.tar.gz', md5_digest, :md5)
      tar 'zxf', 'httperf-0.9.0.tar.gz'
      cd 'httperf-0.9.0'
      configure
      make 
      sudo 'make', 'install'
    end
  end
  
end