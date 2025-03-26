class CreateEmailServerJob < ApplicationJob
  queue_as :default

  def perform(domain_name)
    # Step 1: Purchase domain
    # purchase_response = ApiClients::DnsSimpleService.register_domain(domain_name)
    # raise StandardError, purchase_response[:error] if purchase_response[:error]

    # Step 2: Create server on Hetzner
    data = ApiClients::HetznerService.create_server(domain_name)
    raise StandardError, "Server creation failed" unless server_id

    # Step 3: Set up mail records
    # mail_records_response = ApiClients::DnsSimpleService.setup_mail_records(domain_name)
    # raise StandardError, mail_records_response[:error] if mail_records_response[:error]

    { message: "Email server created successfully", data: data }
  rescue StandardError => e
    { error: e.message }
  end
end
