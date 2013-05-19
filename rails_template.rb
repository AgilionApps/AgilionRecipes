post_install_commands = []
@cucumber = false

##
# Standard Gems
#
gem 'has_scope'
gem 'kaminari'
gem 'unicorn'

gem_group :development, :test do
  gem 'debugger'
  gem 'rspec-rails'
  gem 'fabrication'
end

gem_group :development do
  gem 'foreman'
end

##
# Interactively Install Gems
#
if yes?('Use Omni-auth for auth?')
  gem 'omniauth'
elsif yes?('Use Devise for auth?')
  gem 'devise'
end

if yes?('Use Backbone.js?')
  gem 'backbone-on-rails'
  gem 'backbone-support'
  post_install_commands << 'rails g backbone:install -j'
  #TODO: Setup backbone file structures with .gitkeeps, js requires.
end

if yes?('Use Ember.js?')
  gem 'ember-rails'
  gem 'active_model_serializers'
end


if yes?('Use cucumber?')
  @cucumber = true
  gem_group :test do
    gem 'cucumber-rails', :require => false
    gem 'database_cleaner'
  end
  post_install_commands << 'rails g cucumber:install'
end

if yes?('Use Boostrap?')
  gem 'bootstrap-sass'
  create_file 'app/assets/stylesheets/main.css.scss' do
    <<-SCSS
@import 'bootstrap'; // Imports bootstrap to allow mixins and extends.

#app {

}
    SCSS
  end
end

##
# Add common files to git ignore.
#
append_to_file '.gitignore' do
  %W[
    /config/database.yml
    /cookbooks
    .vagrant
  ].join("\n")
end

##
# Add Fabrication to generators
#
inject_into_file 'config/application.rb', before: '  end' do
  <<-CONFIG

    # Generate fabrication fixtures when generating model
    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.fixture_replacement :fabrication
    end

  CONFIG
end

##
# Remove default README, replace with custom info
#
remove_file 'README'
remove_file 'README.rdoc'
create_file 'README.md' do
  <<-RDOC

# #{@app_name}

Application developed by [Agilion Apps](http://agilionapps.com/)

## Development Setup

Development of the application was done using [Vagrant](http://www.vagrantup.com/).
Follow these steps to get a Vagrant virtual machine up and running.

1. Install Vagrant and VirtualBox. See instructions at [vagrantup.com](http://docs.vagrantup.com/v1/docs/getting-started/index.html)
2. Install Berkshelf for managing chef cookbooks: `gem install berkshelf`
3. Install vagrant berkshelf plugin: `vagrant plugin install vagrant-berkshelf`
4. Setup the VM: `vagrant up`
5. SSH into VM: `vagrant ssh`

From your host you can now use:

* `vagrant suspend` and `vagrant resume` to quickly pause and re-open your VM.
* `vagrant halt` to shutdown your VM, `vagrant up` to re-boot it.
* `vagrant destroy` to shutdown and delete your VM and free up disk space, `vagrant up` to re-create.
* `vagrant reload` to restart and re-provision your VM.

## Development Commands

All development commands such as installing gems and running database
migrations must be done from within the Virtual Machine:

1. SSH into VM: `vagrant ssh`
2. Change into working directory: `cd /vagrant`
3. Startup Rails server: `rails s`
4. Startup Rails console: `rails c`

## Running Automated Tests

The application has a number of unit tests (RSpec) #{"and integration tests
(Cucumber)" if @cucumber} that should be run after making changes to the application
and before deploying.

1. SSH into VM: `vagrant ssh`
2. Change into working directory: `cd /vagrant`
2. Setup test database: `rake db:test:prepare`
4. Run unit tests: `rspec`
#{'5. Run integration tests: `cucumber`' if @cucumber}

  RDOC
end

##
# Add default chef config file.
#
create_file 'Berksfile' do
  <<-CHEF
site :opscode

cookbook 'apt'
cookbook 'build-essential'
cookbook 'postgresql'

cookbook 'rvm',
  github: 'fnichol/chef-rvm'

cookbook 'postgres_vagrant',
  github: 'AgilionApps/AgilionRecipes',
  rel: 'cookbooks/postgres_vagrant',
  ref: '0.4.0'

cookbook 'standard_packages',
  github: 'AgilionApps/AgilionRecipes',
  rel: 'cookbooks/standard_packages',
  ref: '0.4.0'

cookbook 'rails_development',
  github: 'AgilionApps/AgilionRecipes',
  rel: 'cookbooks/rails_development',
  ref: '0.4.0'
  CHEF
end



##
# Add default vagrant config file.
#
create_file 'Vagrantfile' do
  password = [*('a'..'z')].sample(20).join
  <<-VAGRANT
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = 'ruby_base'
  config.vm.box_url = 'https://www.dropbox.com/s/47tb2867l7jfwok/ruby_base.box'

  config.vm.network :private_network, ip: '10.10.10.10'
  config.vm.network :forwarded_port, guest: 3000, host: 3001

  config.vm.synced_folder '.', '/vagrant', nfs: true

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end

  config.berkshelf.enabled = true

  # Provision with chef (solo)
  config.vm.provision :chef_solo do |chef|
    chef.add_recipe 'apt'
    chef.add_recipe 'build-essential'
    chef.add_recipe 'postgres_vagrant'
    chef.add_recipe 'rvm::vagrant'
    chef.add_recipe 'rvm::system_install'
    chef.add_recipe 'standard_packages'
    chef.add_recipe 'rails_development::postgres'

    chef.json = {
      'postgresql' => {
        'password' => { 'postgres' => '#{password}' }
      },
      'rvm' => {
        'default_ruby' => '2.0.0'
      }
    }
  end

end
  VAGRANT
end


##
# Add default unicorn config files for Heroku.
#
create_file 'config/unicorn.rb' do
  <<-UNICORN
    worker_processes 3
    timeout 15
    preload_app true

    before_fork do |server, worker|

      Signal.trap 'TERM' do
        puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
        Process.kill 'QUIT', Process.pid
      end

      defined?(ActiveRecord::Base) and
        ActiveRecord::Base.connection.disconnect!
    end

    after_fork do |server, worker|

      Signal.trap 'TERM' do
        puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
      end

      defined?(ActiveRecord::Base) and
        ActiveRecord::Base.establish_connection
    end
  UNICORN
end

##
# Add default Procfile for Heroku.
#
create_file 'Procfile' do
  'web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb'
end

##
# Print final setup instructions.
#
puts <<-INSTRUCTIONS

Application #{@app_name} generated at #{@app_path}.

Please boot this application's vagrant machine with 'vagrant up'.
This will take approx 20-40 minutes depending on your hardware.

Once booted ssh to the server with 'vagrant ssh' and execute the following:

#{post_install_commands.join("\n")}

Have Fun!
INSTRUCTIONS
