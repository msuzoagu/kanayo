require 'find'
require_relative "./notification"

module DockerizedAcmeClient
  module Configuration

    def valid_directory_structure?
      directory_structure_is_invalid unless (directory_present? && files_count_valid?)
    end

    def has_empty_file?
      empty_file_present(empty_file) if empty_file
    end

    def yaml_valid?
      invalid_yaml if error_in_yaml?
    end

    def domains
      load_yaml['domains']
    end

    def email
      load_yaml['email']
    end

    def provider
      load_yaml['provider']
    end

    def account_key_path
      path_as_string = File.join(configuration_directory, '/', find_account_key )
      Pathname.new(path_as_string)
    end

    def certificate_key_path
      path_as_string = File.join(configuration_directory, '/', find_certificate_key )
      Pathname.new(path_as_string)
    end

     # :skippit:
    private 

      def configuration_directory
        Dir.getwd + '/configuration' 
      end 

      def directory_present?
         Dir.exist?(configuration_directory)
      end  

      def files_count_valid?
        files_in_directory.count == 3
      end

      def files_in_directory
        files = []
        Find.find(configuration_directory) do |file|
          files.push(file) if not FileTest.directory?(file)
        end
        files      
      end

      def empty_file
        files_in_directory.detect { |string_path_to_file| Pathname.new(string_path_to_file).zero? }
      end

      def load_yaml
        begin
          YAML.load_file(yaml_file_path)
        rescue SyntaxError => e
          alert_then_abort(e)  
        end
      end

      def yaml_file_path
        path_as_string = File.join(configuration_directory, '/', find_yaml_file )
        Pathname.new(path_as_string)
      end

      def find_yaml_file
        Dir.children(configuration_directory).find { |is_yaml_file| is_yaml_file[/(.yaml$|.yml$)/] }
      end 

      def find_certificate_key
        Dir.children(configuration_directory).find { |is_csr_pem| is_csr_pem[/(certificate.key$)/] }
      end

      def find_account_key
        Dir.children(configuration_directory).find { |is_acct_pem| is_acct_pem[/(account.key$)/] }
      end
      
      def error_in_yaml?
        email_is_absent || provider_is_invalid || domain_is_absent
      end

      def email_is_absent
        email == nil || email.empty?  == true
      end

      def provider_is_invalid 
       provider.empty? == true || 
       provider.count != 2 || 
       contains_empty_value(provider)
      end

      def value_is_invalid(arg_is_hash)
        arg_is_hash.any? do |key, value|
          value.empty? == true  || value == nil
        end
      end

      def contains_empty_value(arg_is_hash)
        if value_is_invalid(arg_is_hash)
          true
        else
          false
        end
      end

      def domain_is_absent
        domains.is_a?(String) == true || 
        domains == nil || 
        domains.include?(nil) == true || 
        domains.count == 0
      end
  end
end
