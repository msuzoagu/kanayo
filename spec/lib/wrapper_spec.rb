require "support/vcr_helper"
require "shared/valid_context"
require_relative "../../lib/wrapper"
require_relative "../../lib/notification"
require_relative "../../lib/configuration"

RSpec.describe DockerizedAcmeClient::Wrapper do 
  include_context :valid_context

  let(:url)                         { 'https://acme-staging-v02.api.letsencrypt.org/directory' }
  let(:file_creator)                { instance_double(DockerizedAcmeClient::FileCreator) }
  let(:cloud_provider)              { instance_double(DockerizedAcmeClient::CloudProvider) }

  let(:objet)                       { Object.new }
  let(:notification)                { objet.extend(DockerizedAcmeClient::Notification) }
  let(:configuration)               { objet.extend(DockerizedAcmeClient::Configuration) }

  let(:shared_dir)                  { Dir.getwd + '/spec/shared'}
  let(:path_to_acct_key)            { shared_dir + '/account.key' }
  let(:path_to_cert_key)            { shared_dir + '/certificate.key' }

  subject(:wrapper) do 
    DockerizedAcmeClient::Wrapper.new(
      url: url,
      file_creator: file_creator, 
      cloud_provider: cloud_provider
    )
  end

  describe '#order_certs' do 

    context 'when order is invalid' do

      before do 
        allow(configuration).to receive(:domains).and_return(['domainname_12on.com'])
        allow(cloud_provider).to receive(:add_txt_values_for)        
      end

      it 'aborts the program with a message', vcr: {cassette_name: 'acme/order_invalid'} do 
        expect do 
          expect{wrapper.order_certs}.to raise_error(SystemExit)
        end.to output().to_stderr   
      end
    end

    context 'when challenge is invalid' do 

      before do 
        allow(configuration).to receive(:domains).and_return(['www.invalidchallenge.com'])
        allow(cloud_provider).to receive(:add_txt_values_for)
      end 


      it 'aborts the program with message', vcr: {cassette_name: 'acme/challenge_invalid'} do 
        expect do 
          expect{wrapper.order_certs}.to raise_error(SystemExit)
        end.to output().to_stderr
      end 
    end

    context 'when order and challenge are valid' do 

      before do 
        allow(configuration).to receive(:domains).and_return(['www.cname.com'])
        allow(cloud_provider).to receive(:add_txt_values_for)
        allow(file_creator).to receive(:download_certificate)
      end       

      it 'does not raise any errors', vcr: {cassette_name: 'acme/valid_order_challenge'} do 
        expect{wrapper.order_certs}.to_not raise_error
      end

      it 'calls download_certificate on instance of self', vcr: {cassette_name: 'acme/valid_order_challenge'} do 
        expect(wrapper).to receive(:get_certificate)
        wrapper.order_certs 
      end
    end
  end
end
