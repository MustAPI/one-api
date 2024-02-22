#!/bin/bash

# azure 服务器初始化

export DEBIAN_FRONTEND=noninteractive
sudo apt update #&& apt upgrade -o Dpkg::Options::='--force-confold' -y

sudo apt install -y lrzsz
sudo apt install -y locales
sudo locale-gen en_US.UTF-8
sudo localectl set-locale LANG=en_US.UTF-8

# dpkg-reconfigure locales
sudo apt install -y dnsutils

echo "net.ipv4.tcp_fin_timeout = 30
net.ipv4.ip_local_port_range = 10240 65535
net.ipv4.tcp_tw_reuse = 1" >/etc/sysctl.d/99-coolproxy.conf
sudo sysctl -p /etc/sysctl.d/99-coolproxy.conf

ulimit -n 65535

echo "root soft nofile 655350
root hard nofile 655350
www-data soft nofile 655350
www-data hard nofile 655350" >/etc/security/limits.d/coolproxy.conf

# nginx
sudo apt install -y nginx

# logrotate
# vim /etc/logrotate.d/nginx
# cat /etc/cron.daily/logrotate
# systemctl status logrotate

#echo "/var/log/nginx/*.log {
#        hourly
#        missingok
#        rotate 48
#        compress
#        delaycompress
#        dateext
#        dateformat .%Y%m%d%H
#        notifempty
#        create 0640 www-data adm
#        sharedscripts
#        prerotate
#                if [ -d /etc/logrotate.d/httpd-prerotate ]; then \\
#                        run-parts /etc/logrotate.d/httpd-prerotate; \\
#                fi \\
#        endscript
#        postrotate
#                invoke-rc.d nginx rotate >/dev/null 2>&1
#        endscript
#}" >/etc/logrotate.d/nginx

# doesn't work. logrotate is configured to use systemd timer
# cp /etc/cron.daily/logrotate /etc/cron.hourly/
# systemctl restart cron

# systemctl list-timers
# systemctl edit logrotate.timer

# run the logrotate systemd timer hourly

#mkdir -p /etc/systemd/system/logrotate.timer.d
#echo "[Unit]
#Description=Daily rotation of log files
#Documentation=man:logrotate(8) man:logrotate.conf(5)
#
#[Timer]
#OnCalendar=hourly
#AccuracySec=1min
#Persistent=true
#
#[Install]
#WantedBy=timers.target
#" >/etc/systemd/system/logrotate.timer.d/override.conf
#systemctl daemon-reload

# or use the interactive editor
# systemctl edit logrotate.timer

# to check the timer status
# systemctl status logrotate.timer

# change the editor
# update-alternatives --config editor

