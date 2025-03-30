class EmailServersController < ApplicationController
  def create
    domain_name = params[:domain_name]

    response = ApiClients::HetznerService.create_server(domain_name)
    puts "this is server ip====#{response}"
    raise StandardError, "Server creation failed" unless response[:server_id]

    dns_service = ApiClients::DnsSimpleService.new
    mail_setup = dns_service.setup_mail_records(domain_name, response[:server_ip])

    render json: { message: "Email server creation in progress", server_ip: response[:server_ip], data: mail_setup }, status: :accepted
  end

  def buy_domain
    domain_name = params[:domain_name]
    dns_service = ApiClients::DnsSimpleService.new
    response = dns_service.register_domain(domain_name)

    render json: { message: "Domain is registered", data: response }, status: :created
  end

  def setup_mail_records
    dns_service = ApiClients::DnsSimpleService.new
    response = dns_service.setup_mail_records("prajwal.tech", "195.201.145.67")
    render json: { message: "Mail record setup completed", data: response }
  end
end
