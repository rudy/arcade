
commands do
  allow :apt_get, "apt-get", :y, :q
  allow :gem_install, "/usr/bin/gem", "install", :n, '/usr/bin', :y, :V, "--no-rdoc", "--no-ri"
  allow :gem_sources, "/usr/bin/gem", "sources"
  allow :update_rubygems
  allow :thin, "/usr/local/bin/thin", :d, :R, './config.ru', :l, './thin.log', :P, './thin.pid'
end

sinatra_home = "/path/2/sinatra"
routines do
  
  sysupdate do
    script :root do                  
      apt_get "update"               
      apt_get "install", "build-essential", "git-core"
      apt_get "install", "sqlite3", "libsqlite3-dev"
      apt_get "install", "ruby1.8-dev", "rubygems"
      apt_get "install", "apache2-prefork-dev", "libapr1-dev"
      apt_get "install", "libfcgi-dev", "libfcgi-ruby1.8"
      gem_sources :a, "http://gems.github.com"
      gem_install 'rubygems-update'
      update_rubygems
    end
  end
  
  installdeps do
    script :root do
      gem_install "test-spec", "rspec", "camping", "fcgi", "memcache-client"
      gem_install "mongrel"
      gem_install "ruby-openid", :v, "2.0.4" # thin requires 2.0.x
      gem_install "rack", :v, "0.9.1"
      gem_install "macournoyer-thin"         # need 1.1.0 which works with rack 0.9.1
      gem_install "sinatra"
    end
  end


    environment :dev, :stage, :prod do

      startup do      
        adduser :rudy
        authorize :rudy  
      end

      restart do
        after :rudy do
          thin :c, sinatra_home, "restart"
        end
      end
      start do
        after :rudy do
          thin :c, sinatra_home, "start"
        end
      end
      stop do
        after :rudy do
          thin :c, sinatra_home, "stop"
        end
      end


    end

  end