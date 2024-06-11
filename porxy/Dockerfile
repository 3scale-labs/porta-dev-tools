FROM nginx

RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/nginx.conf

RUN apt-get update && apt-get -y install iputils-ping

CMD ["nginx", "-g", "daemon off;"]

EXPOSE 3008
