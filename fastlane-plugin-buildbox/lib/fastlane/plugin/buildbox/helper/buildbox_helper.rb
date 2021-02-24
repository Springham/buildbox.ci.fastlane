require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class BuildboxHelper
      # class methods that you define here become available in your action
      # as `Helper::BuildboxHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the buildbox plugin helper!")
      end
    end
  end
end
