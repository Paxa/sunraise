require 'singleton'
require 'optparse'

module SunRaise
  # configurator class
  class Config

    include Singleton
    attr_accessor :conf

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
      :remake
    ]

    @config_methods.each do |method_name|
      define_method method_name do |value|
        value.strip! if value.class == String
        @conf[method_name] = value
      end
    end

    def initialize
      @conf = {:verbose => false, :local_project_path => '.', :release => true}
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
      end.parse!
    end

  end

  module PubConf
    SunRaise::Config.config_methods.each do |method_name|
      define_method method_name do |value|
        SunRaise::Config.instance.send method_name, value
      end
    end
  end
end
