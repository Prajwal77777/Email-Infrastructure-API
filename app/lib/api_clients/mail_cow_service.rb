module ApiClients
  class MailCowService
    def self.base_client
      base_url = Figaro.env.MAIL_COW_BASE_URL
      api_key = Figaro.env.MAIL_COW_API_TOKEN

      BaseClient.new(base_url, api_key, :api_key)
    end

    def self.create_email_account_on_server(email_account)
      url = "api/v1/add/mailbox"
      payload = {
      active: "1",
      domain: email_account[:domain],
      local_part: email_account[:local_part],
      name: "#{email_account[:first_name]} #{email_account[:last_name]}",
      password: email_account[:password],
      password2: email_account[:password2],
      quota: "3072",
      force_pw_update: "1",
      tls_enforce_in: "1",
      tls_enforce_out: "1",
      tags: email_account[:tags] || []
    }

      response = base_client.perform_request(:post, url, payload)
      response = response.is_a?(Array) ? response.first : response

      if response[:type] == "danger"
        return { error: response[:msg]&.join(", ") }
      end
      response
    end

    def self.mail_server_status
      url_path = "api/v1/get/status/containers"
      response = base_client.perform_request(:get, url_path)
      response
    end
  end
end
