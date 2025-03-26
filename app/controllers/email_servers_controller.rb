class EmailServersController < ApplicationController
  def create
    domain_name = params[:domain_name]

    server_id, server_ip = ApiClients::HetznerService.create_server(domain_name)
    raise StandardError, "Server creation failed" unless server_id
    render json: { message: "Email server creation in progress", server_ip: }, status: :accepted
  end
end
