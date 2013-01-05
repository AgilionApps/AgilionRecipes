post_install_commands = []


##
# Interactively Install Gems
#
gem 'jquery-rails'
gem 'simple-form'
gem 'pg'

if yes?('Use Omni-auth for auth?')
  gem 'omni-auth'
elsif yes?('Use Devise for auth?')
  gem 'devise'
end

gem_group :development, :test do
  gem 'debugger'
  gem 'rspec-rails'
end

gem_group :development do
  gem 'foreman'
end

gem_group :assets do
  gem 'compass-rails'
  if yes?('Use Boostrap?')
    gem 'bootstrap-sass'
    gem 'compass_twitter_bootstrap', git: 'https://github.com/vwall/compass-twitter-bootstrap.git'
  end
end

if yes?('Use Backbone.js?')
  gem 'backbone-on-rails'
  gem 'backbone-support'
  post_install_commands << 'rails g backbone:install -j'
end


##
# Add common files to git ignore.
#
append_to_file '.gitignore' do
  %W[
    /config/database.yml
    /cookbooks
    .vagrant
  ].join('\n')
end


##
# Remove default README, replace with application name and todo.
#
remove_file 'README'
remove_file 'README.rdoc'
create_file 'README.rdoc' do
  <<-RDOC

# #{@app_name}

By Agilion Apps

## Description

TODO

## Development Setup

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

cookbook 'rvm', git: 'https://github.com/fnichol/chef-rvm'

cookbook 'rails_vagrant_dev', git: 'https://github.com/AgilionApps/AgilionRecipes'
cookbook 'standard_packages', git: 'https://github.com/AgilionApps/AgilionRecipes'
cookbook 'postgres_vagrant', git: 'https://github.com/AgilionApps/AgilionRecipes'
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
    chef.add_recipe 'rails_vagrant_dev'

    chef.json = {
      'postgresql' => {
        'password' => { 'postgres' => '#{password}' }
      },
      'rvm' => {
        'user_installs' => [{ 'user' => 'vagrant' }]
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

#{post_install_commands.join('/n')}

Have Fun!
INSTRUCTIONS
