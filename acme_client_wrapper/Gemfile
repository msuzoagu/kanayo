source 'https://rubygems.org'
ruby '2.6.2'

group :production do 
  gem 'thor'
  gem 'droplet_kit', '~> 2.2.2'
  gem 'acme-client'
  gem 'public_suffix'
end

group :development, :test do 
  gem 'pry-byebug', '~> 3.5.1'
end

group :test do 
  gem 'vcr'
  gem 'rspec'
  gem 'webmock'
  gem 'simplecov', require: false
end
