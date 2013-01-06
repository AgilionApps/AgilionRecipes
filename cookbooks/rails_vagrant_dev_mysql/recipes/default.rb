##
# Completes standard Agilion Apps Rails development setup for vagrant boxes.
# Leverages:
#   * RVM
#   * Ruby 1.9.3 (latest)
#   * MySQL
#   * Bundler

# Install latest Ruby 1.9.3 and set as default.
rvm_default_ruby '1.9.3@vagrant' do
  action :create
  user 'vagrant'
end

# Create database.yml - should not be checked in.
# Database names will be vagrant_#{ENV}.
template '/vagrant/config/database.yml' do
  source 'database.yml.erb'
  owner 'vagrant'
  group 'vagrant'
  mode 0744
  variables({
    :password => node['mysql']['password']['postgres']
  })
end

# Install node.js for JS compilation.
package 'nodejs' do
  action :install
end

rvm_shell 'bundle' do
  cwd '/vagrant'
  user 'vagrant'
  ruby_string '1.9.3@vagrant'
  code 'bundle'
end

rvm_shell 'create_databases' do
  cwd '/vagrant'
  user 'vagrant'
  ruby_string '1.9.3@vagrant'
  code 'rake db:create:all'
end

rvm_shell 'migrate_development_database' do
  cwd '/vagrant'
  user 'vagrant'
  ruby_string '1.9.3@vagrant'
  code 'rake db:migrate'
end

rvm_shell 'load_test_db_schema' do
  cwd '/vagrant'
  user 'vagrant'
  ruby_string '1.9.3@vagrant'
  code 'rake db:test:prepare'
end
