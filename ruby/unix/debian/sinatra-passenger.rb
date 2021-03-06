commands do
  allow :apt_get, "apt-get", :y, :q
  allow :gem_install, "/usr/bin/gem", "install", :n, '/usr/bin', :y, :V, "--no-rdoc", "--no-ri"
  allow :gem_sources, "/usr/bin/gem", "sources"
  allow :passenger_install_apache2, "passenger-install-apache2-module", '--auto'
  allow :passenger_install_nginx, "passenger-install-nginx-module", '--auto', '--autodownload'
  allow :apache2ctl
  allow :update_rubygems
end


routines do
  
  sysupdate do
    remote :root do                  
      apt_get "update"               
      apt_get "install", "build-essential", "git-core"
      apt_get "install", "sqlite3", "libsqlite3-dev"
      apt_get "install", "ruby1.8-dev", "rubygems"
      apt_get "install", "nginx"
      apt_get "install", "apache2-mpm-prefork", "apache2-prefork-dev", "libapr1-dev"
      apt_get "install", "libfcgi-dev", "libfcgi-ruby1.8"
      gem_sources :a, "http://gems.github.com"
      gem_install 'rubygems-update'
      update_rubygems
    end
  end
  
  installdeps do
    remote :root do
      gem_install "test-spec", "rspec", "camping", "fcgi", "memcache-client"
      gem_install "rake", "passenger"
      passenger_install_apache2
      passenger_install_nginx
      gem_install "rack", :v, "0.9.1"   # 0.9.1 required by sinatra
      gem_install "sinatra"
    end
  end
  
  ## TODO: Add start, stop, restart routines
  
end
