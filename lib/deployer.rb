begin
  require 'rubygems'
  gem 'net-ssh', ">= 2.0.10"
rescue LoadError, NameError
end

require 'net/ssh'

module SunRaise
  # working horse
  class Deployer
    
    def go!
      return if conf[:help]
      return destroy_existen! if conf[:destroy]
      if !conf[:remake] && initiated?
        update
      else
        init_deploy
      end

      callbacks :after

      puts "SSH OUT: \n" + @ssh_out.join("\n") if conf[:verbose]
    end

    def init_deploy
      destroy_existen! if conf[:remake]
      log_ok "initial deploy.."
      ssh_exec [
        "mkdir -p #{deploy_path}",
        "cd #{deploy_path}",
        "mkdir -p log shared tmp",
        "git clone #{conf[:git_url]} current"
      ]
      log_ok "Created dir and cloned repo"
      
      test_rails_app! 'current' if conf[:test_rails_app]
      auto_migrate! 'current' if conf[:auto_migrate]

      log_ok "Made new dirs and cloned repo"
      make_links 'current'
    end

    def update
      
      last_commit = ssh_exec ["cd #{current_path}", "git log -1 --pretty=format:\"%H\""]
      last_repo_commit = (`cd #{conf[:local_project_path]} && git ls-remote #{conf[:git_url]}`).split("\t").first

      if !conf[:force] && last_commit.strip == last_repo_commit.strip
        log_ok "Nothing to update"
        return
      end

      new_commits = (`cd #{conf[:local_project_path]} && git log #{last_commit}..HEAD --pretty=format:"%s"`).split("\n")

      log_ok "New commits: \n    #{new_commits.join "\n    "}"
      @new_dir = "pre_release"
      
      ssh_exec [
        "cd #{deploy_path}",
        "rm #{@new_dir} .git_temp previous2 current2 -rf", # if previous deploy was crashed
        "mv current/.git .git_temp", # moving repo dir
        "cp current #{@new_dir} -r", # clone sitedir without .git
        "mv .git_temp #{@new_dir}/.git", # move git in pre_release folder
      ]

      ssh_exec (conf[:shared_dirs] + conf[:linked_dirs]).map {|dir| "rm #{deploy_path}/#{@new_dir}/#{dir}" }

      ssh_exec [
        "cd #{@new_dir}",
        "git reset HEAD --hard",
        "git pull origin master"
      ]

      log_ok "Forked, git updated"

      make_links @new_dir

      test_rails_app! @new_dir if conf[:test_rails_app]
      auto_migrate! @new_dir if conf[:auto_migrate]
      
      release! if conf[:release]
    end

    def release!
      ssh_exec [
        "cd #{deploy_path}", # folder magic :) old current => previous, pre_release => current
        "mv current current2",
        "mv #{@new_dir} current",
        "if [ -d previous ]; then mv previous previous2 -f; fi",
        "mv current2 previous"
      ]
      log_ok "Released!"
    end

    private
    def ssh_exec command
      command = command.join " && " if command.is_a? Array
      puts ">>>>".color(:cyan) + " #{command}" if conf[:verbose]
      @ssh_ist ||= Net::SSH.start conf[:remote_host], conf[:remote_user]
      @ssh_out ||= []
      @ssh_out << @ssh_ist.exec!(command)
      @ssh_out.last
    end

    def make_links dist_dir
      links = []
      conf[:shared_dirs].each do |link_to, dir|
        links << "rm #{dir} -rf"
        links << "mkdir #{deploy_path}/shared/#{dir} -p"
        links << "ln -s #{deploy_path}/shared/#{link_to} #{dir}"
      end

      conf[:linked_dirs].each do |dir|
        links << "rm #{dir} -rf"
        links << "mkdir #{deploy_path}/#{dir} -p"
        links << "ln -s #{deploy_path}/#{dir} #{dir}"
      end

      ssh_exec ["cd #{File.join deploy_path, dist_dir}"] + links
      @ssh_out.each {|m| puts m}
      log_ok "Made links"
    end

    def initiated?
      ssh_exec "cd #{current_path}"
      last_msg = @ssh_out.pop
      !(last_msg && last_msg =~ /No such file or directory/)
    end

    def destroy_existen!
      log_ok "Removing existen deploy dir"
      ssh_exec "rm #{deploy_path} -rf"
    end

    def test_rails_app! dir
      @app_about ||= rails_app_about dir
      if !@app_about.index('Application root')
        if !@app_about.index('Database schema version')
          log_error "Rails app test fail"
        else
          log_error "Rails app test: Database didn't configurated"
        end
          puts @app_about
          log_error "Deploy aborted, use " + "ssh #{conf[:remote_user]}@#{conf[:remote_host]}".italic + " to fix it"
          exit
      else
        log_ok "Rails app successfully tested"
      end
    end

    def auto_migrate! dir
      @app_about ||= rails_app_about dir
      matches = @app_about.match(/Database schema version\s+ ([0-9]+)/)
      remote_magration_version = matches && matches.size > 0 && matches[1] || 0
      local_about = `#{File.join conf[:local_project_path], 'script', 'about'}`
      local_migration_version = local_about.match(/Database schema version\s+ ([0-9]+)/)[1]
      if remote_magration_version == local_migration_version
        msg_ok "No new migrations"
      else
        log_ok "Rinning rake db:migrate"
        puts ssh_exec ["cd #{File.join deploy_path, dir}", "rake db:migrate RAILS_ENV=production"] # run migrations
      end
    end

    def rails_app_about dir
      ssh_exec "RAILS_ENV=production " + File.join(deploy_path, dir, 'script', 'about') # run script/about
    end

    def conf
      SunRaise::Config.instance.conf
    end

    def callbacks name
      c = SunRaise::Config.instance.callbacks

      if c[name].class == Proc
        instance_eval &c[name]
      end
    end

    def current_path
      File.join conf[:deploy_to], 'current'
    end

    def deploy_path
      conf[:deploy_to]
    end

    def app_path
      File.join deploy_path, (conf[:release] ? 'current' : 'pre_release' )
    end

    def log_ok msg
      puts ":: ".color(:green) + "#{msg}".bright
    end

    def log_error msg
      puts "!! ".bright.color(:red) + "#{msg}".bright
    end

  end
end

