require 'openssl'
require 'yaml'

shared_context :valid_context do
  around do |example|
    @root_stub = fake_config_dir_valid_context
    example.run 
    FileUtils.rm_r(@root_stub)
  end
  attr_accessor :root_stub_path
end

def fake_config_dir_valid_context
  files           = %w[config.yaml certificate.key account.key]  
  strg_config_dir = Dir.pwd + '/configuration'
  @root_stub_path  = Pathname.new(strg_config_dir)
  fake_config_dir = FileUtils.mkdir_p(@root_stub_path)

  files.each do |filename|
    file_path = strg_config_dir + '/' + filename
    create_file_content(file_path)
  end

  strg_config_dir
end


def create_file_content(filepath_as_string)
  convert_valid_hash = valid_hash.to_yaml
  read_account_key = OpenSSL::PKey::RSA.new(File.read(Dir.getwd + '/spec/shared/account.key'))
  read_certificate_key = OpenSSL::PKey::RSA.new(File.read(Dir.getwd + '/spec/shared/certificate.key'))

  file = File.open(filepath_as_string, 'w')

  if File.basename(file) == "config.yaml"
    file.write(convert_valid_hash)   
  elsif File.basename(file) == "account.key"
    file.write(read_account_key.to_pem) 
  else
    file.write(read_certificate_key.to_pem)
  end

  file.close
end

def valid_hash
  { 
    "provider"=>{
      "name"=>"digital_ocean", 
      "token"=>"abc"
    }, 
    "domains"=>[
      "www.cname.com"
    ],
    "email"=>"youremail@mailserver.com"
  }
end

def generate_private_key
  OpenSSL::PKey::RSA.new(2048)
end
