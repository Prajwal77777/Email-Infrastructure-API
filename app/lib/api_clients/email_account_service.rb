require "net/ssh"
module ApiClients
  class EmailAccountService
    IMAP_PORT = 143
    SMTP_PORT = 587

    def initialize(server_config)
      @server_host = Figaro.env.SERVER_HOST_IP
      @ssh_username = Figaro.env.SSH_USER_NAME
      @ssh_key = Figaro.env.SSH_KEY_PATH
      @docker_container = "mailserver"
    end

    def create_email_account(params)
      email = generate_email(params[:first_name], params[:last_name], params[:domain])
      password = params[:password]

      execute_email_account_creation(email, password, params[:domain])
      build_account_response(
        email:,
        password:,
        first_name: params[:first_name],
        last_name: params[:last_name],
        domain: params[:domain]
      )
    end

    def check_server_status
      command = "docker inspect -f '{{.State.Status}}' #{@docker_container}"
      begin
        Net::SSH.start(@server_host, @ssh_username, keys: [ @ssh_key ]) do |ssh|
          result = ssh.exec!(command).strip
          return result
        end
      rescue Net::SSH::AuthenticationFailed
        "SSH Authentication failed"
      rescue StandardError => e
        puts "Error getting Docker container state: #{e.message}"
        "unknown"
      end
    end

    private
    def generate_email(first_name, last_name, domain)
      sanitized_first = first_name.downcase.gsub(/[^a-z]/, "")
      sanitized_last = last_name.downcase.gsub(/[^a-z]/, "")

      "#{sanitized_first}.#{sanitized_last}@#{domain}"
    end

    def execute_domain_setup(domain)
      ssh_command("docker exec #{@docker_container} setup email domain add #{domain}")
    end

    def execute_email_account_creation(email, password, domain)
      command = "docker exec #{@docker_container} setup email add #{email} #{password} --domain #{domain}"
      Net::SSH.start(@server_host, @ssh_username, keys: [ @ssh_key ]) do |ssh|
        result = ssh.exec!(command)

        raise "Account creation failed: #{result}" unless result.nil? || result.strip.empty?
      end
    rescue Net::SSH::AuthenticationFailed
      raise "SSH Authentication failed"
    rescue StandardError => e
      raise "Email account creation error: #{e.message}"
    end

    def build_account_response(email:, password:, first_name:, last_name:, domain:)
      {
        user: email,
        password: password,
        name: "#{first_name} #{last_name}",
        imap_server_credentials: {
          server: "mail.#{domain}",
          port: IMAP_PORT,
          protocol: "IMAP",
          security: "STARTTLS",
          server_ip: @server_host
        },
        smtp_server_credentials: {
          server: "mail.#{domain}",
          port: SMTP_PORT,
          protocol: "SMTP",
          security: "STARTTLS",
          server_ip: @server_host
        },
        additional_info: {
          first_name: first_name,
          last_name: last_name,
          domain: domain
        }
      }
    end
  end
end
