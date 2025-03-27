module ApiClients
  class HetznerService
    def self.base_client
      base_url = Figaro.env.HETZNER_BASE_URL
      api_key = Figaro.env.HETZNER_API_KEY

      BaseClient.new(base_url, api_key, :bearer)
    end

    def self.create_server(domain_name)
      user_data = setup_mail_server_script(domain_name)

      payload = {
        name: "#{domain_name}",
        server_type: "cx22",
        image: "ubuntu-24.04",
        location: "nbg1",
        ssh_keys: [ Figaro.env.SSH_KEYS_NAME ],
        public_net: { enable_ipv4: true, enable_ipv6: false },
        start_after_create: true,
        user_data: user_data
     }
      response = base_client.perform_request(:post, "/servers", payload)

      if response[:server]
        server_id = response[:server][:id]
        server_ip = response[:server][:public_net][:ipv4][:ip]
        assign_static_ip(server_id, server_ip)
        { server_id: server_id, server_ip: server_ip }
      else
        error_message = response[:error] ? response[:error][:message] : "Unknown error"
        { error: error_message }
      end
    end

    def self.setup_mail_server_script(domain_name)
      <<~SCRIPT
        #cloud-config
        write_files:
          - path: opt/mailserver/docker-compose.yml
            content: |
              services:
                mailserver:
                  image: ghcr.io/docker-mailserver/docker-mailserver:latest
                  container_name: mailserver
                  hostname: mail.#{domain_name}
                  env_file: mailserver.env
                  ports:
                    - "25:25"    # SMTP  (explicit TLS => STARTTLS, Authentication is DISABLED => use port 465/587 instead)
                    - "143:143"  # IMAP4 (explicit TLS => STARTTLS)
                    - "465:465"  # ESMTP (implicit TLS)
                    - "587:587"  # ESMTP (explicit TLS => STARTTLS)
                    - "993:993"  # IMAP4 (implicit TLS)
                  volumes:
                    - ./docker-data/dms/mail-data/:/var/mail/
                    - ./docker-data/dms/mail-state/:/var/mail-state/
                    - ./docker-data/dms/mail-logs/:/var/log/mail/
                    - ./docker-data/dms/config/:/tmp/docker-mailserver/
                    - /etc/localtime:/etc/localtime:ro
                  restart: always
                  stop_grace_period: 1m
                  healthcheck:
                    test: "ss --listening --tcp | grep -P 'LISTEN.+:smtp' || exit 1"
                    timeout: 3s
                    retries: 0
        runcmd:
          - apt-get update && apt upgrade -y
          - apt install -y ca-certificates curl gnupg
          - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
          - echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
          - apt update
          - apt install -y docker-ce docker-ce-cli containerd.io
          - sudo usermod -aG docker $USER
          - sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
          - sudo chmod +x /usr/local/bin/docker-compose
          - sleep 30
          - systemctl enable docker
          - systemctl start docker
          - sleep 10
          - mkdir -p /opt/mailserver/data /opt/mailserver/config
          - cd /opt/mailserver
          - wget "https://raw.githubusercontent.com/docker-mailserver/docker-mailserver/master/mailserver.env"

          - docker-compose pull
          - docker-compose up -d
          - sleep 300
      SCRIPT
    end

    def self.assign_static_ip(server_id, server_ip)
      payload = {
        "type": "ipv4",
        "description": "Static IP for server #{server_id}",
        "home_location": "nbg1",
        "server": server_id
      }

      response = base_client.perform_request(:post, "/floating_ips", payload)
      if response[:floating_ip]
        puts "Static IP assigned successfully: #{response[:floating_ip]}"
      else
        {
          error: "Failed to assign static IP: #{response[:error]}"
        }
      end
    end
  end
end
