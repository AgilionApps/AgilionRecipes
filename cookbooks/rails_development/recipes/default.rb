# Install Ruby version defined in vagrant file and set as default.
rvm_user_settings = node['rvm']['user_installs'].detect{|u| u['user'] == 'vagrant'}
ruby_version = rvm_user_settings['default_ruby'] || 'ruby-1.9.3-p374'
ruby_and_gemset = "#{ruby_version}@vagrant"

rvm_default_ruby ruby_and_gemset do
  action :create
  user 'vagrant'
end

# Install node.js for JS compilation.
package 'nodejs' do
  action :install
end

rvm_shell 'bundle' do
  cwd '/vagrant'
  user 'vagrant'
  ruby_string ruby_and_gemset
  code 'bundle'
end

rvm_shell 'create_databases' do
  cwd '/vagrant'
  user 'vagrant'
  ruby_string ruby_and_gemset
  code 'rake db:create:all'
end

rvm_shell 'migrate_development_database' do
  cwd '/vagrant'
  user 'vagrant'
  ruby_string ruby_and_gemset
  code 'rake db:migrate'
end

rvm_shell 'load_test_db_schema' do
  cwd '/vagrant'
  user 'vagrant'
  ruby_string ruby_and_gemset
  code 'rake db:test:prepare'
end
