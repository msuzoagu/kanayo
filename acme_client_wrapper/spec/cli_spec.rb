require "cli"
require "shared/valid_context"
require "shared/invalid_context"

RSpec.describe Cli do 
  let(:cli) { Cli.new }

  describe '#endpoint_is_valid?' do 
    context 'when false' do 
      let(:env) { 'something' }

      it 'aborts the program with a message' do 
        msg = "You supplied #{env} but only staging or production are valid arguments."

        expect do 
          expect{cli.endpoint_is_valid?(env)}.to raise_error(SystemExit)
        end.to output("#{msg}\n").to_stderr
      end
    end
  end

  describe '#order_certs' do 
    let(:env)        { 'staging' }
    let(:url)        { 'https://acme-staging-v02.api.letsencrypt.org/directory' }
    let(:wrapper)     { instance_double(DockerizedAcmeClient::Wrapper) }

    context 'when configuration is invalid' do
      include_context :invalid_context 

      it 'exits the program with a message' do 
        expect do 
          expect{cli.order_certs(env)}.to raise_error(SystemExit)
        end.to output().to_stderr
      end
    end

    context 'when configuration is valid' do 
      include_context :valid_context 

      before do 
        allow(DockerizedAcmeClient::Wrapper).to receive(:new).and_return(wrapper)
      end

      it 'sends order_certs to instance of Wrapper class' do 
        expect(wrapper).to receive(:order_certs)  
        cli.order_certs(env)
      end            
    end
  end
end
