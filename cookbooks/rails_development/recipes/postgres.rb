# Create postgres database.yml - should not be checked in.
# Database names will be vagrant_#{ENV}.
template '/vagrant/config/database.yml' do
  user 'root'
  source 'postgres/database.yml.erb'
  variables({
    :password => node['postgresql']['password']['postgres']
  })
end

include_recipe 'rails_development::default'
