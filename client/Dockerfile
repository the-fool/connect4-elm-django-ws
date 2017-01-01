FROM node:6

WORKDIR /app
RUN npm i -g elm

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
