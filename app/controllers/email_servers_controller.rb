class EmailServersController < ApplicationController
  def create
    domain_name = params[:domain_name]

    # purchase_response = ApiClients::HetznerService.purchase_domain(domain_name)
    # return render json: { error: purchase_response[:error] }, status: :unprocessable_entity if purchase_response[:error]

    server_id, server_ip = ApiClients::HetznerService.create_server(domain_name)
    return render json: { error: "Server creation failed" }, status: :bad_request unless server_id

    # mail_records_response = ApiClients::CloudFlareService.setup_mail_records(domain_name, server_ip)
    # return render json: { error: mail_records_response[:error] }, status: :unprocessable_entity if mail_records_response[:error]

    render json: { message: "Email server created successfully", server_id: server_id, server_ip: server_ip }, status: :created
  end
end
