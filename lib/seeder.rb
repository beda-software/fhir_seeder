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
    option :connect_attempts_limit, default: 20, type: :numeric,
                                    desc: 'Number of attempts to connect to the target server'
    option :sleep, default: 10, type: :numeric, desc: 'Speep between connect attempts'

    def seed
      client = establish_client
      authentificate_client(client) if options[:username] && options[:password]
      bundle = bundle_data
      seed_data_from_bundle(client, bundle, options[:attempts])
    end

    private

    def establish_client
      connect_attempts = 0
      max_attempts = options[:connect_attempts_limit]
      sleep_time = options[:sleep]

      client = FHIR::Client.new(options[:server])

      loop do
        if connect_attempts >= max_attempts
          raise "Failed to establish connection after #{connect_attempts} attempts"
        end

        connect_attempts += 1
        puts "Connection attempt ##{connect_attempts} of #{max_attempts}..."

        begin
          client.capability_statement
          return client
        rescue Errno::ECONNREFUSED => e
          puts "Connection failed: #{e.message}. Retrying in #{sleep_time} seconds..."
          sleep sleep_time
        end
      end
    end


    def authentificate_client(client)
      auth_token = Base64.strict_encode64("#{options[:username]}:#{options[:password]}")
      client.additional_headers = { Authorization: "Basic #{auth_token}" }
    end

    def bundle_data
      case options[:type]
      when 'bundle'
        FHIR::Bundle.new(JSON.parse(File.read(options[:source])))
      when 'seeds'
        entries = Dir.glob(File.join(options[:source], '**', '*.json')).map do |json_file_path|
          { 'resource' => JSON.parse(File.read(json_file_path)) }
        end
        FHIR::Bundle.new('resourceType' => 'Bundle', 'entry' => entries)
      end
    end

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

        break if resources_with_problems.empty?

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
