require 'singleton'
require 'optparse'

module SunRaise
  # configurator class
  class Config

    include Singleton
    attr_accessor :conf, :callbacks

    class << self
      attr_accessor :config_methods
    end

    @config_methods = [
      :remote_host,
      :remote_user,
      :deploy_to,
      :then_link_to,
      :git_url,
      :shared_dirs,
      :linked_dirs,
      :local_project_path,
      :verbose,
      :force,
      :release,
      :remake,
      :test_rails_app,
      :auto_migrate,
      :help,
      :destroy
    ]

    @config_methods.each do |method_name|
      define_method method_name do |value|
        value.strip! if value.class == String
        @conf[method_name] = value
      end
    end

    def initialize
      @callbacks = {:after => ''}
      @conf = {
        :verbose => false, 
        :local_project_path => '.', 
        :release => true, 
        :test_rails_app => true, 
        :auto_migrate => true,
        :help => false
      }
      cl_options
    end
    
    def cl_options
      OptionParser.new do |opts|
        opts.on("-v", "--[no-]verbose", "Run verbosely") do |verbose|
          @conf[:verbose] = verbose
        end
                
        opts.on("-f", "--[no-]force", "Deploy even there are no new commits") do |force|
          @conf[:force] = force
        end

        opts.on("-n", "--no-reelase", "Do not replace 'current' dir and start test server") do |no_release|
          @conf[:release] = !no_release
        end

        opts.on("--remake", "Delete current deploy and make initial deploy") do |remake|
          @conf[:remake] = remake
        end

        opts.on("-d", "--destroy", "Delete current deploy and make initial deploy") do |destroy|
          @conf[:destroy] = destroy
        end

        opts.on("-h", "--help", "Show this help") do |help|
          @conf[:help] = true
          puts opts
        end
      end.parse!
    end

  end

  module PubConf
    SunRaise::Config.config_methods.each do |method_name|
      define_method method_name do |value|
        SunRaise::Config.instance.send method_name, value
      end
    end

    def after_deploy &block
      SunRaise::Config.instance.callbacks[:after] = block
    end
  end
end
