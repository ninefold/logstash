include_recipe "git"
include_recipe "logrotate"
include_recipe "build-essential"

kibana_base = node['logstash']['kibana']['basedir']
kibana_home = node['logstash']['kibana']['home']
kibana_log_dir = node['logstash']['kibana']['log_dir']
kibana_pid_dir = node['logstash']['kibana']['pid_dir']

# Install ruby
node.default[:ruby_installer][:package_removals] = %w(ruby1.8 ruby1.8-full)
include_recipe 'ruby_installer'

gem_package 'bundler'

if Chef::Config[:solo]
  es_server_ip = node['logstash']['elasticsearch_ip']
else
  es_server_results = discovery_all(
    node['logstash']['elasticsearch_role'],
    :minimum_response_time_sec => false,
    :environment_aware => node['logstash']['discovery']['environment_aware'],
    :empty_ok => false
  )
  unless es_server_results.empty?
    es_server_ip = es_server_results.map do |es_srv|
      es_srv['ipaddress']
    end
  else
    es_server_ip = node['logstash']['elasticsearch_ip'] || '127.0.0.1'
  end
end

es_server_port = node['logstash']['elasticsearch_port'] || 9200

#install new kibana version only if is true
case node['logstash']['kibana']['language'].downcase
when "ruby"

  logstash_kibana 'default' do
    conf(
      'Elasticsearch' => Array(es_server_ip).map{|ip| "#{ip}:#{es_server_port}" },
      'KibanaHost' => node[:ipaddress]
    )
  end

  
  service "kibana" do
    supports :status => true, :restart => true
    action [:enable, :start]
    subscribes :restart, [ "link[#{kibana_home}]", "template[#{kibana_home}/KibanaConfig.rb]", "template[#{kibana_home}/kibana-daemon.rb]" ]
  end
    
  logrotate_app "kibana" do
    cookbook "logrotate"
    path "/var/log/kibana/kibana.output"
    frequency "daily"
    options [ "missingok", "notifempty" ]
    rotate 30
    create "644 kibana kibana"
  end

  server_auth_method = node['logstash']['kibana']['auth']['server_auth_method']
  if server_auth_method
    include_recipe "apache2"
    include_recipe "apache2::mod_proxy"
    include_recipe "apache2::mod_proxy_http"

    if server_auth_method == "basic"
      htpasswd_path     = "#{node['logstash']['basedir']}/kibana/#{kibana_version}/htpasswd"
      htpasswd_user     = node['logstash']['kibana']['auth']['user']
      htpasswd_password = node['logstash']['kibana']['auth']['password']

      execute "add htpasswd file" do
        command "/usr/bin/htpasswd -b #{htpasswd_path} #{htpasswd_user} #{htpasswd_password}"
      end
  
      file htpasswd_path do
        owner node['logstash']['user']
        group node['logstash']['group']
        mode "0755"
      end
    end

    template "#{node['apache']['dir']}/sites-available/kibana" do
      source node['logstash']['kibana']['apache_template']
      variables(:server_name => node['logstash']['kibana']['server_name'],
                :server_hostname => node['logstash']['kibana']['server_hostname'],
                :http_port => node['logstash']['kibana']['http_port'])
    end

    apache_site "kibana", :enabled => true

    service "apache2"
  end
  
when "php"
  
  include_recipe "apache2"
  include_recipe "apache2::mod_php5"
  include_recipe "php::module_curl"

  kibana_version = node['logstash']['kibana']['sha']

  apache_module "php5" do
    action :enable
  end

  apache_site "default" do
    enable false
  end

  directory "#{node['logstash']['basedir']}/kibana/#{kibana_version}" do
    owner node['logstash']['user']
    group node['logstash']['group']
    recursive true
  end

  git "#{node['logstash']['basedir']}/kibana/#{kibana_version}" do
    repository node['logstash']['kibana']['repo']
    reference kibana_version
    action :sync
    user node['logstash']['user']
    group node['logstash']['group']
  end

  if platform? "redhat", "centos", "amazon", "fedora", "scientific"
    arch = node['kernel']['machine']    == "x86_64" ? "64" : ""
    file '/etc/httpd/mods-available/php5.load' do
      content "LoadModule php5_module /usr/lib#{arch}/httpd/modules/libphp5.so"
    end
  end

  link "#{node['logstash']['basedir']}/kibana/current" do
    to "#{node['logstash']['basedir']}/kibana/#{kibana_version}"
    notifies :restart, "service[apache2]"
  end

  template "#{node['apache']['dir']}/sites-available/kibana" do
    source node['logstash']['kibana']['apache_template']
    variables(:docroot => "#{node['logstash']['basedir']}/kibana/current",
              :server_name => node['logstash']['kibana']['server_name'])
  end

  apache_site "kibana"

  template "#{node['logstash']['basedir']}/kibana/current/config.php" do
    source node['logstash']['kibana']['config']
    owner node['logstash']['user']
    group node['logstash']['group']
    mode "0755"
    variables(:es_server_ip => es_server_ip)
  end

  if node['logstash']['kibana']['auth']['enabled']
    htpasswd_path     = "#{node['logstash']['basedir']}/kibana/#{kibana_version}/htpasswd"
    htpasswd_user     = node['logstash']['kibana']['auth']['user']
    htpasswd_password = node['logstash']['kibana']['auth']['password']

    file htpasswd_path do
      owner node['logstash']['user']
      group node['logstash']['group']
      mode "0755"
    end

    execute "add htpasswd file" do
      command "/usr/bin/htpasswd -b #{htpasswd_path} #{htpasswd_user} #{htpasswd_password}"
    end
  end
  service "apache2"

end
