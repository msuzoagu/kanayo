module DockerizedAcmeClient
  # :skippit:
  module Notification
    
    # aborts writes to STDERR and
    # exits with status false which
    # represents a failure and thus
    # will exit the program
    def alert_then_abort(message)
      abort(message)
    end

    def alert(message)
      $stdout.puts(message)
    end

    #### Wrapper Notifications
    def display_existing_account_message(arg)
      msg = "retriving account tied to #{arg}"
      alert(msg)
    end

    def display_no_existing_account_message(excep)
      msg = excep.message
      alert(msg)
    end

    def display_creating_account_message(arg)
      msg = "creating a new account tied to #{arg}"
      alert(msg)
    end

    def display_account_already_deactivated(excep)
      msg = excep.message
      alert_then_abort(msg)
    end

    def display_malformed_dns(excep)
      msg = excep.message
      alert_then_abort(msg)
    end

    def raise_invalid_challenge(domain, challenge)
      "challenge status is invalid" 
      type = challenge.error['type']
      detail = challenge.error['detail']
      msg = "certificate request for #{domain} resulted in error type #{type} with #{detail}"
      alert_then_abort(msg)      
    end

    ### Configuration Notifications 
    def empty_file_present(file)
      string_message = "#{file} is an empty file. Please see image readme."
      alert_then_abort(string_message)         
    end

    def directory_structure_is_invalid
      string_message = "config directory must contain 3 config files. See image readme"
      alert_then_abort(string_message) 
    end 
      
    def raise_invalid_environment(arg)
      msg = "You supplied #{arg} but only staging or production are valid arguments."
      alert_then_abort(msg)
    end

    def invalid_yaml
      string_message = "yaml file is misconfigurated. Please check your yaml file"
      alert_then_abort(string_message)       
    end

    ### CloudProvider Notifications
    def last
      "Please check your domain and DNS configurations on DigitalOcean."
    end

    def raise_apex_missing(arg)
      one = "#{arg} not managed by DigitalOcean.\n"
      msg = one + last
      alert_then_abort(msg)
    end
    
    def raise_subdomain_missing(apex, subdomain)
      one = "Neither #{subdomain} nor its root #{apex} are managed by DigitalOcean\n"
      msg = one + last
      alert_then_abort(msg)
    end

    def raise_neither_cname_nor_hostname(apex, subdomain)
      one = "Root domain #{apex} was found for #{subdomain}\n"
      two = "but neither #{subdomain}, a cname record nor a hostname record was found for it.\n"
      msg = one + two + last
      alert_then_abort(msg)
    end

    ### FileCreator Notification
    def domain_dir_found(arg)
      msg = "#{arg} directory found"
      alert(msg)
    end

    def domain_dir_not_found(arg)
      msg = "creating #{arg} to hold certificate and certificate key"
      alert(msg)      
    end
  end
end
