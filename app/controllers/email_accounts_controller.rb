class EmailAccountsController < ApplicationController
  def create
    response = ApiClients::MailCowService.create_email_account_on_server(email_account_params)
    puts "================#{response}"
    if response[:error]
      render json: { error: response[:error] }, status: :unprocessable_entity
    else
      render json: { message: "Email account created successfully", email_account: response }, status: :created
    end
  end

  def mail_server_status
    response = ApiClients::MailCowService.mail_server_status
    if response[:error]
      render json: { error: response[:error] }, status: :unprocessable_entity
    else
      filtered_status = response.slice(:'postfix-mailcow', :'dovecot-mailcow')

      render json: { message: "Mail server is running", data: filtered_status }, status: :ok
    end
  end

  private

    def email_account_params
      params.require(:email_account).permit(:local_part, :domain, :first_name, :last_name, :password, :password2, tags: [])
    end
end
