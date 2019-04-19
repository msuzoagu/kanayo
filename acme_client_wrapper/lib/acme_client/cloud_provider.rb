require 'droplet_kit'
require 'public_suffix'
require 'acme_client/notification' 
require 'acme_client/configuration'

module DockerizedAcmeClient
  class CloudProvider
    include Notification
    include Configuration

    def add_txt_values_for(domain, txt_hash)

      domains = client.domains.all.collect { |record| record[:name] }

      if is_subdomain?(domain)
        create_or_update_subdomain_record(domain, txt_hash, domains)
      else
        verify_apex(domain, domains)
        records = domain_records_for(domain)
        create_or_update_record(domain, txt_hash, records)
      end
    end

    # :skippit:
    private 
    def is_subdomain?(domain)
      PublicSuffix.parse(domain).subdomain != nil 
    end

    def create_or_update_subdomain_record(subdomain, txt_hash, domains)
      if domains.include?(subdomain)
        records = domain_records_for(subdomain)
        create_or_update_record(subdomain, txt_hash, records)
      else
        check_apex_for(subdomain, txt_hash, domains)
      end
    end

    def verify_apex(domain, domains)
      raise_apex_missing(domain) unless domains.include?(domain) 
    end

    def check_apex_for(subdomain, txt_hash, domains)
      apex = PublicSuffix.parse(subdomain).domain
      prefix = PublicSuffix.parse(subdomain).trd

      raise_subdomain_missing(apex, subdomain) unless domains.include?(apex)   

      records = domain_records_for(apex)

      if is_cname?(prefix, records)
        
        old_record_name = txt_hash[:record_name]
        new_record_name = old_record_name + '.' + prefix
        txt_hash[:record_name] = new_record_name

        create_or_update_record(apex, txt_hash, records) 
      else
        hostname_check(apex, prefix, txt_hash, records)
      end
    end

    def is_cname?(prefix, records)
      found = records.select { |record| record[:type] == "CNAME" && record[:name] == prefix }.count
      found > 0 
    end

    def hostname_check(apex, prefix, txt_hash, records)
      subdomain = prefix + '.' + apex 

      if is_hostname(prefix, records)

        old_record_name = txt_hash[:record_name]
        new_record_name = old_record_name + '.' + prefix
        txt_hash[:record_name] = new_record_name

        create_or_update_record(apex, txt_hash, records) 
      else
        raise_neither_cname_nor_hostname(apex, subdomain)
      end
    end

    def is_hostname(prefix, records)
      found = records.select { |record| record[:type] == "A" && record[:name] == prefix }.count
      found > 0 
    end

    # how do I know which txt record to update? Think:
    # I need to find a way to add txt record 
    # validate, poll, raise_error if any in wrapper 
    # then delete newly created/updated txt record 
    def create_or_update_record(domain, txt_hash, records)
      txt_record = records.find { |record| record[:type] == "TXT" }
      if txt_record == nil
        create_txt_record(domain, txt_hash)
      else
       update_txt_record(domain, txt_hash, txt_record) 
      end
    end

    def create_txt_record(domain, txt_hash)
      record = add_record(txt_hash)
      client.domain_records.create(record, for_domain: domain)       
    end

    def update_txt_record(domain, txt_hash, record)
      record_id = record.id
      new_record = add_record(txt_hash)
      client.domain_records.update(new_record, for_domain: domain, id: record_id)
    end

    def add_record(record_hash)
      DropletKit::DomainRecord.new(
        type: record_hash[:record_type],
        name: record_hash[:record_name],
        data: record_hash[:record_data]        
      )
    end

    def find_txt_record(domain)
      domain_records_for(domain).find { |record| record[:type] == "TXT" }
    end

    def domain_records_for(domain)
      client.domain_records.all(for_domain: domain)
    end

    def token
      provider.transform_keys { |key| key.to_sym }.fetch(:token) 
    end

    def client
      DropletKit::Client.new(access_token: token)
    end
  end
end
