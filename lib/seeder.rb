# frozen_string_literal: true

require_relative 'seeder/version'
require 'thor'
require 'fhir_client'
require 'json'
require 'base64'

module Seeder
  class CLI < Thor
    desc 'seed', 'Seed data into a FHIR server from a bundle or seed directory'
    option :server, required: true, desc: 'FHIR Server URL'
    option :username, desc: 'FHIR Server Username'
    option :password, desc: 'FHIR Server Password'
    option :source, required: true, desc: 'Path to FHIR Bundle JSON or seed directory'
    option :type, required: true, enum: %w[bundle seeds],
                  desc: 'Source type: bundle resource in JSON format or seeds folder with resources in JSON format'
    option :attempts, default: 1, type: :numeric, desc: 'Number of attempts to seed data'

    def seed
      client = FHIR::Client.new(options[:server])
      client.default_json

      if options[:username] && options[:password]
        auth_token = Base64.strict_encode64("#{options[:username]}:#{options[:password]}")
        client.additional_headers = { Authorization: "Basic #{auth_token}" }
      end

      bundle_data = case options[:type]
                    when 'bundle'
                      FHIR::Bundle.new(JSON.parse(File.read(options[:source])))
                    when 'seeds'
                      entries = Dir.glob(File.join(options[:source], '**', '*.json')).map do |json_file_path|
                        { 'resource' => JSON.parse(File.read(json_file_path)) }
                      end
                      FHIR::Bundle.new('resourceType' => 'Bundle', 'entry' => entries)
                    end

      seed_data_from_bundle(client, bundle_data, options[:attempts])
    end

    private

    def seed_data_from_bundle(client, bundle, max_attempts)
      attempts = 0
      resources_to_save = bundle.entry.map(&:resource)

      while attempts < max_attempts
        attempts += 1
        puts "Seed attempt #{attempts} of #{max_attempts}"

        resources_with_problems = []
        resources_to_save.each do |resource|
          if resource
            response = save_to_fhir_server(client, resource)
            resources_with_problems << resource unless response.response[:code].to_i.between?(200, 299)
          else
            puts 'Skipping entry without resource'
          end
        end
        resources_to_save = resources_with_problems
      end
    end

    def save_to_fhir_server(client, resource)
      read_response = client.read(resource.class.name, resource.id)
      if read_response.response[:code].to_i == 404
        response = client.create(resource)
        log_response(response, 'create', resource)
      else
        response = client.update(resource, resource.id)
        log_response(response, 'update', resource)
      end
      response
    end

    def log_response(response, action, resource)
      if response.response[:code].to_i.between?(200, 299)
        puts "Successfully #{action}d: #{resource.resourceType}/#{response.resource&.id}"
      else
        puts "Failed to #{action} #{resource.resourceType}: #{response.response[:code]}"
        puts response.body
      end
    end
  end
end
