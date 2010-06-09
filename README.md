
####Sunraise is super fast, rails oriented deploying tool with clean and dead simple configuration
## Usage
Intalling:

    gem install sunraise
    cd /my/project/path
    sunraise generate
    # edit generated sunraise file

Deploying:

    sunraise

## How it works

When you have big repository, deploying via capistrano takes a long time, becouse it fetching all project from git every time. You can go to ssh and do *git pull origin*; it will be very fast.

When you deploying with Sunraise, it doing something like this

    git reset HEAD --hard
    git pull origin master
    # restart web server
    
But also it 

* saves previous release
* make links to shared folders
* checks rails for working (runs script/about)
* and run migrations

## Configuring

Deloy config file contain usual ruby code
Available methods:

* **remote_host** - production servername
* **remote_user** - user to login via ssh
* **deploy_to** - path for deploy folder
* **then_link_to** - link to other place, don't make link if not specified
* **git_url** - repository path, it fetches code from it
* **shared_dirs** - (hash) folders what will be stored outside of project, and will be linking to it (usefull for attachments)
* **linked_dirs** - (array) the same with shared_dirs, but stored in other folder
* **local_project_path** - (default '.') project location
* **verbose** - (bool) if true** - showing ssh comands
* **force** - (bool) deploy even no new commits
* **release** - (bool, default true) don't replace with release folder if false
* **remake** - (bool) removes current deploy folder and initiate again
* **test_rails_app** - (bool, default true) test if rails app working, by running script/about
* **auto_migrate** - run rake db:migrate after deploy
* **destroy** - destroy deploy folder on remote host

parameters 

* destroy
* remake
* verbose
* force
* release

Can be specified by command line, for more information see

    sunraise -h
