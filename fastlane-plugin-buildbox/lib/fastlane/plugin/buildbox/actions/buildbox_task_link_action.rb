require 'fastlane/action'
require_relative '../helper/buildbox_helper'

module Fastlane
  module Actions
    class BuildboxTaskLinkAction < Action
      def self.run(params)
        require "http"

        UI.message("The BuildBox plugin is working!")

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

        puts "Linking project and task"

        http = HTTP
          .headers("Authorization" => "Bearer #{accessToken}")
          .accept(:json)

        linkResponse = http.post("#{baseUri}/task/#{params[:task_id]}/link", :json => { 
          :projectIdentifier => params[:project_identifier]
        })

        unless linkResponse.status.success?
          UI.user_error!("Attempt to link failed, Code: #{linkResponse.code}, Des: #{linkResponse.body}")
        end

        puts "Finished project task link"
      end

      def self.description
        "Fastlane plugin to link a project and task in BuildBox"
      end

      def self.authors
        ["BuildBox"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        "Fastlane plugin to link a project and task in BuildBox"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :token,
                                  env_name: "BUILDBOX_TOKEN",
                              description: "CI Token for auth",
                                  optional: false,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :project_identifier,
                                  env_name: "BUILDBOX_PROJECT_IDENTIFIER",
                               description: "Unique identifier for project",
                                  optional: false,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :task_id,
                                  env_name: "BUILDBOX_TASK_ID",
                               description: "Task ID for project management tool to associate with this project",
                                  optional: false,
                                      type: String)
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end
    end
  end
end
