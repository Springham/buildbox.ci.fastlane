require 'fastlane/action'
require_relative '../helper/buildbox_helper'

module Fastlane
  module Actions
    class BuildboxAction < Action
      def self.run(params)
        require "http"

        platformName = lane_context[SharedValues::PLATFORM_NAME]

        UI.message("BuildBox upload plugin initiated. Platform: #{platformName}")

        if platformName == "ios"
          accepted_formats = [".ipa"]
        elsif platformName == "android"
          accepted_formats = [".apk"]
        else
          UI.user_error!("Unknown platform")
        end

        filePath = params[:package_path]

        unless accepted_formats.include? File.extname(filePath)
          UI.user_error!("File must be an IPA for iOS and APK for Android")
        end

        unless File.exist?(filePath)
          UI.user_error!("File at #{filePath} does not exist")
        end

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

        puts "Reserving Upload"

        reserveUploadResponse = http
          .get("#{baseUri}/build/reserveupload", :json => {
          })

        unless reserveUploadResponse.status.success?
          UI.user_error!("Attempt to reserve upload failed, Code: #{accessResponse.code}, Des: #{accessResponse.body}")
        end

        reserveUploadResponseBody = JSON.parse(reserveUploadResponse.body.to_s)
        uploadUrl = reserveUploadResponseBody["uploadUrl"]
        uploadName = reserveUploadResponseBody["uploadID"]

        puts "Reserved Upload. Upload Name: #{uploadName}"

        puts "Uploading blob"

        file = File.open(filePath)

        fileUploadResponse = HTTP.headers("x-ms-blob-type" => "BlockBlob")
          .put(uploadUrl, body: File.new(file))

        unless fileUploadResponse.status.success?
          UI.user_error!("Attempt to upload build file failed, Code: #{accessResponse.code}, Des: #{accessResponse.body}")
        end

        file.close()

        puts "Uploaded blob"

        puts "Registering upload"

        registerUploadResponse = http.post("#{baseUri}/build/registerupload", :json => {
          :uploadName => uploadName,
          :platform => platformName,
          :releaseNotes => params[:release_notes],
          :projectIdentifier => params[:project_identifier],
          :projectDisplay => params[:project_display],
          :taskIDs => params[:task_ids]
        })

        unless registerUploadResponse.status.success?
          UI.user_error!("Attempt to register upload failed, Code: #{accessResponse.code}, Des: #{accessResponse.body}")
        end

        puts "Registered upload"

        puts "Finished Upload"
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
                               description: "Path to app package (ipa or apk)",
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
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :task_ids,
                                  env_name: "BUILDBOX_TASK_IDS",
                               description: "Task IDs added in this build",
                                  optional: true,
                                      type: Array)
        ]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end
  end
end
