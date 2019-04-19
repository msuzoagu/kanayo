require 'support/vcr_helper'
require 'shared/valid_context'
require 'acme_client/cloud_provider'

RSpec.describe DockerizedAcmeClient::CloudProvider do 
  include_context :valid_context

  subject(:provider)  { DockerizedAcmeClient::CloudProvider.new }

  describe '#add_txt_values_for' do 
    
    let(:txt_hash) {
      {
        :record_type=>"TXT", 
        :record_name=>"_acme-challenge", 
        :record_data=>"P94nI4FoH-zUrFUGSzLq5l05KKaxiM0TabMeBVXgwwM"
      }
    }

    let(:update_txt) {
      {
        :record_type=>"TXT", 
        :record_name=>"_acme-challenge", 
        :record_data=>"K5KaxiM0T-zUrFUGSzLq5l0P94nI4FoHabMeBVXgwwM"
      }
    }

    let(:domains) {
      ["blog.subdomainishostnameorfqdn.com", "somerandomdomain.com", "subdomainishostnameorfqdn.com", "apex.com", "txtrecordexists.com"]
    }  

    context 'when apex' do
      let(:domain) { 'apex.com' }

      context 'domain does not exist' do 
        let(:domain) { 'doesnotexist.com' }

        it 'aborts the program with message', vcr: {cassette_name: 'provider/do/domain_record'} do 
          expect do 
            expect{provider.add_txt_values_for(domain, txt_hash)}.to raise_error(SystemExit)
          end.to output().to_stderr
        end        
      end 

      context 'domain exists' do 

        context 'when no TXT record' do     
          it 'does not call update_txt_record', vcr: {cassette_name: 'provider/do/new_txt_for_apex'} do 
            expect(provider).to_not receive(:update_txt_record)
            provider.add_txt_values_for(domain, txt_hash)        
          end      

          it 'creates a txt record', vcr: {cassette_name: 'provider/do/new_txt_for_apex'} do 
            expect(provider.add_txt_values_for(domain, txt_hash)[:data]).to eq(txt_hash[:record_data])      
          end 

          it 'does not raise_error', vcr: {cassette_name: 'provider/do/new_txt_for_apex'} do 
            expect{provider.add_txt_values_for(domain, txt_hash)}.to_not raise_error   
          end 
        end

        context 'when TXT record exists' do   
          let(:domain) {'txtrecordexists.com'}

          it 'does not call create_txt_record', vcr: {cassette_name: 'provider/do/update_txt_for_apex'} do 
            expect(provider).to_not receive(:create_txt_record)
            provider.add_txt_values_for(domain, update_txt)        
          end    

          it 'updates txt record', vcr: {cassette_name: 'provider/do/update_txt_for_apex'} do 
            expect(provider.add_txt_values_for(domain, update_txt)[:data]).to eq(update_txt[:record_data])      
          end 

          it 'does not raise_error', vcr: {cassette_name: 'provider/do/update_txt_for_apex'} do 
            expect{provider.add_txt_values_for(domain, update_txt)}.to_not raise_error   
          end  
        end                 
      end
    end

    context 'when subdomain is cname' do 
      let(:domain) { 'www.apex.com' }
      
      context 'when no TXT record' do 
        it 'calls check_apex_for', vcr: {cassette_name: 'provider/do/new_txt_for_cname'} do 
          expect(provider).to receive(:check_apex_for)
          provider.add_txt_values_for(domain, txt_hash)        
        end

        it 'does not call hostname_check', vcr: {cassette_name: 'provider/do/new_txt_for_cname'} do 
          expect(provider).to_not receive(:hostname_check)
          provider.add_txt_values_for(domain, txt_hash)        
        end

        it 'creates a txt record', vcr: {cassette_name: 'provider/do/new_txt_for_cname'} do 
          expect(provider.add_txt_values_for(domain, txt_hash)[:data]).to eq(txt_hash[:record_data])      
        end  

        it 'does not raise_error', vcr: {cassette_name: 'provider/do/new_txt_for_cname'} do 
          expect{provider.add_txt_values_for(domain, txt_hash)}.to_not raise_error   
        end       
      end

      # context 'when TXT record' do 
      #   it 'does not call hostname_check', vcr: {cassette_name: 'provider/do/update_txt_for_cname'} do 
      #     expect(provider).to_not receive(:hostname_check)
      #     provider.add_txt_values_for(domain, update_txt)        
      #   end

      #   it 'updates txt record', vcr: {cassette_name: 'provider/do/update_txt_for_cname'} do 
      #     expect(provider.add_txt_values_for(domain, update_txt)[:data]).to eq(update_txt[:record_data])      
      #   end 

      #   it 'does not raise_error', vcr: {cassette_name: 'provider/do/update_txt_for_cname'} do 
      #     expect{provider.add_txt_values_for(domain, update_txt)}.to_not raise_error   
      #   end
      # end
    end

    # FQDN is a domain name that includes a hostname eg: www.yahoo.com
    context 'when subdomain is hostname/FQDN' do 
      let(:domain) { 'www.subdomainishostnameorfqdn.com' }
      
      context 'when no TXT record' do 
        it 'calls check_apex_for', vcr: {cassette_name: 'provider/do/new_txt_for_hostname'} do 
          expect(provider).to receive(:check_apex_for)
          provider.add_txt_values_for(domain, txt_hash)        
        end    
            
        it 'calls hostname_check', vcr: {cassette_name: 'provider/do/new_txt_for_hostname'} do 
          expect(provider).to receive(:hostname_check)
          provider.add_txt_values_for(domain, txt_hash)        
        end

        it 'creates a txt record', vcr: {cassette_name: 'provider/do/new_txt_for_hostname'} do 
          expect(provider.add_txt_values_for(domain, txt_hash)[:data]).to eq(txt_hash[:record_data])      
        end  

        it 'does not raise_error', vcr: {cassette_name: 'provider/do/new_txt_for_hostname'} do 
          expect{provider.add_txt_values_for(domain, txt_hash)}.to_not raise_error   
        end        
      end

      context 'when TXT record' do 
        it 'calls check_apex_for', vcr: {cassette_name: 'provider/do/update_txt_for_hostname'} do 
          expect(provider).to receive(:check_apex_for)
          provider.add_txt_values_for(domain, txt_hash)        
        end 

        it 'calls hostname_check', vcr: {cassette_name: 'provider/do/update_txt_for_hostname'} do 
          expect(provider).to receive(:hostname_check)
          provider.add_txt_values_for(domain, update_txt)        
        end

        it 'updates txt record', vcr: {cassette_name: 'provider/do/update_txt_for_hostname'} do 
          expect(provider.add_txt_values_for(domain, update_txt)[:data]).to eq(update_txt[:record_data])      
        end 

        it 'does not raise_error', vcr: {cassette_name: 'provider/do/update_txt_for_hostname'} do 
          expect{provider.add_txt_values_for(domain, update_txt)}.to_not raise_error   
        end
      end
    end

    # subdomain exists on its own 
    # not a cname record of its apex domain 
    # not a hostname record of its apex domain
    context 'when neither cname nor hostname' do 
      let(:domain) {'blog.subdomainishostnameorfqdn.com'}

      context 'when no TXT record' do 
        it 'does not call check_apex_for', vcr: {cassette_name: 'provider/do/independent_subdomain'} do 
          expect(provider).to_not receive(:check_apex_for)
          provider.add_txt_values_for(domain, txt_hash)        
        end

        it 'creates a txt record', vcr: {cassette_name: 'provider/do/independent_subdomain'} do 
          expect(provider.add_txt_values_for(domain, txt_hash)[:data]).to eq(txt_hash[:record_data])      
        end  

        it 'does not raise_error', vcr: {cassette_name: 'provider/do/independent_subdomain'} do 
          expect{provider.add_txt_values_for(domain, txt_hash)}.to_not raise_error   
        end        
      end     

      context 'when TXT record' do 
        it 'does not call check_apex_for', vcr: {cassette_name: 'provider/do/update_independent_subdomain'} do 
          expect(provider).to_not receive(:check_apex_for)
          provider.add_txt_values_for(domain, update_txt)        
        end

        it 'updates txt record', vcr: {cassette_name: 'provider/do/update_independent_subdomain'} do 
          expect(provider.add_txt_values_for(domain, update_txt)[:data]).to eq(update_txt[:record_data])      
        end  

        it 'does not raise_error', vcr: {cassette_name: 'provider/do/update_independent_subdomain'} do 
          expect{provider.add_txt_values_for(domain, update_txt)}.to_not raise_error   
        end        
      end 
    end    
  end
end
