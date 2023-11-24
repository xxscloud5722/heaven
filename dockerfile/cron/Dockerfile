FROM ubuntu:23.10
USER root
COPY ./start.sh /usr/local/bin/entrypoint.sh
RUN apt-get update -y && export DEBIAN_FRONTEND=noninteractive && apt-get install -yq tzdata -y && echo 'Asia/Shanghai' >/etc/timezone && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && apt-get install -y cron && cp /etc/pam.d/cron /etc/pam.d/cron.bak && sed -i 's/required/sufficient/g' /etc/pam.d/cron && apt-get install curl vim jq ca-certificates uuid-runtime -y && chmod +x /usr/local/bin/entrypoint.sh
CMD ["sh", "-c", "/usr/local/bin/entrypoint.sh"]