class EmailServersController < ApplicationController
  def create
    domain_name = params[:domain_name]

    CreateEmailServerJob.perform_later(domain_name)
    render json: { message: "Email server creation in progress" }, status: :accepted
  end
end
