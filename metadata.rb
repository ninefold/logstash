name             "logstash"
maintainer       "John E. Vincent"
maintainer_email "lusis.org+github.com@gmail.com"
license          "Apache 2.0"
description      "Installs/Configures logstash"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.6.1"

%w{ ubuntu debian redhat centos scientific amazon fedora }.each do |os|
  supports os
end

%w{ apt apache2 php build-essential git rbenv runit python java ant logrotate rabbitmq yumrepo discovery ruby_installer application application_ruby build-essential }.each do |ckbk|
  depends ckbk
end
