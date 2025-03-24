class EmailAccountsController < ApplicationController
  def create
    response =ApiClients::MailuService.create_email_account_on_server(email_account_params)

    if response[:error]
      render json: { error: response[:error] }, status: :unprocessable_entity
    else
      render json: { message: "Email account created successfully", email_account: response }, status: :created
    end
  end

  def mail_server_status
    if mail_server_running?
      render json: { status: "running" }, status: :ok
    else
      render json: { status: "stopped" }, status: :ok
    end
  end

  private

    def email_account_params
      params.require(:email_account).permit(:user, :password, :domain_name, :first_name, :last_name)
    end

    def mail_server_running?
      # Check if the Docker container named 'mailserver' is running
      system('docker ps --filter "name=mailserver" --format "{{.Status}}" | grep -q "Up"')
    end
end
