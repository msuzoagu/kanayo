require_relative "../../lib/notification"

RSpec.describe DockerizedAcmeClient::Notification do 

  let(:objet)               { Object.new }
  let(:message)             { "Hello" }
  subject(:notification)    { objet.extend(DockerizedAcmeClient::Notification) }

  describe '#alert' do 

    it 'outputs a message to stdin' do 
      expect{notification.alert(message)}.to output("#{message}\n").to_stdout
    end
  end

  describe '#alert_then_abort' do 
    it 'aborts the program with a message' do 
      expect do 
        expect{notification.alert_then_abort(message)}.to raise_error(SystemExit)
      end.to output("#{message}\n").to_stderr
    end
  end
end
