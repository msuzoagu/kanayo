require 'vcr'

VCR.configure do |c|
  c.configure_rspec_metadata!
  c.cassette_library_dir = 'spec/cassettes'

  c.hook_into :webmock

  c.default_cassette_options = { record: :new_episodes, match_requests_on: [:method, :path, :query], allow_playback_repeats: :true  }
  c.allow_http_connections_when_no_cassette = false
end
