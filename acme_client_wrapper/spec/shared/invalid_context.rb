require 'openssl'
require 'yaml'

shared_context :invalid_context do
  around do |example|
    @root_stub = fake_config_dir_invalid_context
    example.run
    FileUtils.rm_r(@root_stub)
  end
  attr_accessor :root_path_empty
end

def fake_config_dir_invalid_context
  files  = %w[config.yaml certificate.key account.key]  
  strg_config_dir        = Dir.pwd + '/configuration'
  @root_path_empty        = Pathname.new(strg_config_dir)
  root_empty_config_dir  = FileUtils.mkdir_p(@root_path_empty)

  files.each do |filename|
    file_path = strg_config_dir + '/' + filename
    create_file_content_empty(file_path)
  end

  strg_config_dir
end

def create_file_content_empty(filepath_as_string)
  read_account_key = OpenSSL::PKey::RSA.new(File.read(Dir.getwd + '/spec/shared/account.key'))
  convert_invalid_hash = invalid_hash.to_yaml
  
  file = File.open(filepath_as_string, 'w')

  if File.basename(file) == "config.yaml"
    file.write(convert_invalid_hash)   
  elsif File.basename(file) == "account.key"
    file.write(read_account_key.to_pem) 
  else
    file.write("")
  end

  file.close
end

def invalid_hash
  { 
    "provider"=>{
      "name"=>"digital_ocean", 
      "token"=>"abc"
    }, 
    "domains"=>[
      "example.com", 
      "one.example.com", 
      "nine.example.com"
    ],
    "email"=>"validemail@gmail.co.uk"
  }
end
