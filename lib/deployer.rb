begin
  require 'rubygems'
  gem 'net-ssh', ">= 2.0.10"
rescue LoadError, NameError
end

require 'net/ssh'

module SunRaise
  class Deployer
    def check
      ssh_exec "cd #{current_path}"
      if @ssh_out.last && @ssh_out.last =~ /No such file or directory/
        @ssh_out.pop
        init_deploy
      else
        update
      end

      puts "SSH OUT: \n" + @ssh_out.join("\n")
    end

    def init_deploy
      log_ok "initial deploy.."
      ssh_exec [
        "mkdir -p #{conf[:remote_deploy_lib]}",
        "cd #{conf[:remote_deploy_lib]}",
        "mkdir -p log shared tmp",
        "git clone #{conf[:git_url]} current"
      ]
      log_ok ""

      log_ok "Maked new dirs and cloned repo"
      make_links 'current'
    end

    def update
      last_commit = ssh_exec ["cd #{current_path}", "git log -1 --pretty=format:\"%H\""]
      last_repo_commit = (`git ls-remote #{conf[:git_url]}`).split("\t").first

      if last_commit.strip == last_repo_commit.strip
        log_ok "Nothing to update"
        return
      end

      new_commits = (`git log #{last_commit}..HEAD --pretty=format:"%s"`).split("\n")

      log_ok "New commits: \n    #{new_commits.join "\n    "}"
      new_dir = "pre_release"

      ssh_exec [
        "cd #{current_path}",
        "rm ../#{new_dir} -rf", # if previous deploy was crashed
        "mkdir ../#{new_dir}",  # making pre_resease dir
        "cp -a -p -r `ls --ignore .git -A` ../#{new_dir}", # forking "current" dir
        "mv .git ../#{new_dir}", # moving repo dir
        "cd ../#{new_dir}",
        "git pull origin master"
      ]
      log_ok "Forked, git updated"

      make_links new_dir

      ssh_exec [
        "cd #{deploy_path}", # folder magic :) old current => previous, pre_release => current
        "rm previous2 current2 -rf",
        "mv current current2",
        "mv #{new_dir} current",
        "if [ -d previous ]; then mv previous previous2 -f; fi",
        "mv current2 previous"
      ]
      log_ok "Files magic complite!"
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

      if conf[:project_type] == :rails
        ssh_exec [
          "cd #{File.join deploy_path, dist_dir}",
          "rm logs tmp -rf",
          "mkdir ../shared/logs ../shared/tmp -p",
          "ln -s ../shared/logs logs",
          "ln -s ../shared/tmp tmp"
        ] + links
      end

      log_ok "Maked links"
    end

    def conf
      SunRaise::Config.instance.conf
    end

    def current_path
      File.join conf[:remote_deploy_lib], 'current'
    end

    def deploy_path
      conf[:remote_deploy_lib]
    end

    def log_ok msg
      puts ":: ".color(:green) + "#{msg}"
    end
  end
end
