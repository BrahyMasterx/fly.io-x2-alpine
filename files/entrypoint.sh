#!/usr/bin/env bash

# Set variables
UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
WEB_USERNAME=${WEB_USERNAME:-'admin'}
WEB_PASSWORD=${WEB_PASSWORD:-'password'}

generate_config() {
  cat > config.json << EOF
{
	"log": {
		"loglevel": "none"
	},
	"inbounds": [{
		"port": 8080,
		"protocol": "vless",
		"settings": {
			"clients": [{
				"id": "${UUID}"
			}],
			"decryption": "none"
		},
		"streamSettings": {
			"network": "ws"
		}
	}],
	"outbounds": [{
		"protocol": "freedom",
		"settings": {}
	}]
}
EOF
}

generate_argo() {
  cat > argo.sh << ABC
#!/usr/bin/env bash

argo_type() {
  if [[ -n "\${ARGO_AUTH}" && -n "\${ARGO_DOMAIN}" ]]; then
    [[ \$ARGO_AUTH =~ TunnelSecret ]] && echo \$ARGO_AUTH > tunnel.json && cat > tunnel.yml << EOF
tunnel: \$(cut -d\" -f12 <<< \$ARGO_AUTH)
credentials-file: /app/tunnel.json
protocol: auto

ingress:
  - hostname: \$ARGO_DOMAIN
    service: http://localhost:8080
EOF

    [ -n "\${SSH_DOMAIN}" ] && cat >> tunnel.yml << EOF
  - hostname: \$SSH_DOMAIN
    service: http://localhost:2222
EOF

    cat >> tunnel.yml << EOF
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF

  else
    ARGO_DOMAIN=\$(cat argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
  fi
}

argo_type
export_list
ABC
}

generate_ttyd() {
  cat > ttyd.sh << EOF
#!/usr/bin/env bash

# Check if running
check_run() {
  [[ \$(pgrep -lafx ttyd) ]] && echo "ttyd running" && exit
}

# ssh argo 
check_variable() {
  [ -z "\${SSH_DOMAIN}" ] && exit
}

# download the latest version ttyd
download_ttyd() {
  if [ ! -e ttyd ]; then
    URL=\$(wget -qO- "https://api.github.com/repos/tsl0922/ttyd/releases/latest" | grep -o "https.*x86_64")
    URL=\${URL:-https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64}
    wget -O ttyd \${URL}
    chmod +x ttyd
  fi
}

check_run
check_variable
download_ttyd
EOF
}

generate_pm2_file() {
  if [[ -n "${ARGO_AUTH}" && -n "${ARGO_DOMAIN}" ]]; then
    [[ $ARGO_AUTH =~ TunnelSecret ]] && ARGO_ARGS="tunnel --edge-ip-version auto --config tunnel.yml run"
    [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]] && ARGO_ARGS="tunnel --edge-ip-version auto --protocol auto run --token ${ARGO_AUTH}"
  else
    ARGO_ARGS="tunnel --edge-ip-version auto --no-autoupdate --protocol auto --logfile argo.log --loglevel info --url http://localhost:8080"
  fi


  cat > ecosystem.config.js << EOF
module.exports = {
  "apps":[
      {
          "name":"web",
          "script":"/app/web.js run"
      },
      {
          "name":"argo",
          "script":"/app/cloudflared",
          "args":"${ARGO_ARGS}"
EOF
  
  [ -n "${SSH_DOMAIN}" ] && cat >> ecosystem.config.js << EOF
      },
      {
          "name":"ttyd",
          "script":"/app/ttyd",
          "args":"-c ${WEB_USERNAME}:${WEB_PASSWORD} -p 2222 bash"
EOF

  cat >> ecosystem.config.js << EOF
      }
  ]
}
EOF
}

generate_config
generate_argo
generate_ttyd
generate_pm2_file
[ -e argo.sh ] && bash argo.sh
[ -e ttyd.sh ] && bash ttyd.sh
[ -e ecosystem.config.js ] && pm2 start