mycoolproxy_io_crt=$(cat <<EOF
-----BEGIN CERTIFICATE-----
MIIDWTCCAkGgAwIBAgIJANzCqcUj8fN3MA0GCSqGSIb3DQEBCwUAMB4xCzAJBgNV
BAYTAlVTMQ8wDQYDVQQDDAZSb290Q0EwHhcNMjMxMTE0MDgwOTM4WhcNMjQxMjE1
MDgwOTM4WjAmMQswCQYDVQQGEwJVUzEXMBUGA1UEAwwObXljb29scHJveHkuaW8w
ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCy/tO0DjAiFXdjS/w39zD1
PyWZr63W431+QvdQNtIOBe1wDaaSCVzs9NTV5F65C28Y5a1soOupzHLtufR8Bd7W
V5yBM6Kuujlr/wSIWLqCsaAGHLe4ps6dzIU5poTeHP0xKeji88sN1WWCRT5a6lF2
TGVb3Eo+gnUQmKsRQiM9Uz9ndPFoL8pwdfK92b6L9d1PsnaY6zA8A8lqxoip3JZU
MrR5vESu4gziKXAiX/fQVJkRpcgMs+2E0S2S3eXpo8usWB9FslQ5qoWOBDuWzzDC
3CrVOZS7oALR9UyQXPHizYrpADm4oxV0lsqjn3h/w2RuW6LGRpeVipqLWDCEfP0H
AgMBAAGjgZEwgY4wOAYDVR0jBDEwL6EipCAwHjELMAkGA1UEBhMCVVMxDzANBgNV
BAMMBlJvb3RDQYIJANB6Ot0RBB9mMAkGA1UdEwQCMAAwCwYDVR0PBAQDAgTwMBsG
A1UdEQQUMBKCECoubXljb29scHJveHkuaW8wHQYDVR0OBBYEFG5gHlXfd/cAs0DG
be7Ov9sp0K7+MA0GCSqGSIb3DQEBCwUAA4IBAQCuI4Mgl4J2HaVfu8WXCtt3OsAQ
mK2PAq6+cyd8kahJWlcw2UkqTXCbH1PSRNePAo4gUBDRlKm2JJVD9GciJjRrt+4O
zAFVZeyOJTy2TSjsSyJh8lZ+XBTronjB1KoZEYVQAcDb+JTU8sZEHNum7L1S9JaW
gvLfZCdXZJmR2s9bd4D3z5ZuoQLGVfygXXRY60Sy4nM3Sx3xG8MQFXYlzAyHL0Dw
9K0cxqKVhpSXn+CSSjc4cyYZvPUys2EoOWnP/UsY6kIhF3DnJWqmWZ+Ox9aJkuXs
mFx3Zm8VLoiCbiwLkNlHcslK4S2SiFEp20xpDy17zKfnPjCstrtM9R0biW28
-----END CERTIFICATE-----
EOF
)

mycoolproxy_io_key=$(cat <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEpgIBAAKCAQEAsv7TtA4wIhV3Y0v8N/cw9T8lma+t1uN9fkL3UDbSDgXtcA2m
kglc7PTU1eReuQtvGOWtbKDrqcxy7bn0fAXe1lecgTOirro5a/8EiFi6grGgBhy3
uKbOncyFOaaE3hz9MSno4vPLDdVlgkU+WupRdkxlW9xKPoJ1EJirEUIjPVM/Z3Tx
aC/KcHXyvdm+i/XdT7J2mOswPAPJasaIqdyWVDK0ebxEruIM4ilwIl/30FSZEaXI
DLPthNEtkt3l6aPLrFgfRbJUOaqFjgQ7ls8wwtwq1TmUu6AC0fVMkFzx4s2K6QA5
uKMVdJbKo594f8NkbluixkaXlYqai1gwhHz9BwIDAQABAoIBAQClWaw9r8GdKtFg
BCiZlps+YrgcUeK4GOyrv7bw/cNruuQNWD7gtw+FweH/OPib3kkh6cIcEEfDUp90
pgyIqW+h98sWu5lz6Yn0Dt+kCLs60lVucAbz5/wEX5NOn1osSQFH8lw1k1qni9M6
1TZ2C/F247nacxSOzDrSOwYEamFdWsWiDVdETJBpjl6hGxLhk8KRm08QN+W08+kG
YFeX78bhAjOOXJ3z3lYxM5Gw095Xzs4ZT7rPyfEPpTqcRZAmrFcKi2opjCL+4Uwl
YXH9F6X8yShdeLG7/cQPkl3O5hvOsPFF9Wg3Mczx8jAt6HYDi7csmZKDR8FxScKo
3O5T1FdBAoGBAOpQIR6fs26YQE9l7lqOx6XUmnwoMqo9+nZk5GfzQQDftX5BY4Cn
gqAsDuZue8cV2oiwndRbZ1LRgTh3sPpL1qFabAybbdrYqw0sZYLuGybaNyRSlM3n
0lvlCbJDG5exErymlosY+jadCqVrZjzRnSqRB1MybQwGUJLgjE9+yxFnAoGBAMOP
/SmO+4qxKgNVYAsZHaPmJv/b7EKI+rknV5nY23tnZsS/xOryO6nkTSzUYY/EJq11
1yZbU1ugBCsSqJC3/sJCp7uE8N6QRH0EZScFh5rZPDdZ/X+/N3iVXu8+WZvEXjjT
1n6QU6+bJXwAZDZbRFFH6BF3E+Ic/v3GI85ygVNhAoGBALFNNvKMV+NM9ATgla8S
sYILUWa3qDboNTkXeToreLmnjhdedWOp3Y9EJ3Y4jhMEt1uNgbBqBdJGU+idsV6E
uoFYAcC8cDEUmMKcIKglcohAwU8L6iuwyp3cvyyT2TI8vHfh+rKAkP14cdDgZvmI
h8vo+Ej9NETQFnI91g5lXFXrAoGBAJ/lzlg5iWBIJRLero3EdmC5YO/YkJ+CQoY7
Lbwj/Kk0zWlXZxm2/6OUgKmD6VVUS0+Ox2CcUVbcSiwxsFPLrWiGeYCwXQWNLgKO
Imq6cbrhngOf986IuUFF2H6DG19qOqP6SSnothQiJY7y/v0WuJBA2/XTyBUcIj26
0TIOm8FhAoGBANB8UH0VLfUhAW1EE7PVteeyOIo+rMdNIKzU/o7bn5fZXFwSzgEV
6Ij/n/VrYDbJ3BZgO5mxmIKLGWcP8/GNnHACzir7ZNB7tobzJu93+3ZU4ELzSFwZ
t2/XHBv0O35el0zwQUjyHKpG/AMJJtv83kTmVGkLVk9YnsWD2usSznJk
-----END RSA PRIVATE KEY-----
EOF
)

