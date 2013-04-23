actions :create, :destroy
default_action :create

attribute :service_name, :kind_of => [NilClass,String], :default => ''
attribute :repository, :kind_of => String, :default => 'git://github.com/rashidkpc/Kibana.git'
attribute :revision, :kind_of => String, :default => 'kibana-ruby'
attribute :base_dir, :kind_of => String, :default => '/opt/logstash/kibana'
attribute :log_dir, :kind_of => String, :default => '/var/log/kibana'
attribute :pid_dir, :kind_of => String, :default => '/var/run/kibana'
attribute :conf, :kind_of => Hash, :required => true
attribute :user, :kind_of => String, :default => 'kibana'
attribute :group, :kind_of => String, :default => 'kibana'
attribute :disable_bundle_update, :kind_of => [TrueClass,FalseClass], :default => false
attribute :init_type, :kind_of => String

DEFAULT_CONFIG = Mash.new(
  'Elasticsearch' => '127.0.0.1:9200',
  'ElasticsearchTimeout' => 500,
  'KibanaPort' => 5601,
  'KibanaHost' => '127.0.0.1',
  'Type' => '',
  'Per_page' => 50,
  'Timezone' => 'user',
  'Timezone_format' => 'mm/dd HH:MM:ss',
  'Default_fields' => %w(@message),
  'Highlight_results' => true,
  'Highlighted_field' => '@message',
  'Clickable_URLs' => true,
  'Default_operator' => 'OR',
  'Analyze_limit' => 2000,
  'Analyze_show' => 25,
  'Rss_show' => 25,
  'Expert_show' => true,
  'Expert_delimiter' => ',',
  'Filter' => '',
  'Smart_index' => true,
  'Smart_index_pattern' => 'logstash-%Y.%m.%d',
  'Smart_index_step' => 86400,
  'Smart_index_limit' => 150,
  'Facet_index_limit' => 0,
  'Primary_field' => '_all',
  'Default_index' => '_all',
  'Disable_fullscan' => false,
  'Allow_iframed' => false,
  'Fallback_interval' => 900
)
