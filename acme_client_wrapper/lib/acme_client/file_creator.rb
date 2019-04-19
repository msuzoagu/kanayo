require "openssl"
require "acme_client/notification"

module DockerizedAcmeClient
  class FileCreator
    include DockerizedAcmeClient::Notification
    attr_reader :file, :file_utils

    def initialize
      @file = File 
      @file_utils = FileUtils    
    end

    def download_certificate(cert_hash)
      cert_hash.each_entry do |domain, hsh|
        path = create_domain_dir(domain)
        write_to_disk(path: path, file_name: cert_name, content: hsh[:cert])
        write_to_disk(path: path, file_name: pkey_name, content: hsh[:cert_key])
      end
    end

    # :skippit:
    def file_name(arg)
      file_name_array = arg.split('.')
      file_name_array.first + '_' + date_to_string + '.' + file_name_array.last
    end

    def cert_name
      file_name('fullchain.pem') 
    end

    def pkey_name
      file_name('certificate.key')
    end

    def date_to_string
      Date.today.strftime.gsub('-', '_')
    end

    # /ssl/live/domain_name/fullchain.pem
    # /ssl/live/domain_name/certificate.key
    def write_to_disk(content:, path:, file_name:)
      case file_name
      when pkey_name
        file.open(File.join(path, file_name), File::CREAT|File::TRUNC|File::RDWR, 0644) {|io| io.write(content.to_pem)}
      when cert_name
        file.open(File.join(path, file_name), File::CREAT|File::TRUNC|File::RDWR, 0644) {|io| io.write(content)}
      end  
    end

    def create_domain_dir(domain_name)
      domain_path = File.join(unexpired_path, "#{domain_name}")

      if string_path_exists?(domain_path)
        domain_dir_found(domain_path)
        domain_path
      else
        domain_dir_not_found(domain_path)
        create_path(domain_path)
      end
    end

    def unexpired_path
      active_certs =  Dir.pwd + '/ssl/live'
      string_path_exists?(active_certs) ? active_certs : create_path(active_certs)
    end

    def string_path_exists?(string_path)
      Dir.exists?(string_path) ? true : false
    end

    def create_path(string_path)
      file_utils.mkdir_p(string_path, mode: 0755)
      string_path
    end

    def expired_path
      expired_certs =  Dir.pwd + '/ssl/archive'
      string_path_exists?(expired_certs) ? expired_certs : create_path(expired_certs)
    end
  end
end
