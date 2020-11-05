# frozen_string_literal: true

require 'openssl'
require 'faraday'
require 'base64'
require 'json'

class Api
  def initialize(endpoint: ENV['API_ENDPOINT'], access_token: ENV['ACCESS_TOKEN'], logger: nil)
    @endpoint = endpoint
    @access_token = access_token
    @connection = build_connection
    @logger = logger
    @logs_enabled = !!logger
  end

  attr_reader :endpoint, :access_token, :logger, :logs_enabled

  VERBS = %i[get post put patch delete].freeze

  VERBS.each do |verb|
    define_method(verb) do |*args|
      send_request(verb, *args)
    end
  end

  def enable_logs!
    @logs_enabled = true
  end

  def disable_logs!
    @logs_enabled = false
  end

  protected

  def build_connection
    Faraday.new(endpoint, ssl: { verify_mode: OpenSSL::SSL::VERIFY_NONE }) do |faraday|
      faraday.use Faraday::Adapter::NetHttp
    end
  end

  attr_reader :connection

  def send_request(verb, path, payload = {})
    debug "#{verb.upcase} #{path}"

    response = connection.send(verb, path) do |request|
      request.headers.merge!(request_headers)
      request.body = payload.to_json
    end

    response.body.empty? ? {} : JSON.parse(response.body)
  end

  def request_headers
    { 'Content-Type' => 'application/json; charset=utf-8', 'Authorization' => "Bearer #{Base64.encode64(access_token)}" }
  end

  %i[debug info warn error fatal unknown].each do |log_level|
    define_method(log_level) do |*args, &block|
      return unless logger && logs_enabled
      logger.public_send(log_level, *args, &block)
    end
  end
end
