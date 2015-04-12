# References used:
# https://github.com/phusion/baseimage-docker
# http://nginx.org/en/docs/configure.html
# http://xmodulo.com/compile-install-nginx-web-server.html
# https://docs.google.com/spreadsheet/ccc?key=0AjuNPnOoex7SdG5fUkhfc3BCSjJQbVVrQTg4UGU2YVE
# https://github.com/arut/nginx-rtmp-module/
FROM phusion/baseimage:0.9.16
MAINTAINER nakanaa

# Set correct environment variables
ENV REFRESHED_AT 13.04.2015
ENV HOME /root
WORKDIR $HOME

ENV NGINX_VERSION 1.7.10
ENV RTMP_MODULE_VERSION v1.1.6

RUN \
  buildDeps="\
    unzip \
    make \
    # For SSL module
    libssl-dev \
    # For zlib module
    zlib1g-dev \
    # For PCRE module
    libpcre3-dev \ 
    # For Image Filter module
    libgd2-xpm-dev \
    # For XSLT module
    libxslt1-dev \
    # For GeoIP module
    libgeoip-dev \
  "; \
  runDeps="\
    # For Image Filter module
    libgd3 \
    # For XSLT module
    libxml2 \
    libxslt1.1 \
    # For GeoIP module
    libgeoip1 \
  "; \
  apt-get -q -y update && DEBIAN_FRONTEND=noninteractive apt-get -q -y install \
    $buildDeps \
    $runDeps && \
  # Download Nginx
  curl -LO http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  # Extract Nginx
  tar -xvf *.tar.gz && \
  mv nginx-*/ nginx/ && \
  rm *.tar.gz && \
  # Download RTMP module
  curl -LO https://github.com/arut/nginx-rtmp-module/archive/${RTMP_MODULE_VERSION}.zip && \
  # Extract RTMP module
  unzip *.zip && \
  mv nginx-rtmp-module-*/ nginx-rtmp-module/ && \
  rm *.zip && \
  # Go to Nginx directory
  cd nginx/ && \
  # Configure
  ./configure \
    --prefix=/usr/local/nginx \
    --sbin-path=/usr/local/nginx/nginx \
    --conf-path=/usr/local/nginx/nginx.conf \
    --pid-path=/usr/local/nginx/nginx.pid \
    --lock-path=/usr/local/nginx/nginx.lock \
    --error-log-path=/dev/stderr \
    --http-log-path=/dev/stdout \
    --user=www-data \
    --group=www-data \
    --with-debug \
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_geoip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_spdy_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_xslt_module \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-pcre \
    --with-pcre-jit \
    --add-module=/root/nginx-rtmp-module && \
  # Make
  make && \
  # Install
  make install && \
  # Clean up
  make clean && \
  # Go back to parent directory
  cd .. && \
  # Clean up downloaded files
  rm -rf * && \
  # Clean up unneeded packages when done
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps && \
  # Clean up APT when done
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd -r nginx

RUN curl -L https://raw.githubusercontent.com/nakanaa/conf-fetcher/master/conf-fetcher.sh -o /etc/my_init.d/01_conf-fetcher.sh && chmod +x /etc/my_init.d/01_conf-fetcher.sh

# Use baseimage-docker's init system
ENTRYPOINT ["/sbin/my_init", "--"]

# Define default command
CMD ["/usr/local/nginx/nginx", "-g", "daemon off;"]