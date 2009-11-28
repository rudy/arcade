commands do
  allow :bundle_vol, 'ec2-bundle-vol'
  allow :upload_bundle, 'ec2-upload-bundle'
end
 
routines do
  
  # Create an EC2 machine image from a running instance
  #
  # Usage: rudy -b bucket-name bundle-image image-name
  #
  # Requirements:
  # * Amazon EC2 AMI tools must be installed on the remote machine.
  # * Amazon EC2 API tools must be installed on the local machine.
  # * An S3 bucket to store the machine image. 
  # * Amazon account credentials (pk, cert, accesskey, secretkey, and account#)
  # * Rudy 0.9 or greater
  bundle_image do
    remote :root do |argv|
      raise "Must provide an architecture (i386 or x86_64)" if argv[0].nil?
      raise "Must provide an image name" if argv[1].nil?
      raise "Must provide a bucket (-b bucket-name)" if $global.bucket.nil?
      
      setenv 'EC2_HOME', '/usr/local/ec2'
      setenv 'RUBYLIB', '/usr/lib/site_ruby'
      
      pkeyfile = File.basename $global.pkey
      certfile = File.basename $global.cert
      
      file_upload $global.pkey, $global.cert, "/mnt/"
      touch "/root/firstrun"
      
      puts argv[1]
      
      bundle_vol :r, argv[0], :p, argv[1], :k, "/mnt/#{pkeyfile}", :c, "/mnt/#{certfile}", :u, $global.accountnum
      upload_bundle :b, $global.bucket, :m, "/tmp/#{argv[1]}.manifest.xml", :a, $global.accesskey, :s, $global.secretkey

    end
    local do |argv|
      rudy_ec2 :z, $global.zone, 'im', :R, "#{$global.bucket}/#{argv[1]}.manifest.xml"
    end
  end
  
  
end
