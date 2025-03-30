class EmailAccountsController < ApplicationController
  def create
    server_config = {
      server_host: Figaro.env.SERVER_HOST_IP,
      ssh_username: Figaro.env.SSH_USER_NAME,
      ssh_key: Figaro.env.SSH_KEY_PATH,
      docker_container: "mailserver"
    }
    email_account_service = ApiClients::EmailAccountService.new(server_config)

    begin
     response = email_account_service.create_email_account(email_account_params)

      render json: { message: "Email account creation initiated.", data: response }, status: :created
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def index
  end

  def mail_server_status
    server_config = {
      server_host: Figaro.env.SERVER_HOST_IP,
      ssh_username: Figaro.env.SSH_USER_NAME,
      ssh_key: Figaro.env.SSH_KEY_PATH,
      docker_container: "mailserver"
    }
    email_account_service = ApiClients::EmailAccountService.new(server_config)

    server_status = email_account_service.check_server_status

    if response[:error]
      render json: { error: response[:error] }, status: :unprocessable_entity
    else

      render json: { status: 200, message: "Mail server is running", data: server_status }, status: :ok
    end
  end

  private

    def email_account_params
      params.permit(:domain, :first_name, :last_name, :password)
    end
end
