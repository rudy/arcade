commands do
  allow :rake, "/usr/bin/rake"
  allow :rm
end

publish do
  local do
    project = File.basename pwd.first
    puts 'Building docs...'
    rake 'rdoc'
    if file_exists?('doc')
      
      puts 'Updating Github Pages'
      git 'checkout', 'gh-pages'
      
      puts "Updating docs..."
      rm :r, :f, 'files', 'classes' 
      cd 'doc'
      mv ls, '../.'
      cd '..'
      rm :r, :f, 'doc'
      git 'add', 'files', 'classes'
      git 'commit', :a, :m, 'Updated docs'
      
      git 'checkout', 'master'
      git 'push'
    else
      puts "No docs directory"
    end
    rake 'clean'
    git 'tag', :f, 'latest'
    git 'push', '--all'
    git 'push', '--tags'
    puts "Done"
  end
end
