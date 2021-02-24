#!/bin/bash
#install openresty on directory /opt ,the directory include sbin log pid
#install prepare

install_dir=/opt/openresty
nginx_dir=${install_dir}/nginx
config_dir=/${install_dir}/nginx/conf
log_dir=${install_dir}/nginx/logs
pid_file=${log_dir}/nginx.pid
echo "install_dir ${install_dir}.nginx_dir ${nginx_dir},config_dir ${config_dir},log_dir ${log_dir},pid_file ${pid_file}"


if [[ ! -e ${install_dir} ]]; then
    echo -e "install directory ${install_dir} not Found,auto create it"
    mkdir ${install_dir}
fi
if [[ ! -e ${nginx_dir} ]]; then
    echo -e "ngconf directory ${nginx_dir} not Found,auto create it"
    mkdir ${nginx_dir}
fi


[ -d ${install_dir}/bin ] && PATH=$PATH:${install_dir}/bin
[ -d ${install_dir}/nginx/sbin ] && PATH=$PATH:${install_dir}/nginx/sbin
export PATH
#logrotate.conf
cat <<
echo "Please add a fllow line to the ~/.bashrc or ~/.zshrc;export PATH=${install_dir}/bin:$PATH"

#vi auto/cc/gcc
#debug

cd ./openresty-1.19.3.1/
./configure \
  --prefix=${install_dir} \
  --conf-path=${nginx_dir}/nginx.conf \  
  --user=nginx --group=nginx \
  --with-compat \
  --with-file-aio \
  --with-threads \
  --with-http_addition_module \
  --with-http_auth_request_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_mp4_module \
  --with-http_random_index_module \
  --with-http_realip_module \
  --with-http_secure_link_module \
  --with-http_slice_module \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_sub_module \
  --with-http_v2_module \
  --with-stream 
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-http_iconv_module \
  --with-pcre \
  --with-pcre-jit \
  --with-luajit \
  --with-ld-opt=-ljemalloc \
  --without-mail \
  --without-mail_pop3_module \
  --without-mail_imap_module \
  --without-mail_smtp_module \
  --add-module=./ngx_brotli \
  --add-module=./ngx_cache_purge \
  --add-module=./nginx-module-vts \
  #--add-module=./nginx-upsync-module-2.1.3 \
  #--add-module=./nginx_upstream_check_module \
  #--add-module=./ngx_http_substitutions_filter_module \

cat >>/etc/systemd/system/openresty.service <<-EOF
[Unit]
Description=openresty
After=syslog.target network.target

[Service]
Type=forking
PIDFile=${pid_file}
ExecStartPre=${nginx_dir}/sbin/nginx -t -q -g 'pid ${pid_file}; daemon on; master_process on;'
ExecStart={nginx_dir}/sbin/nginx -g 'pid ${pid_file}; daemon on; master_process on;'
ExecReload={nginx_dir}/sbin/nginx -g 'pid ${pid_file}; daemon on; master_process on;' -s reload
ExecStop={nginx_dir}/sbin/nginx -g 'pid ${pid_file}; daemon on; master_process on;' -s quit
[Install]
WantedBy=multi-user.target
EOF

cat >>/etc/logrotate.d/nginx <<-EOF
${log_dir}/*.log {
    daily
    missingok
    sharedscripts
    compress
    delaycompress
    postrotate
    rotate 60
    test -r ${pid_file} && kill -USER1 'cat ${pid_file}'
}
EOF
