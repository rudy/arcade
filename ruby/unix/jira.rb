# JIRA -- An Example of Temporary Infrastructure
# 
# This Rudy configuration demonstrates how to install JIRA
# to an EBS volume.
#

# ----------------------------------------------------------- DEFAULTS --------
# These values are used as defaults for their respective global settings. They
# can be overridden by the command-line global options.  
#
defaults do
  environment :apps
  role :jira
  color true
  auto false
end


# ---------------------------------------------------------  MACHINES  --------
# The machines block describes the 'physical' characteristics of your machines.
machines do
  
  region :'us-east-1' do
    ami 'ami-6f2cc906'               # Cloud Tools, CentOS 32-bit
  end
  
  env :apps do
    role :jira do
      
      user :root
      size 'm1.small'                # EC2 machine type
      disks do                       
        path '/jira' do              # The EBS volume where 
          size 10                    # JIRA will be installed.
          device '/dev/sdr'          
        end
      end
      
    end
  end  

end


# ----------------------------------------------------------- COMMANDS --------
# The commands block defines shell commands that can be used in routines. The
# ones defined here are added to the default list defined by Rye::Cmd (Rudy 
# executes all SSH commands via Rye).
commands do
  allow :java
  allow :wget, 'wget', :q
end


# ----------------------------------------------------------- ROUTINES --------
# The routines block describes the repeatable processes for each machine group.
# To run a routine, specify its name on the command-line: rudy startup
routines do
  
  env :apps do
    role :jira do
      
      # $ rudy restore
      #
      # Run this to launch a new machine instance
      # and restore JIRA from the most recent backup.
      #
      restore do
        before :startup
        adduser :jira
        authorize :jira
        network do                   # Open access to port 8080
          authorize 8080             # for your local machine 
        end                          
        disks do                     # Create a volume from the
          restore "/jira"            # most recent snapshot
        end
        after :start_jira
      end  

      # $ rudy install
      #
      # Run this once, to setup JIRA the first time. 
      #
      install do
        before :startup
        adduser :jira
        authorize :jira
        network do                   # Open access to port 8080
          authorize 8080             # for your local machine 
        end
        disks do                     # Create an EBS volume where
          create "/jira"             # JIRA will be installed.
        end
        remote :root do
          disable_safe_mode          # Allow file globs and tildas.

          raise "JIRA is already installed" if file_exists? '/jira/app'

          jira_archive = "atlassian-jira-standard-3.13.5-standalone.tar.gz"
          uri = "http://www.atlassian.com/software/jira/downloads/binary"
          wget "#{uri}/#{jira_archive}" unless file_exists? jira_archive

          cp jira_archive, '/jira/jira.tar.gz' 
          cd '/jira'
          mkdir :p, '/jira/indexes', '/jira/attachments', '/jira/backups'
          tar :x, :f, 'jira.tar.gz'
          mv 'atlassian-jira-*', 'app'
          chown :R, 'jira', '/jira'
          ls :l
        end
        after :start_jira
      end
  
      shutdown do
        before :stop_jira, :archive
        disks do 
          destroy "/jira"
        end
      end
    
      start_jira do
        remote :jira do
          cd '/jira/app'
          sh 'bin/startup.sh'
        end
      end
  
      stop_jira do
        remote :jira do
          cd '/jira/app'
          sh 'bin/shutdown.sh'
        end
      end
  
      archive do
        disks do
          archive "/jira"
        end
      end
      
      authuser do
        authorize :jira
      end
      
    end
  end
  
end

