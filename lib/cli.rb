require "thor"
require_relative "./wrapper"
require_relative "./configuration"
require_relative "./notification"

class Cli < Thor 
  include DockerizedAcmeClient::Notification
  include DockerizedAcmeClient::Configuration

  desc "order_certs ENDPOINT", "order ssl/tls certs at LetsEncrypt endpoint. Default is staging"
  def order_certs(endpoint='staging')
    acme_client_wrapper(endpoint).order_certs
  end

  no_tasks do 
    def acme_client_wrapper(endpoint)
      endpoint_is_valid?(endpoint)
      valid_directory_structure?
      has_empty_file?
      yaml_valid?
      wrapper(set_url(endpoint))
    end

    def endpoint_is_valid?(endpoint)
      raise_invalid_environment(endpoint) unless ['staging', 'production'].include?(endpoint)
    end

    def wrapper(url)
      @wrapper ||= DockerizedAcmeClient::Wrapper.new(url: url, cloud_provider: cloud_provider, file_creator: file_creator)
    end

    def set_url(endpoint)
      url = ''
      if endpoint === 'production'
        url = 'https://acme-v02.api.letsencrypt.org/directory'
      else
        url = 'https://acme-staging-v02.api.letsencrypt.org/directory' 
      end
    end 

    def cloud_provider
      @cloud_provider ||= DockerizedAcmeClient::CloudProvider.new
    end

    def file_creator
      @file_creator ||=  DockerizedAcmeClient::FileCreator.new
    end
  end
end
