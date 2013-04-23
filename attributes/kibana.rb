default['logstash']['kibana']['repo'] = 'git://github.com/rashidkpc/Kibana.git'
default['logstash']['kibana']['reference'] = 'v0.2.0'
default['logstash']['kibana']['sha'] = '806d9b4d7a88b102777cca8ec3cb472f3eb7b5b1'
default['logstash']['kibana']['apache_template'] = 'kibana.conf.erb'
default['logstash']['kibana']['basedir'] = "#{node['logstash']['basedir']}/kibana"
default['logstash']['kibana']['log_dir'] = '/var/log/kibana'
default['logstash']['kibana']['pid_dir'] = '/var/run/kibana'
default['logstash']['kibana']['home'] = "#{node['logstash']['kibana']['basedir']}/current"
default['logstash']['kibana']['server_name'] = node['ipaddress']
default['logstash']['kibana']['server_hostname'] = node['ipaddress']
default['logstash']['kibana']['http_port'] = 80
default['logstash']['kibana']['auth']['server_auth_method'] = nil
default['logstash']['kibana']['auth']['user'] = 'admin'
default['logstash']['kibana']['auth']['password'] = 'unauthorized'
default['logstash']['kibana']['auth']['cas_login_url'] = "https://example.com/cas/login"
default['logstash']['kibana']['auth']['cas_validate_url'] = "https://example.com/cas/serviceValidate"
default['logstash']['kibana']['auth']['cas_validate_server'] = "off"
default['logstash']['kibana']['auth']['cas_root_proxy_url'] = nil
default['apache']['default_site_enabled'] = false

default['logstash']['kibana']['language'] = "ruby" 
