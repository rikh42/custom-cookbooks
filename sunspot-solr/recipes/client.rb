include_recipe "deploy"

node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'rails'
    Chef::Log.debug("Skipping sunspot-solr::client as application #{application} is not a Rails app")
    next
  end

  execute "restart Rails app #{application}" do
    cwd deploy[:current_path]
    command "touch tmp/restart.txt"
    action :nothing
  end
 
  solr_server = node[:scalarium][:roles][:solr][:instances].collect{|instance, names| names["private_dns_name"]}.first

  template "#{deploy[:current_path]}/config/sunspot.yml" do
    source "sunspot.yml.erb"
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables :host => solr_server

    notifies :run, resources(:execute => "restart Rails app #{application}")

    only_if do
      File.directory?("#{deploy[:deploy_to]}/current")
    end
  end
end
