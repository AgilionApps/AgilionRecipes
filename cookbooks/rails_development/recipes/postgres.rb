# Create postgres database.yml - should not be checked in.
# Database names will be vagrant_#{ENV}.
template '/vagrant/config/database.yml' do
  source 'postgres/database.yml.erb'
  owner 'vagrant'
  group 'vagrant'
  mode 0744
  variables({
    :password => node['postgresql']['password']['postgres']
  })
end

include_recipe 'rails_development::default'
