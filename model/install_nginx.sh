#安装nginx
 yum install nginx -y


 #直接生成nginx配置
CONF_NGINX=/etc/nginx/nginx.conf

 echo " " > ${CONF_NGINX}
 echo "" >> ${CONF_NGINX}

 echo "user nginx;" >> ${CONF_NGINX}
 echo "worker_processes auto;" >> ${CONF_NGINX}
 echo "error_log /var/log/nginx/error.log;" >> ${CONF_NGINX}
 echo "pid /run/nginx.pid;" >> ${CONF_NGINX}
 echo "include /usr/share/nginx/modules/*.conf;" >> ${CONF_NGINX}
 echo "events {worker_connections 2048;}" >> ${CONF_NGINX}
 echo "http {" >> ${CONF_NGINX}
 echo "   log_format  main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '" >> ${CONF_NGINX}
 echo "                      '\$status \$body_bytes_sent \"\$http_referer\" '" >> ${CONF_NGINX}
 echo "                      '\"\$http_user_agent\" \"\$http_x_forwarded_for\"';" >> ${CONF_NGINX}
 echo "   access_log  /var/log/nginx/access.log  main;" >> ${CONF_NGINX}
 echo "   resolver 	      8.8.8.8;" >> ${CONF_NGINX}
 echo "   sendfile            on;" >> ${CONF_NGINX}
 echo "   tcp_nopush          on;" >> ${CONF_NGINX}
 echo "   tcp_nodelay         on;" >> ${CONF_NGINX}
 echo "   keepalive_timeout   65;" >> ${CONF_NGINX}
 echo "   types_hash_max_size 4096;" >> ${CONF_NGINX}
 echo "   include             /etc/nginx/mime.types;" >> ${CONF_NGINX}
 echo "   default_type        application/octet-stream;" >> ${CONF_NGINX}
 echo "   include /etc/nginx/conf.d/*.conf;" >> ${CONF_NGINX}
 echo "   server {" >> ${CONF_NGINX}
 echo "        listen 80;" >> ${CONF_NGINX}
 echo "        server_name localhost;" >> ${CONF_NGINX}
 echo "        location ~* ^/az/https://?(.*)$ {" >> ${CONF_NGINX}
 echo "        set \$azurl \$1;" >> ${CONF_NGINX}
 echo "        proxy_intercept_errors off;" >> ${CONF_NGINX}
 echo "        proxy_pass 'https://\$azurl?\$args';" >> ${CONF_NGINX}
 echo "        proxy_ssl_server_name on;" >> ${CONF_NGINX}
 echo "        proxy_buffering off;" >> ${CONF_NGINX}
 echo "                autoindex_localtime on;" >> ${CONF_NGINX}
 echo "                proxy_connect_timeout 2000s;" >> ${CONF_NGINX}
 echo "                proxy_read_timeout 2000s;" >> ${CONF_NGINX}
 echo "                proxy_send_timeout 2000s;" >> ${CONF_NGINX}
 echo "        }" >> ${CONF_NGINX}
 echo "        error_page 500 502 503 504 /50x.html;" >> ${CONF_NGINX}
 echo "        location = /50x.html {" >> ${CONF_NGINX}
 echo "                root html;" >> ${CONF_NGINX}
 echo "        }" >> ${CONF_NGINX}
 echo "    }" >> ${CONF_NGINX}
 echo "}" >> ${CONF_NGINX}
 echo "" >> ${CONF_NGINX}


 #启动nginx
service nginx start
