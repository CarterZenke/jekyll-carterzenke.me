require 'jekyll'
require 'yaml'
require 'json'
require 'uri'

module Jekyll
  class S3ConfigGenerator < Generator
    safe true
    priority :highest

    def generate(site)
      Jekyll.logger.info "S3ConfigGenerator:", "Generating S3 config"
      
      config_data = site.config['s3']
      return unless config_data

      website_configuration = {}

      website_configuration['IndexDocument'] = { 'Suffix' => config_data['index'] } if config_data['index']
      website_configuration['ErrorDocument'] = { 'Key' => config_data['error'] } if config_data['error']

      if config_data['redirects']
        redirect_rules = config_data['redirects'].map do |rule|
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

      File.write(site.dest + '/s3_config.json', JSON.pretty_generate(website_configuration))
      Jekyll.logger.info "S3ConfigGenerator:", "S3 config generated at #{site.dest}/s3_config.json"
    end
  end
end
