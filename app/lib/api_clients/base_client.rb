require "httparty"

module ApiClients
  class BaseClient
    include HTTParty

    attr_accessor :base_url, :api_key

    def initialize(base_url, api_key)
      @base_url = base_url
      @api_key = api_key
    end

    def perform_request(method, url_path, payload = {})
      url = "#{base_url}#{url_path}"
      puts "Sending Request to #{url}"

      headers = {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Authorization" => "Bearer #{@api_key}"
      }

      response = HTTParty.send(method, url, headers: headers, body: payload.to_json)

      JSON.parse(response.body, symbolize_names: true)
    rescue HTTParty::Error => e
      if e&.response&.body&.present?
        { error: "#{JSON.parse(e.response.body, symbolize_names: true)[:message]}.", detail: e.inspect }
      else
        { error: "Error: #{e.message}", detail: e.inspect }
      end
    end
  end
end
