require 'yaml'
require 'json'
require 'uri'

def convert_yaml_to_s3_json_config(yaml_file, json_file)
  yaml_data = YAML.load_file(yaml_file)

  website_configuration = {}

  if yaml_data['s3']
    website_configuration['IndexDocument'] = { 'Suffix' => yaml_data['s3']['index'] } if yaml_data['s3']['index']
    website_configuration['ErrorDocument'] = { 'Key' => yaml_data['s3']['error'] } if yaml_data['s3']['error']

    if yaml_data['s3']['redirects']
      redirect_rules = yaml_data['s3']['redirects'].map do |rule|
        {
          'Condition' => {
            'KeyPrefixEquals' => rule['path'].delete_prefix('/')
          },
          'Redirect' => {
            'HostName' => URI.parse(rule['destination']).host,
            'HttpRedirectCode' => '301',
            'Protocol' => URI.parse(rule['destination']).scheme,
            'ReplaceKeyPrefixWith' => URI.parse(rule['destination']).path.delete_prefix('/')
          }
        }
      end
      website_configuration['RoutingRules'] = redirect_rules
    end
  end

  File.write(json_file, JSON.pretty_generate(website_configuration))
end

convert_yaml_to_s3_json_config('_config.yml', 's3_config.json')