mycoolproxy_conf=$(cat <<'EOF'
log_format mycoolproxy '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" '
                    'host:"$host" proxy_host:"$proxy_host" upstream_addr:"$upstream_addr" request_time:"$request_time" up_resp_time:"$upstream_response_time" up_header_time":$upstream_header_time"';

server {
    listen       80;
    listen       443 ssl;
    server_name  az.mycoolproxy.io;

    ssl_certificate mycoolproxy.io.crt;
    ssl_certificate_key mycoolproxy.io.key;

    access_log   /var/log/nginx/az.access.log  mycoolproxy;

    # allows large request body for multi-modality
    client_max_body_size 100M;

    resolver 1.1.1.1 208.67.222.222 208.67.220.220 8.8.8.8 valid=600s;

    location ~* ^/az/https://?(.*)$ {
        set $azurl $1;

        if ($http_api_key = '') {
            return 403;
        }

        proxy_intercept_errors off;

        # only pass white listed headers to upstream
        proxy_pass_request_headers off;
        proxy_set_header Content-Type $http_content_type;
        proxy_set_header api-key $http_api_key;
        proxy_set_header User-Agent 'python-requests/2.25.1';


        proxy_set_header x-version '';
        proxy_set_header Authorization '';

        proxy_connect_timeout 1800s;
        proxy_read_timeout 1800s;
        proxy_send_timeout 1800s;
        proxy_http_version 1.1;
        proxy_set_header Connection '';

        proxy_pass 'https://$azurl?$args';
        proxy_ssl_server_name on;
        proxy_buffering off;

    }

    location = /hello {
        return 200 "hello. I'm $host";
    }

    location / {
        return 403;
    }
}
EOF
)
cat > /etc/nginx/mycoolproxy.io.key <<EOF
$mycoolproxy_io_key
EOF
cat > /etc/nginx/mycoolproxy.io.crt <<EOF
$mycoolproxy_io_crt
EOF
cat > /etc/nginx/sites-enabled/mycoolproxy.conf <<EOF
$mycoolproxy_conf
EOF
