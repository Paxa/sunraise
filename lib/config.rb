require 'singleton'

module SunRaise
  class Config

    include Singleton
    attr_accessor :conf

    class << self
      attr_accessor :config_methods
    end

    @config_methods = [
      :remote_host,
      :remote_user,
      :remote_deploy_lib,
      :remote_site_lib,
      :git_url,
      :shared_dirs,
      :project_type
    ]

    @config_methods.each do |method_name|
      define_method method_name do |value|
        value.strip! if value.class == String
        @conf[method_name] = value
      end
    end

    def initialize
      @conf = {:project_type => :rails}
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