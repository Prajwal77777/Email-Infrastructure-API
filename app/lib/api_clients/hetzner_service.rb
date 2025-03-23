module ApiClients
  class HetznerService
    def self.base_client
      base_url = Figaro.env.HETZNER_BASE_URL
      api_key = Figaro.env.HETZNER_API_KEY

      BaseClient.new(base_url, api_key)
    end

    def self.create_server(domain_name)
      user_data = setup_mail_server_script(domain_name)
      puts "Creating server with user data: #{user_data}"
      payload = {
        name: "main-#{domain_name}",
        server_type: "cx22",
        image: "ubuntu-22.04",
        location: "nbg1",
        ssh_keys: [ Figaro.env.SSH_KEYS_NAME ],
        public_net: { enable_ipv4: true, enable_ipv6: false },
        start_after_create: true,
        user_data: Base64.strict_encode64(user_data)
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
          - path: /var/mail/docker-compose.yml
            permissions: '0644'
            content: |
              services:
                redis:
                  image: redis:alpine
                  restart: always
                development:
                  image: ghcr.io/mailu/setup:master
                  environment:
                    stable_version: 2024.06
                    this_version: master
                    VERSIONS: 2024.06,master
                    ENABLE_API: "true"
                  ports:
                    - 25:25
                    - 587:587
                    - 993:993
                    - 8080:80
                  labels:
                    - traefik.enable=true
                    - traefik.port=80
                    - traefik.docker.network=web
                    - traefik.main.frontend.rule=Host:#{domain_name};PathPrefix:/master
                  depends_on:
                    - redis
                  restart: always
        runcmd:
          - apt update
          - apt install -y docker.io docker-compose
          - systemctl enable docker
          - systemctl start docker
          - mkdir -p /var/mail
          - chmod 777 /var/mail
          - docker-compose -f /var/mail/docker-compose.yml up -d
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
