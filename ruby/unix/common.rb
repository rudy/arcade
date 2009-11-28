commands do
  allow :pkill
end

routines do

  upload do
    remote do |*argv|
      raise "No file specified" if argv.empty?
      file_upload *argv
    end
  end
  
  download do
    remote do |*argv|
      raise "No file specified" if argv.empty?
      dir_download *argv
    end
  end

  gem_install do
    remote do |*argv|
      gem_install *argv
    end
  end
  
  jgem_install do
    remote do |*argv|
      jgem_install *argv
    end
  end

  ps do
    remote do |argv|
      disable_safe_mode
      ps "aux | grep #{argv.first}"
    end
  end

  pkill do
    remote do |argv|
      pkill argv.first
    end
  end
end
