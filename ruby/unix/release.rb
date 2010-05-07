
commands do
  allow :rm
  allow :rake
  allow :gem_push, 'gem', 'push'
end
  
routines do
  
  publish do
    local do |argv|
      abort "Usage: rudy publish TAG" if argv.empty?
      project = File.basename pwd.first
      puts "PUBLISH #{project} #{argv.first}", $/
      git 'tag', argv.first
    end
    after :package_test
    after :publish_docs
    after :publish_github
    after :publish_gem
  end
  
  package_test do
    local do
      puts "Creating Test package..."
      rake file_exists?('VERSION.yml') ? 'build' : 'package'
      rake 'clean'
    end
  end
  
  publish_github do
    local do
      puts 'Pushing to GitHub...'
      git 'tag', :f, 'latest'
      git 'push', '--all'
      git 'push', '--tags'
    end
  end
  
  publish_gem do
    local do
      puts 'Publishing Gemcutter gem...'
      rake "clean"
      rake file_exists?('VERSION.yml') ? 'build' : 'package'
      gemfile = unsafely { ls "pkg/*gem" }
      gem_push gemfile.first
    end
  end

  path do
    local do
      pwd
      cd 'files'
      pwd
      cd '..'
      pwd
    end
  end
  
  publish_docs do
    local do
      rake 'rdoc'
      if file_exists?('doc')
        puts 'Updating Github Pages...'
        git 'checkout', 'gh-pages'
        rm :r, :f, 'files', 'classes' 
        unsafely { mv 'doc/*', '.' }
        rm :r, :f, 'doc'
        git 'add', '.'
        git 'commit', :a, :m, 'Updated docs'
        
        git 'checkout', 'master'
        git 'push'
        rake 'publish:rdoc'
      else
        puts "No docs directory"
      end
    end
  end
  sudotest do
    local do
      ret = sudo 'gem', 'install', 'annoy', :V, '--no-ri', '--no-rdoc'
      sudo :K
    end
  end
  
end