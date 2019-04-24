require "openssl"
require_relative "../../lib/file_creator"

RSpec.describe DockerizedAcmeClient::FileCreator do 
  subject(:file_creator) { DockerizedAcmeClient::FileCreator.new }

  let(:cert_key_path)           { Dir.getwd + '/spec/shared/certificate.key' }
  let(:domain_dir)              { Pathname.new(Dir.getwd + '/ssl/live/domain_name') }
  let(:remove)                  { Pathname.new(Dir.getwd + '/ssl') }

  let(:cert) {
    "-----BEGIN CERTIFICATE-----\n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\nU/nHZ56B3iQ=\n-----END CERTIFICATE-----\n\n-----BEGIN CERTIFICATE-----\nMIIEqzCCApOgAwIBAgIRAIvhKg5ZRO08VGQx8JdhT+UwDQYJKoZIhvcNAQELBQAw\nGjEYMBYGA1UEAwwPRmFrZSBMRSBSb290IFgxMB4XDTE2MDUyMzIyMDc1OVoXDTM2\nMDUyMzIyMDc1OVowIjEgMB4GA1UEAwwXRmFrZSBMRSBJbnRlcm1lZGlhdGUgWDEw\nggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDtWKySDn7rWZc5ggjz3ZB0\n8jO4xti3uzINfD5sQ7Lj7hzetUT+wQob+iXSZkhnvx+IvdbXF5/yt8aWPpUKnPym\noLxsYiI5gQBLxNDzIec0OIaflWqAr29m7J8+NNtApEN8nZFnf3bhehZW7AxmS1m0\nZnSsdHw0Fw+bgixPg2MQ9k9oefFeqa+7Kqdlz5bbrUYV2volxhDFtnI4Mh8BiWCN\nxDH1Hizq+GKCcHsinDZWurCqder/afJBnQs+SBSL6MVApHt+d35zjBD92fO2Je56\ndhMfzCgOKXeJ340WhW3TjD1zqLZXeaCyUNRnfOmWZV8nEhtHOFbUCU7r/KkjMZO9\nAgMBAAGjgeMwgeAwDgYDVR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAw\nHQYDVR0OBBYEFMDMA0a5WCDMXHJw8+EuyyCm9Wg6MHoGCCsGAQUFBwEBBG4wbDA0\nBggrBgEFBQcwAYYoaHR0cDovL29jc3Auc3RnLXJvb3QteDEubGV0c2VuY3J5cHQu\nb3JnLzA0BggrBgEFBQcwAoYoaHR0cDovL2NlcnQuc3RnLXJvb3QteDEubGV0c2Vu\nY3J5cHQub3JnLzAfBgNVHSMEGDAWgBTBJnSkikSg5vogKNhcI5pFiBh54DANBgkq\nhkiG9w0BAQsFAAOCAgEABYSu4Il+fI0MYU42OTmEj+1HqQ5DvyAeyCA6sGuZdwjF\nUGeVOv3NnLyfofuUOjEbY5irFCDtnv+0ckukUZN9lz4Q2YjWGUpW4TTu3ieTsaC9\nAFvCSgNHJyWSVtWvB5XDxsqawl1KzHzzwr132bF2rtGtazSqVqK9E07sGHMCf+zp\nDQVDVVGtqZPHwX3KqUtefE621b8RI6VCl4oD30Olf8pjuzG4JKBFRFclzLRjo/h7\nIkkfjZ8wDa7faOjVXx6n+eUQ29cIMCzr8/rNWHS9pYGGQKJiY2xmVC9h12H99Xyf\nzWE9vb5zKP3MVG6neX1hSdo7PEAb9fqRhHkqVsqUvJlIRmvXvVKTwNCP3eCjRCCI\nPTAvjV+4ni786iXwwFYNz8l3PmPLCyQXWGohnJ8iBm+5nk7O2ynaPVW0U2W+pt2w\nSVuvdDM5zGv2f9ltNWUiYZHJ1mmO97jSY/6YfdOUH66iRtQtDkHBRdkNBsMbD+Em\n2TgBldtHNSJBfB3pm9FblgOcJ0FSWcUDWJ7vO0+NTXlgrRofRT6pVywzxVo6dND0\nWzYlTWeUVsO40xJqhgUQRER9YLOLxJ0O6C8i0xFxAMKOtSdodMB3RIwt7RFQ0uyt\nn5Z5MqkYhlMI3J1tPRTp1nEt9fyGspBOO05gi148Qasp+3N+svqKomoQglNoAxU=\n-----END CERTIFICATE-----\n"
  }

  let(:cert_hash) {
    {
      'domain_name' => {
        cert: cert, 
        cert_key: OpenSSL::PKey::RSA.new(File.read(cert_key_path))
      }
    }
  }

  after do 
    FileUtils.rm_rf(remove)
  end

  describe '#download_certificate' do 
    context 'when certicate directory does not exist' do 
      it 'writes certificate and its private key to ssl directory' do 
        file_creator.download_certificate(cert_hash)
        files_count = Dir.children(domain_dir).count
        expect(files_count).to eq(2)
      end
    end    
  end
end
