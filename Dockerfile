FROM registry1.dso.mil/ironbank/opensource/nodejs/nodejs18:18.17.0 AS builder

ENV NODE_ENV=production
ENV PORT=9000
ENV ENVIRONMENT=production

# Create app directory
USER root
RUN mkdir -p /app
WORKDIR /app
COPY package.json /app/.
COPY src /app/src
COPY tsconfig.json /app/.
COPY privatekey.pem /app/.
COPY .env /app/.

RUN chown -R node:node /app

USER node
RUN npm install
RUN npm run build

# config env variables

EXPOSE $PORT

CMD [ "node", "./lib/index.js" ]
