FROM alpine:latest
EXPOSE 8080
WORKDIR /app
COPY files/* /app/
ENV UUID=0e059fce-d6c8-4cc2-9e11-9efff358f8b9
ENV ARGO_AUTH=eyJhIjoiYWQ1NDUwYTgyNTI0M2VhZTE5Y2E0ODI4MWQxNTRiZjIiLCJ0IjoiNzc0YzcxZGMtNmJlMC00YTk0LTg1NWEtMzEzNjgwNzBkYzUyIiwicyI6Ik9HTmlOMlF4WVdZdE16RTROQzAwTmpjNExXSmtZekl0TVRjNU1UQTBZbUU1WTJGbSJ9
ENV ARGO_DOMAIN=vl2.k-fans.com.ar
ENV SSH_DOMAIN=vsh2.k-fans.com.ar
ENV WEB_USERNAME=admin
ENV WEB_PASSWORD=admin*2023*

RUN apk update &&\
    apk add iproute2 npm nodejs bash curl &&\
    npm install -r package.json &&\
    npm install -g pm2 &&\
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 &&\
    mv cloudflared-linux-amd64 cloudflared &&\
    chmod +x web.js cloudflared

ENTRYPOINT [ "node", "app.js" ]