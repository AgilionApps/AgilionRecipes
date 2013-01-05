##
# Install PostgreSQL with correct locale settings.
# Requires postgresql cookbooks from opscode.

# Export locale env variables in shell.
template '/etc/profile.d/lang.sh' do
  source 'lang.sh.erb'
  mode '0644'
end

execute 'locale-gen' do
  command 'locale-gen en_US.UTF-8'
end

execute 'dpkg-reconfigure-locales' do
  command 'dpkg-reconfigure locales'
end

# As above script has not been sources, set locales
ENV['LANGUAGE'] = ENV['LANG'] = ENV['LC_ALL'] = 'en_US.UTF-8'

# Install postgres
include_recipe 'postgresql::server'
