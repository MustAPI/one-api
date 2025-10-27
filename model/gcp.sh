# 设置配置文件路径
CONF_NGINX=/etc/nginx/nginx.conf

# 清空并写入新的配置
echo "user nginx;" > ${CONF_NGINX}
echo "worker_processes auto;" >> ${CONF_NGINX}
echo "error_log /var/log/nginx/error.log;" >> ${CONF_NGINX}
echo "pid /run/nginx.pid;" >> ${CONF_NGINX}
echo "include /usr/share/nginx/modules/*.conf;" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}
echo "events {worker_connections 2048;}" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}
echo "http {" >> ${CONF_NGINX}
echo "    log_format  main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '" >> ${CONF_NGINX}
echo "                      '\$status \$body_bytes_sent \"\$http_referer\" '" >> ${CONF_NGINX}
echo "                      '\"\$http_user_agent\" \"\$http_x_forwarded_for\"';" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}
echo "    access_log  /var/log/nginx/access.log  main;" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}
echo "    resolver 8.8.8.8;" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}
echo "    sendfile            on;" >> ${CONF_NGINX}
echo "    tcp_nopush          on;" >> ${CONF_NGINX}
echo "    tcp_nodelay         on;" >> ${CONF_NGINX}
echo "    keepalive_timeout   65;" >> ${CONF_NGINX}
echo "    types_hash_max_size 4096;" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}
echo "    include             /etc/nginx/mime.types;" >> ${CONF_NGINX}
echo "    default_type        application/octet-stream;" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}
echo "    include /etc/nginx/conf.d/*.conf;" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}
echo "    server {" >> ${CONF_NGINX}
echo "        listen 80;" >> ${CONF_NGINX}
echo "        server_name localhost;" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}
echo "        # ======== 修改开始 ========" >> ${CONF_NGINX}
echo "        # 匹配 /az/http:/... 或 /az/https:/... (Nginx合并斜杠后的结果)" >> ${CONF_NGINX}
echo "        location ~* ^/az/(https?):/(.*)$ {" >> ${CONF_NGINX}
echo "            # 捕获协议 (http 或 https)" >> ${CONF_NGINX}
echo "            set \$az_protocol \$1;" >> ${CONF_NGINX}
echo "            # 捕获余下的URL (例如 www.google.com)" >> ${CONF_NGINX}
echo "            set \$az_url \$2;" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}
echo "            proxy_intercept_errors off;" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}
echo "            # 重新组合成 'https://www.google.com?query_args'" >> ${CONF_NGINX}
echo "            proxy_pass \$az_protocol://\$az_url?\$args;" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}
echo "            # 必须设置Host头，否则目标服务器不知道请求的哪个域名" >> ${CONF_NGINX}
echo "            proxy_set_header Host \$az_url;" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}
echo "            proxy_ssl_server_name on;" >> ${CONF_NGINX}
echo "            proxy_buffering off;" >> ${CONF_NGINX}
echo "            autoindex_localtime on; # 你原来配置中的行" >> ${CONF_NGINX}
echo "            proxy_connect_timeout 2000s;" >> ${CONF_NGINX}
echo "            proxy_read_timeout 2000s;" >> ${CONF_NGINX}
echo "            proxy_send_timeout 2000s;" >> ${CONF_NGINX}
echo "        }" >> ${CONF_NGINX}
echo "        # ======== 修改结束 ========" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}
echo "        error_page 500 502 503 504 /50x.html;" >> ${CONF_NGINX}
echo "        location = /50x.html {" >> ${CONF_NGINX}
echo "            root html;" >> ${CONF_NGINX}
echo "        }" >> ${CONF_NGINX}
echo "    }" >> ${CONF_NGINX}
echo "}" >> ${CONF_NGINX}
echo "" >> ${CONF_NGINX}

echo "Nginx 配置文件已生成：${CONF_NGINX}"

 #启动nginx
service nginx start
