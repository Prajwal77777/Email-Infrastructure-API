module ApiClients
  class MailuService
    def self.base_client
      base_url = Figaro.env.MAILU_BASE_URL
      api_key = Figaro.env.MAILU_API_KEY

      BaseClient.new(base_url, api_key)
    end

    def self.create_email_account_on_server(email_account)
      url = "/admin/api/v1/users"
      payload = {
        email: "#{email_account[:user]}@#{email_account[:domain_name]}",
        password: email_account[:password],
        name: "#{email_account[:first_name]} #{email_account[:last_name]}"
      }

      response = base_client.perform_request(:post, url, payload)
      unless response[:error]
        raise "Failed to create email account: #{response[:error]}"
      end
    end
  end
end
