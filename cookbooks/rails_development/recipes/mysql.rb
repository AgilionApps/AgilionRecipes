# Create mysql database.yml - should not be checked in.
# Database names will be vagrant_#{ENV}.
template '/vagrant/config/database.yml' do
  source 'mysql/database.yml.erb'
  owner 'vagrant'
  group 'vagrant'
  mode 0744
  variables({
    :password => node['mysql']['server_root_password']
  })
end

include_recipe 'rails_development::default'
