require "dnsimple"

module ApiClients
  class DnsSimpleService
    def initialize
      @client = Dnsimple::Client.new(base_url: "#{Figaro.env.DNS_SIMPLE_BASE_URL}", access_token: "#{Figaro.env.DNS_SIMPLE_API_KEY}")
      @account_id = Figaro.env.DNS_SIMPLE_ACCOUNT_ID
    end

    def check_domain_availability(domain_name)
      response = @client.registrar.check_domain(@account_id, domain_name)
      response
    rescue Dnsimple::RequestError => e
      { error: "Error checking domain availability: #{e.message}" }
    end

    def get_registrant_id
      response = @client.contacts.list_contacts(@account_id)
      return response.data.first.id if response.data.any?

      { error: "No registrant found. Please create a registrant first." }
    rescue Dnsimple::RequestError => e
      { error: "Error fetching registrant: #{e.message}" }
    end

    def register_domain(domain_name)
      availability = check_domain_availability(domain_name)

      domain_data = availability.data
      unless domain_data.available
        { error: "Domain #{domain_name} is not available for registration." }
      end
      registrant_id = get_registrant_id

      response = @client.registrar.register_domain(@account_id, domain_name, registrant_id: registrant_id)

      { message: "Domain registration successful and setup mail records", data: response.data }
    rescue Dnsimple::RequestError => e
      { error: "Error registering domain: #{e.message}" }
    end

    def get_zone_id(domain_name)
      response = @client.zones.list_zones(@account_id)
      zone = response.data.find { |zone| zone.name == domain_name }
      zone ? zone.id : { error: "Zone not found for domain #{domain_name}" }
    rescue Dnsimple::RequestError => e
      { error: "Error fetching zone ID: #{e.message}" }
    end

    def setup_mail_records(domain_name, server_ip)
      zone_id = get_zone_id(domain_name)
      return { error: "Zone ID not found for #{domain_name}" } unless zone_id

      mail_records = [
        { type: "A", name: "mail", content: "#{server_ip}", ttl: 3600 },
        { type: "MX", name: domain_name, content: "mail.#{domain_name}", priority: 10 },
        { type: "TXT", name: "_dmarc", content: "v=DMARC1; p=reject; rua=mailto:support@#{domain_name}; ruf=mailto:dmarc@#{domain_name}; fo=1" }
      ]

      mail_records.each do |record|
        @client.zones.create_zone_record(@account_id, zone_id, record)
      end
      { success: "Mail records added successfully for #{domain_name}" }
    rescue Dnsimple::RequestError => e
      { error: "Error setting up mail records: #{e.message}" }
    end
  end
end
