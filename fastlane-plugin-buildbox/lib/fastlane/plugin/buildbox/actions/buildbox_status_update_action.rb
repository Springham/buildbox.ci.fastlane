require 'fastlane/action'
require_relative '../helper/buildbox_helper'

module Fastlane
  module Actions
    class BuildboxStatusUpdateAction < Action
      def self.run(params)
        require "http"

        UI.message("TestShip status update initiated")

        baseUri = 'https://buildbox.azurewebsites.net'

        puts "Fetching Access Token"

        accessResponse = HTTP
          .accept(:json)
          .get("#{baseUri}/build/accesstoken", :json => {
            :token => params[:token]
          })

        unless accessResponse.status.success?
          UI.user_error!("Attempt to authenticate failed, Code: #{accessResponse.code}, Des: #{accessResponse.body}")
        end

        accessResponseBody = JSON.parse(accessResponse.body.to_s)
        accessToken = accessResponseBody["accessToken"]

        puts "Fetched Access Token"

        http = HTTP
          .headers("Authorization" => "Bearer #{accessToken}")
          .accept(:json)

        puts "Registering upload"

        statusResponse = http.post("#{baseUri}/build/status", :json => {
          :version => params[:version],
          :buildNumber => params[:build_number],
          :releaseNotes => params[:release_notes],
          :updateType => params[:update_type],
          :platform => params[:platform],
          :appIdentifier => params[:app_identifier],
          :projectIdentifier => params[:project_identifier]
        })

        unless statusResponse.status.success?
          UI.user_error!("Attempt to register upload failed, Code: #{statusResponse.code}, Des: #{statusResponse.body}")
        end

        puts "Registered upload"

        puts "Finished Upload"
      end

      def self.description
        "Fastlane plugin to update build statuses in TestShip"
      end

      def self.authors
        ["TestShip"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        "Fastlane plugin to update build statuses in TestShip"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :token,
                                  env_name: "TESTSHIP_TOKEN",
                               description: "CI Token for auth",
                                  optional: false,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :version,
                                  env_name: "TESTSHIP_VERSION",
                                description: "Version text",
                                  optional: false,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :build_number,
                                  env_name: "TESTSHIP_BUILD_NUMBER",
                                description: "Build number",
                                  optional: false,
                                      type: Integer),                                      

          FastlaneCore::ConfigItem.new(key: :release_notes,
                                  env_name: "BUILDBOX_RELEASE_NOTES",
                               description: "Release notes for this build",
                                  optional: true,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :update_type,
                                  env_name: "BUILDBOX_UPDATE_TYPE",
                                description: "Update type, either Queued or Started",
                                  optional: false,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :platform,
                                  env_name: "BUILDBOX_PLATFORM",
                               description: "iOS or Android",
                                  optional: true,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                  env_name: "BUILDBOX_APP_IDENTIFIER",
                               description: "App identifier",
                                  optional: true,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :project_identifier,
                                  env_name: "BUILDBOX_PROJECT_IDENTIFIER",
                                description: "Project identifier",
                                  optional: true,
                                      type: String)
        ]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end
  end
end
