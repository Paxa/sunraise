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
      if !conf[:remake] && initiated?
        update
      else
        init_deploy
      end

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
      log_ok ""

      log_ok "Maked new dirs and cloned repo"
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
        "cp current #{@new_dir}", # clone sitedir without .git
        "mv .git_temp #{@new_dir}/.git", # move git in pre_release folder
        "cd #{@new_dir}",
        "git pull origin master"
      ]
      log_ok "Forked, git updated"

      make_links @new_dir
      
            
      release!
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
      conf[:shared_dirs].each do |dir|
        links << "rm #{dir} -rf"
        links << "mkdir ../shared/#{dir} -p"
        links << "ln -s ../shared/#{dir} #{dir}"
      end

      conf[:linked_dirs].each do |dir|
        links << "rm #{dir} -rf"
        links << "mkdir ../#{dir} -p"
        links << "ln -s ../#{dir} #{dir}"
      end

      ssh_exec ["cd #{File.join deploy_path, dist_dir}"] + links

      log_ok "Maked links"
    end

    def conf
      SunRaise::Config.instance.conf
    end

    def current_path
      File.join conf[:deploy_to], 'current'
    end

    def deploy_path
      conf[:deploy_to]
    end

    def log_ok msg
      puts ":: ".color(:green) + "#{msg}".bright
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
  end
end
