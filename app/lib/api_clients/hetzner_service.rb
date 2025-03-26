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
          # Set up mail server
          - umask
          - cd /opt/
          - git clone https://github.com/mailcow/mailcow-dockerized /opt/mailcow-dockerized
          - cd /opt/mailcow-dockerized/
          - chmod +x generate_config.sh
          - ./generate_config.sh
          # Create mailcow.conf file
          - echo "MAILCOW_HOSTNAME=mail.#{domain_name}" > mailcow.conf
          - echo "TZ=UTC" >> mailcow.conf

          # Append additional environment variables
          - echo "DBNAME=mailcow" >> mailcow.conf
          - echo "DBUSER=mailcow" >> mailcow.conf
          - echo "DBPASS=xTXfua5bRPqCsKpliaq0B2W1kVMU" >> mailcow.conf
          - echo "DBROOT=FaoBGlDlSjIHXs9vd8udPmejqvln" >> mailcow.conf
          - echo "REDISPASS=pygB8hOUEX8Uuu8mdGt3DpIB2XFQ" >> mailcow.conf
          - echo "HTTP_PORT=80" >> mailcow.conf
          - echo "HTTP_BIND=" >> mailcow.conf
          - echo "HTTPS_PORT=443" >> mailcow.conf
          - echo "HTTPS_BIND=" >> mailcow.conf
          - echo "HTTP_REDIRECT=n" >> mailcow.conf
          - echo "SMTP_PORT=25" >> mailcow.conf
          - echo "SMTPS_PORT=465" >> mailcow.conf
          - echo "SUBMISSION_PORT=587" >> mailcow.conf
          - echo "IMAP_PORT=143" >> mailcow.conf
          - echo "IMAPS_PORT=993" >> mailcow.conf
          - echo "POP_PORT=110" >> mailcow.conf
          - echo "POPS_PORT=995" >> mailcow.conf
          - echo "SIEVE_PORT=4190" >> mailcow.conf
          - echo "DOVEADM_PORT=127.0.0.1:19991" >> mailcow.conf
          - echo "SQL_PORT=127.0.0.1:13306" >> mailcow.conf
          - echo "REDIS_PORT=127.0.0.1:7654" >> mailcow.conf
          - echo "COMPOSE_PROJECT_NAME=mailcowdockerized" >> mailcow.conf
          - echo "DOCKER_COMPOSE_VERSION=native" >> mailcow.conf
          - echo "ACL_ANYONE=disallow" >> mailcow.conf
          - echo "MAILDIR_GC_TIME=7200" >> mailcow.conf
          - echo "ADDITIONAL_SAN=" >> mailcow.conf
          - echo "AUTODISCOVER_SAN=y" >> mailcow.conf
          - echo "ADDITIONAL_SERVER_NAMES=" >> mailcow.conf
          - echo "SKIP_LETS_ENCRYPT=n" >> mailcow.conf
          - echo "ENABLE_SSL_SNI=n" >> mailcow.conf
          - echo "SKIP_IP_CHECK=n" >> mailcow.conf
          - echo "SKIP_HTTP_VERIFICATION=n" >> mailcow.conf
          - echo "SKIP_UNBOUND_HEALTHCHECK=n" >> mailcow.conf
          - echo "SKIP_CLAMD=n" >> mailcow.conf
          - echo "SKIP_SOGO=n" >> mailcow.conf
          - echo "SKIP_FTS=n" >> mailcow.conf
          - echo "FTS_HEAP=128" >> mailcow.conf
          - echo "FTS_PROCS=1" >> mailcow.conf
          - echo "ALLOW_ADMIN_EMAIL_LOGIN=n" >> mailcow.conf
          - echo "USE_WATCHDOG=y" >> mailcow.conf
          - echo "MAILDIR_SUB=Maildir" >> mailcow.conf
          - echo "SOGO_EXPIRE_SESSION=480" >> mailcow.conf
          - echo "DOVECOT_MASTER_USER=" >> mailcow.conf
          - echo "DOVECOT_MASTER_PASS=" >> mailcow.conf
          - echo "ACME_CONTACT=" >> mailcow.conf
          - echo "WEBAUTHN_ONLY_TRUSTED_VENDORS=n" >> mailcow.conf
          - echo "SPAMHAUS_DQS_KEY=" >> mailcow.conf
          - echo "DISABLE_NETFILTER_ISOLATION_RULE=n" >> mailcow.conf

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
