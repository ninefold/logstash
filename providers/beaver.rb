def load_current_resource
  %w(init_type user group).each do |key|
    new_resource.send(key, node[:logstash][key]) unless new_resource.send(key)
  end
  
  case new_resource.files
  when String
    new_resource.files [Mash.new(:path => new_resource.files)]
  when Array
    new_resource.files.map! do |elm|
      case elm
      when String
        {:path => elm}
      when Hash
        Mash.new(elm)
      else
        elm
      end
    end
  end
end

action :create do

  run_context.include_recipe 'logstash::beaver_dependencies'

  basedir = ::File.join(new_resource.base_dir, new_resource.name)
  conf_file = ::File.join(basedir, 'etc/beaver.conf')
  log_file = ::File.join(new_resource.log_dir, "logstash_beaver_#{new_resource.name}.log")
  pid_file = ::File.join(new_resource.pid_dir, "logstash_beaver_#{new_resource.name}.pid")
  new_args = Mash.new.tap do |mash|
    %w(user group output files).each do |key|
      mash[key] = new_resource.send(key)
    end
  end

  [conf_file, pid_file, log_file].each do |leaf|
    directory ::File.dirname(leaf) do
      recursive true
      owner new_resource.user
      group new_resource.group
    end
  end

  Chef::Log.info '*' * 200
  Chef::Log.info "FILES: #{new_resource.files.inspect}"
  Chef::Log.info "CONF: #{new_resource.output.inspect}"
  
  template conf_file do
    cookbook 'logstash'
    source 'beaver.conf.erb'
    mode 0640
    owner new_resource.user
    group new_resource.group
    variables(
      :conf => new_resource.output.values.first,
      :files => new_resource.files
    )
    notifies :restart, "service[logstash_beaver_#{new_resource.name}]"
  end

  cmd = "beaver -t #{new_resource.output.keys.first} -c #{conf_file}"

  case new_resource.init_type
  when 'upstart'
    template "/etc/init/logstash-beaver-#{new_resource.name}.conf" do
      mode "0644"
      cookbook 'logstash'
      source "logstash_beaver.conf.erb"
      variables(
        :cmd => cmd,
        :group => new_resource.group,
        :user => new_resource.user,
        :log => log_file,
        :supports_setuid => node['logstash']['supports_setuid']
      )
      notifies :restart, "service[logstash_beaver_#{new_resource.name}]"
    end

    service "logstash_beaver_#{new_resource.name}" do
      service_name "logstash-beaver-#{new_resource.name}"
      supports :restart => true, :reload => false
      action [:enable, :start]
      provider Chef::Provider::Service::Upstart
    end
    # TODO: Add runit bit here
  else
    template "/etc/init.d/logstash_beaver" do
      cookbook 'logstash'
      mode "0755"
      source "init-beaver.erb"
      variables(
        :cmd => cmd,
        :pid_file => pid_file,
        :user => node['logstash']['user'],
        :log => log_file,
        :platform => node['platform']
      )
      notifies :restart, "service[logstash_beaver]"
    end

    service "logstash_beaver_#{new_resource.name}" do
      supports :restart => true, :reload => false, :status => true
      action [:enable, :start]
    end

  end

  logrotate_app "logstash_beaver_#{new_resource.name}" do
    cookbook "logrotate"
    path log_file
    frequency "daily"
    postrotate "invoke-rc.d logstash_beaver force-reload >/dev/null 2>&1 || true"
    options [ "missingok", "notifempty" ]
    rotate 30
    create "0440 #{new_args[:user]} #{new_args[:group]}"
  end
end
