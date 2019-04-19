require "acme_client/configuration"

RSpec.describe DockerizedAcmeClient::Configuration do 

  let(:objet)                { Object.new }
  subject(:configuration)    { objet.extend(DockerizedAcmeClient::Configuration) }


  let(:configuration_directory) { Dir.getwd + '/configuration'}
end
