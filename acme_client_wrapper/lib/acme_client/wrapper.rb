require 'yaml'
require 'openssl'
require 'acme-client'
require 'acme_client/notification'
require 'acme_client/file_creator'
require 'acme_client/configuration'
require 'acme_client/cloud_provider'

module DockerizedAcmeClient
  class Wrapper
    attr_reader :url, :file_creator, :cloud_provider
    
    include DockerizedAcmeClient::Notification
    include DockerizedAcmeClient::Configuration

    def initialize(**options)
      @url                = options.fetch(:url)
      @cloud_provider     = options.fetch(:cloud_provider)
      @file_creator       = options.fetch(:file_creator)
    end

    def order_certs
      account_verification
      acme_request
    end

    # :skippit:
    private
    def acme_request
      {}.tap do |memo|
        domains.each_with_object(memo) do |domain, memo|
          memo[domain] = Hash.new { |hash, key| hash[key] = {} }
          acme_order_for(domain, memo)
          acme_challenge_for(domain, memo)
          
          challenge = memo[domain][:challenge]
          respond_to_challenge_for(domain, challenge)
          verify_challenge(domain, challenge)

          order = memo[domain][:order]
          csr = request_csr_for(domain)
          finalized_order = finalize_certificate_request_for(order, csr)
          get_certificate(domain, memo)
        end
      end      
    end

    def get_certificate(domain, acme_order_challenge)
      acme_order_challenge[domain][:cert] = acme_order_challenge[domain][:order].certificate
      acme_order_challenge[domain][:cert_key] = read_cert_key
      file_creator.download_certificate(acme_order_challenge)
    end

    def finalize_certificate_request_for(order, domain_csr)
      begin
        order.finalize(csr: domain_csr)
      rescue Acme::Client::Error::BadNonce => e
        alert(e.message)
      end      
    end
    
    def acme_order_for(domain, hash_object)
      hash_object[domain][:order] = submit_order(domain)
    end

    def submit_order(domain)
      begin
        acme_client.new_order(identifiers: domain)
      rescue Acme::Client::Error::Malformed => e
        display_malformed_dns(e)
      rescue Acme::Client::Error::RejectedIdentifier => e
        display_malformed_dns(e)
      end
    end    

    def acme_challenge_for(domain, hash_object)
      hash_object[domain][:challenge] = hash_object[domain][:order].authorizations.find do |auth|
        auth
      end.dns
    end

    def poll(challenge)
      while challenge.status == 'pending'
        sleep(5)
        challenge.reload
      end
    end

    def extract_txt_values_from(challenge)
      {}.tap do |hsh|
        hsh[:record_type] = challenge.record_type
        hsh[:record_name] = challenge.record_name
        hsh[:record_data] = challenge.record_content 
      end
    end

    def respond_to_challenge_for(domain, challenge)
      txt_values_hash = extract_txt_values_from(challenge)     
      cloud_provider.add_txt_values_for(domain, txt_values_hash)
    end

    def verify_challenge(domain, challenge)
      validate(challenge)
      poll(challenge)
      raise_invalid_challenge(domain, challenge) if challenge.status == 'invalid'
    end

    def validate(challenge)
      begin
        response = challenge.request_validation      
      rescue Acme::Client::Error::BadNonce => e
        alert_then_abort(e.message)
      rescue Acme::Client::Error::Dns => e
        alert_then_abort(e.message)
      end
    end

    def account_verification
      begin
        user_account
      rescue Acme::Client::Error::AccountDoesNotExist => e
        create_user_account(e)
      rescue Acme::Client::Error::Unauthorized => e
        display_account_already_deactivated(e)
      end
    end

    def user_account
      account_key_path = account_key_path
      display_existing_account_message(account_key_path)
      acme_client.account
    end

    def create_user_account(excep)
      display_no_existing_account_message(excep)
      account_key_path = account_key_path
      display_creating_account_message(account_key_path)
      acme_client.new_account(contact: mail_to_contact, terms_of_service_agreed: true)
    end

    def acme_client
      Acme::Client.new(
        private_key: read_account_key, 
        directory: url
      )                     
    end

    def request_csr_for(domain_name)
      Acme::Client::CertificateRequest.new(
        private_key: read_cert_key,
        subject: { common_name: domain_name}
      )
    end

    def read_account_key
      OpenSSL::PKey::RSA.new(File.read(account_key_path))
    end

    def read_cert_key
      OpenSSL::PKey::RSA.new(File.read(certificate_key_path))
    end

    def mail_to_contact
      'mailto:' + email
    end
  end
end
