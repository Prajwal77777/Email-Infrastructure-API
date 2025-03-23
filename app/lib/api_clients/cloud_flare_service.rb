module ApiClients
  class CloudFlareService
    def self.base_client
      base_url = Figaro.env.CLOUDFLARE_BASE_URL
      api_key = Figaro.env.CLOUDFLARE_API_KEY

      BaseClient.new(base_url, api_key)
    end

    def self.purchase_domain(domain_name)
      url_path = "/accounts/#{Figaro.env.CLOUDFLARE_ACCOUNT_ID}/registrar/domains"
      payload = {
        domains: [ domain_name ],
        contacts: {
          registrant: {
            name: "#{Figaro.env.CLOUDFLARE_REGISTRAR_NAME}",
            email: "#{Figaro.env.CLOUDFLARE_REGISTRAR_EMAIL}",
            address: "#{Figaro.env.CLOUDFLARE_REGISTRAR_ADDRESS}",
            phone: "#{Figaro.env.CLOUDFLARE_REGISTRAR_PHONE}"
          }
        },
        years: 1,
        privacy: true
      }

      response = base_client.perform_request(:post, url_path, payload)
      if response[:success]
        puts "Domain purchase initiated for #{domain_name}"
        { success: true }
      else
        error_message = response[:error] ? response[:error][:message] : "Unknown error"
        puts "Failed to purchase domain: #{error_message}"
        { error: error_message }
      end
    end

    def self.setup_mail_records(domain_name, server_ip)
      zone_id = get_zone_id(domain_name)
      return { error: "Failed to get Cloudflare Zone ID" } unless zone_id

      records = [
        { type: "A", name: "mail", content: server_ip, ttl: 3600 },
        { type: "MX", name: domain_name, content: "mail.#{domain_name}", priority: 10 },
        { type: "TXT", name: domain_name, content: "v=spf1 mx -all", ttl: 3600 },
        { type: "TXT", name: "_dmarc.#{domain_name}", content: "v=DMARC1; p=reject", ttl: 3600 }
      ]

      records.each do |record|
        url_path = "/zones/#{zone_id}/dns_records"
        base_client.perform_request(:post, url_path, record)
      end

      { message: "Mail records set up successfully" }
    end

    def self.get_zone_id(domain_name)
      url_path = "/zones?name=#{domain_name}"
      response = base_client.perform_request(:get, url_path)
      response[:result]&.first&.dig(:id)
    end
  end
end
