require 'fastlane/action'
require_relative '../helper/buildbox_helper'

module Fastlane
  module Actions
    class BuildboxAction < Action
      def self.run(params)
        require "http"

        UI.message("The BuildBox plugin is working!")

        accepted_formats = [".ipa"]

        filePath = params[:package_path]

        unless accepted_formats.include? File.extname(filePath)
          UI.user_error!("File must be an IPA")
        end

        unless File.exist?(filePath)
          UI.user_error!("File at #{filePath} does not exist")
        end

        baseUri = 'https://buildbox.azurewebsites.net'

        accessHttp = HTTP
          .accept(:json)

        token = params[:token]

        puts "Fetching Access Token"

        accessResponse = accessHttp.get("#{baseUri}/build/accesstoken", :json => {
          :token => token
        })

        unless accessResponse.status.success?
          UI.user_error!("Attempt to authenticate failed, Code: #{accessResponse.code}, Des: #{accessResponse.body}")
        end

        accessResponseBody = JSON.parse(accessResponse.body.to_s)
        accessToken = accessResponseBody["accessToken"]

        file = File.open(filePath)

        puts "Uploading IPA"

        http = HTTP
          .headers("Authorization" => "Bearer #{accessToken}")
          .accept(:json)

        uploadResponse = http.post("#{baseUri}/build", form: { 
          appFile: HTTP::FormData::File.new(file),
          releaseNotes: params[:release_notes],
          projectIdentifier: params[:project_identifier],
          projectDisplay: params[:project_display]
        })

        file.close()

        unless uploadResponse.status.success?
          UI.user_error!("Attempt to upload failed, Code: #{uploadResponse.code}, Des: #{uploadResponse.body}")
        end

        puts "Finished IPA upload"
      end

      def self.description
        "Fastlane plugin to upload builds to BuildBox"
      end

      def self.authors
        ["BuildBox"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        "Fastlane plugin to upload builds to BuildBox"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :token,
                                  env_name: "BUILDBOX_TOKEN",
                               description: "CI Token for auth",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :package_path,
                                  env_name: "BUILDBOX_PACKAGE_PATH",
                               description: "Path to IPA",
                                  optional: false,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :release_notes,
                                  env_name: "BUILDBOX_RELEASE_NOTES",
                               description: "Release notes for this build",
                                  optional: true,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :project_identifier,
                                  env_name: "BUILDBOX_PROJECT_IDENTIFIER",
                                description: "Unique identifier for project",
                                  optional: true,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :project_display,
                                  env_name: "BUILDBOX_PROJECT_DISPLAY",
                               description: "Display name for project",
                                  optional: true,
                                      type: String)
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end
    end
  end
end
