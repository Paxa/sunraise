require 'erb'
module SunRaise
  # generates sunraise file
  class Generator
    def self.run
      
      # check if ./sunrise already exists
      if File.file? './sunraise'
        puts 'file ' + 'sunraise'.color(:blue) + ' already exists'
        exit
      end
      
      # check .git folder
      unless File.directory? './.git'
        puts 'no ' + '.git'.color(:blue) + ' directory found'
        exit
      end
      
      # detecting origins
      git = `git remote -v | grep origin`
      
      # parse git url
      remote = git.split("\n").first.split(" ")[1]
      
      # parse project name 
      # git@github.com:Paxa/ShopFront.git => ShopFront
      dir = remote.match(/.+@.+:.+\/(.+)\.git/)[1]
      
      # calculate executing path
      bin_dir = File.dirname File.expand_path(__FILE__)
      # open and render template
      template = ERB.new File.new(File.join bin_dir, '../sunraise-template.erb').read
      result_content = template.result(binding)
      # write it to file
      File.open('./sunraise', 'w') {|f| f.write result_content }
      puts 'file ' + 'sunraise'.color(:blue) + ' successfuly created'
      exit
    end
  end
end