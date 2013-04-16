post_install_commands = []
@cucumber = false

##
# Standard Gems
#
gem 'has_scope'
gem 'kaminari'

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
2. Install the librarian gem: `gem install librarian`
3. Run: `librarian-chef install`
4. Setup the VM: `vagrant up`
5. SSH into VM: `vagrant ssh`

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
#{5. Run integration tests: `cucumber` if @cucumber}

  RDOC
end

##
# Add default chef config file.
#
create_file 'Cheffile' do
  <<-CHEF
site 'http://community.opscode.com/api/v1'

cookbook 'apt'
cookbook 'build-essential'
cookbook 'postgresql'

cookbook 'rvm',
  git: 'https://github.com/fnichol/chef-rvm',
  ref: 'v0.9.0'

cookbook 'postgres_vagrant',
  git: 'https://github.com/AgilionApps/AgilionRecipes',
  path: 'cookbooks/postgres_vagrant',
  ref: '0.2.0'

cookbook 'standard_packages',
  git: 'https://github.com/AgilionApps/AgilionRecipes',
  path: 'cookbooks/standard_packages',
  ref: '0.2.0'

cookbook 'rails_development',
  git: 'https://github.com/AgilionApps/AgilionRecipes',
  path: 'cookbooks/rails_development',
  ref: '0.2.0'
  CHEF
end

run 'librarian-chef install'

##
# Add default vagrant config file.
#
create_file 'Vagrantfile' do
  password = [*('a'..'z')].sample(20).join
  <<-VAGRANT

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|

  config.vm.box = '#{@app_name.downcase.gsub(/\s/,'')}'
  config.vm.box_url = 'http://files.vagrantup.com/precise64.box'

  # Forward default rails server port to host 3001
  config.vm.forward_port 3000, 3001

  # Boost memory to make it a bit quicker, default 512mb
  # config.vm.customize ["modifyvm", :id, "--memory", 2048]

  # Provision with chef (solo)
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = ['cookbooks', 'agilion_recipes/cookbooks']
    chef.add_recipe 'apt'
    chef.add_recipe 'build-essential'
    chef.add_recipe 'postgres_vagrant'
    chef.add_recipe 'rvm::vagrant'
    chef.add_recipe 'rvm::user_install'
    chef.add_recipe 'standard_packages'
    chef.add_recipe 'rails_development::postgres'

    chef.json = {
      'postgresql' => {
        'password' => { 'postgres' => '#{password}' }
      },
      'rvm' => {
        'branch' => 'none',
        'version' => '1.17.10',
        'user_installs' => [{
          'user' => 'vagrant',
          'default_ruby' => 'ruby-1.9.3-p374'
        }],
      }
    }
  end
end

  VAGRANT
end


##
# Print final setup instructions.

puts <<-INSTRUCTIONS

Application #{@app_name} generated at #{@app_path}.

Please boot this application's vagrant machine with 'vagrant up'.
This will take approx 20-40 minutes depending on your hardware.

Once booted ssh to the server with 'vagrant ssh' and execute the following:

#{post_install_commands.join("\n")}

Have Fun!
INSTRUCTIONS
