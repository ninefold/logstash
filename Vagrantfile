require 'berkshelf/vagrant'

Vagrant::Config.run do |config|

chef_run_list = %w[
        logstash::server
        logstash::agent
]
#        curl::default
#        minitest-handler::default
#        logstash::server
#        logstash::agent
#        ark::default
#        kibana::default
#      ]

chef_json = {
    kibana: {
        webserver_listen: "0.0.0.0",
        webserver: "nginx",
        install_type: "file"
    },
    logstash: {
        supervisor_gid: 'adm',
        agent: {
            server_ipaddress: '127.0.0.1',
            xms: '128m',
            xmx: '128m',
            enable_embedded_es: false,
            inputs: [
              file: {
                type: 'syslog',
                path: ['/var/log/syslog','/var/log/messages'],
                start_position: 'beginning'
              }
            ],
            filters: [
              { 
                condition: 'if [type] == "syslog"',
                block: {    
                  grok: {
                    match: [
                      "message",
                      "%{SYSLOGTIMESTAMP:timestamp} %{IPORHOST:host} (?:%{PROG:program}(?:\[%{POSINT:pid}\])?: )?%{GREEDYDATA:message}"
                    ]
                  },
                  date: {
                    match: [ 
                      "timestamp",
                      "MMM  d HH:mm:ss",
                      "MMM dd HH:mm:ss",
                      "ISO8601"
                    ]
                  }
                }
            }
          ]
        },
        logstash: {
          server: {
            xms: '128m',
            xmx: '128m',
            enable_embedded_es: false,
            elasticserver_ip: '127.0.0.1'
          },
          kibana: {
            server_name: '33.33.33.10',
            http_port: '8080'
          }
        }
    }
}

Vagrant.configure('2') do |config|

  # Common Settings
  config.omnibus.chef_version = 'latest'
  config.vm.hostname = 'logstash'
  config.vm.network :private_network, ip: '192.168.200.50'
  config.vm.provider :virtualbox do |vb|
    vb.customize ['modifyvm', :id, '--memory', '1024']
  end
  config.vm.provider :lxc do |lxc|
    lxc.customize 'cgroup.memory.limit_in_bytes', '1024M'
  end  

  config.vm.define :precise64 do |dist_config|
    dist_config.vm.box       = 'opscode-ubuntu-12.04'
    dist_config.vm.box_url   = 'https://opscode-vm-bento.s3.amazonaws.com/vagrant/opscode_ubuntu-12.04_provisionerless.box'

    dist_config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = ['/tmp/logstash-cookbooks']
      chef.provisioning_path = '/etc/vagrant-chef'
      chef.log_level = log_level
      chef.run_list = chef_run_list
      chef.json = chef_json
      chef.run_list.unshift('apt')
      chef.json[:logstash][:server][:init_method] = 'runit'
    end
  end

  config.vm.define :lucid64 do |dist_config|
    dist_config.vm.box       = 'lucid64'
    dist_config.vm.box_url   = 'http://files.vagrantup.com/lucid64.box'

    dist_config.vm.customize do |vm|
      vm.name        = 'logstash'
      vm.memory_size = 1024
    end

    dist_config.vm.network :bridged, '33.33.33.10'

    dist_config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path    = [ '/tmp/logstash-cookbooks' ]
      chef.provisioning_path = '/etc/vagrant-chef'
      chef.log_level         = :debug

      chef.run_list = %w[
        minitest-handler
        apt
        java
        monit
        erlang
        git
        elasticsearch
        php::module_curl
        logstash::server
        logstash::kibana
      ]

      chef.json = {
        elasticsearch: {
          cluster_name: "logstash_vagrant",
          min_mem: '64m',
          max_mem: '64m',
          limits: {
            nofile:  1024,
            memlock: 512
          }
        },
        logstash: {
          server: {
            xms: '128m',
            xmx: '128m',
            enable_embedded_es: false,
            elasticserver_ip: '127.0.0.1'
          },
          kibana: {
            server_name: '33.33.33.10',
            http_port: '8080'
          }
        }
      }
    end
  end

  config.vm.define :centos6_32 do |dist_config|
    dist_config.vm.box       = 'centos6_32'
    dist_config.vm.box_url   = 'http://vagrant.sensuapp.org/centos-6-i386.box'

    dist_config.vm.customize do |vm|
      vm.name        = 'logstash'
      vm.memory_size = 1024
    end

    dist_config.vm.network :bridged, '33.33.33.10'

    dist_config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path    = [ '/tmp/logstash-cookbooks' ]
      chef.provisioning_path = '/etc/vagrant-chef'
      chef.log_level         = :debug

      chef.run_list = %w[
        minitest-handler
        java
        yum::epel
        erlang
        git
        elasticsearch
        php::module_curl
        logstash::server
        logstash::kibana
      ]

      chef.json = {
        elasticsearch: {
          cluster_name: "logstash_vagrant",
          min_mem: '64m',
          max_mem: '64m',
          limits: {
            nofile:  1024,
            memlock: 512
            }
        },
        logstash: {
          server: {
            xms: '128m',
            xmx: '128m',
            enable_embedded_es: false,
            elasticserver_ip: '127.0.0.1'
          }
        }
      }
    end
  end
end
