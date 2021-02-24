describe Fastlane::Actions::BuildboxAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The buildbox plugin is working!")

      Fastlane::Actions::BuildboxAction.run(nil)
    end
  end
end
