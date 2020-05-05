FROM nginx
RUN chmod g+rwx /var/cache/nginx /var/run /var/log; \
    sed -i.bak 's/^user/#user/' /etc/nginx/nginx.conf; \
    rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/nginx.conf
EXPOSE 3008
