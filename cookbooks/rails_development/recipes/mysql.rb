# Create mysql database.yml - should not be checked in.
# Database names will be vagrant_#{ENV}.
template '/vagrant/config/database.yml' do
  user 'root'
  source 'mysql/database.yml.erb'
  variables({
    :password => node['mysql']['server_root_password']
  })
end

include_recipe 'rails_development::default'
