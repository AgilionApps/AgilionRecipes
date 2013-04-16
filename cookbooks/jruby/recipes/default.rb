# Install Ruby version defined in vagrant file and set as default.
rvm_user_settings = node['rvm']['user_installs'].detect{|u| u['user'] == 'vagrant'}
ruby_version = rvm_user_settings['default_ruby'] || 'jruby-1.7.3'
ruby_and_gemset = "#{ruby_version}@vagrant"

package 'openjdk-7-jre' do
  action :install
end

rvm_default_ruby ruby_and_gemset do
  action :create
  user 'vagrant'
end

rvm_shell 'bundle' do
  cwd '/vagrant'
  user 'vagrant'
  ruby_string ruby_and_gemset
  code 'bundle'
end
