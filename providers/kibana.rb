def load_current_resource
  new_resource.conf Chef::Resource::LogstashKibana::DEFAULT_CONFIG.merge(new_resource.conf)
  new_resource.init_type node[:logstash][:init_type] unless new_resource.init_type
end

action :create do
  
  kibana_base = ::File.join(new_resource.base_dir, new_resource.name)
  
  run_context.include_recipe "git"
  run_context.include_recipe "logrotate"
  run_context.include_recipe "build-essential"

  # Install desired ruby
  run_context.include_recipe 'ruby_installer'
  gem_package 'bundler'

  user new_resource.user do
    home new_resource.base_dir
  end

  [new_resource.pid_dir, new_resource.log_dir].each do |dir|
    Chef::Log.debug "Kibana support directory: #{dir}"
    
    directory dir do
      owner new_resource.user
      recursive true
    end
  end

  Chef::Log.debug "Kibana base directory: #{kibana_base}"
    
  directory kibana_base do
    owner new_resource.user
    recursive true
  end

  template "#{kibana_base}/KibanaConfig.rb" do
    cookbook 'logstash'
    source "kibana-config.rb.erb"
    variables :conf => new_resource.conf
    owner new_resource.user
    group new_resource.group
    mode 0644
    notifies :restart, "service[kibana-#{new_resource.name}]"
  end

  app_args = Mash.new
  %w(repository revision user group name conf log_dir disable_bundle_update).each do |key|
    app_args[key] = new_resource.send(key)
  end
  
  application "kibana(#{new_resource.name})" do
    action :deploy
    path kibana_base
    repository app_args[:repository]
    revision app_args[:revision]
    owner app_args[:user]
    group app_args[:group]
    before_migrate do

      execute 'Update kibana gemfile lock' do
        command 'bundle update'
        cwd new_resource.release_path
        not_if{ app_args[:disable_bundle_update] }
      end

      execute 'Install kibana bundle' do
        command 'bundle install --path=vendor/bundle --deployment --without development test cucumber staging --binstubs bundle-bins'
        cwd new_resource.release_path
        user app_args[:user]
        group app_args[:group]
      end
    end
    notifies :restart, "service[kibana-#{app_args[:name]}]"
  end
  
  case new_resource.init_type
  when 'upstart'
    template "/etc/init/logstash-kibana-#{new_resource.name}.conf" do
      cookbook 'logstash'
      source 'logstash_kibana.conf.erb'
      mode 0644
      variables(
        :cmd => "#{::File.join(kibana_base, 'current/bundle-bins/kibana')} start",
        :app_dir => ::File.join(kibana_base, 'current'),
        :user => new_resource.user,
        :group => new_resource.group,
        :log => ::File.join(new_resource.log_dir, "kibana-#{new_resource.name}.log"),
        :supports_setuid => node['logstash']['supports_setuid']
      )
      notifies :restart, "service[kibana-#{new_resource.name}]"
    end
    
    service "kibana-#{new_resource.name}" do
      service_name "logstash-kibana-#{app_args[:name]}"
      supports :restart => true, :reload => false
      action [:enable, :start]
      provider Chef::Provider::Service::Upstart
    end
  when 'runit'
    # TODO: Add runit support
  else
    # TODO: Update this for lwrp support
    template "/etc/init.d/kibana" do
      cookbook 'logstash'
      source "kibana.init.erb"
      owner 'root'
      mode "755"
      variables(
        :kibana_home => kibana_home,
        :user => 'kibana'
      )
    end
  end
  
  logrotate_app "kibana-#{new_resource.name}" do
    cookbook "logrotate"
    path ::File.join(app_args[:log_dir], "kibana-#{app_args[:name]}.log")
    frequency 'daily'
    option %w(missingok notifempty)
    rotate 30
    create "644 #{app_args[:user]} #{app_args[:group]}"
  end

end

action :destroy do
  # stop service
  # delete service file
  # delete base dir
end
