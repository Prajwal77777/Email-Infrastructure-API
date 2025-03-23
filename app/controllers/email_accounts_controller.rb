class EmailAccountsController < ApplicationController
  def create
    response =ApiClients::MailuService.create_email_account_on_server(email_account_params)

    if response[:error]
      render json: { error: response[:error] }, status: :unprocessable_entity
    else
      render json: { message: "Email account created successfully", email_account: response }, status: :created
    end
  end

  private

    def email_account_params
      params.require(:email_account).permit(:user, :password, :domain_name, :first_name, :last_name)
    end
end
