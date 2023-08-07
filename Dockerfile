FROM registry1.dso.mil/ironbank/opensource/nodejs/nodejs18:18.17.0 AS builder

# config env variables
ENV NODE_ENV=production
ENV PORT=9000
ENV ENVIRONMENT=production

# Create app directory
USER root
RUN mkdir -p /app && yum install -y git
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

EXPOSE $PORT

CMD [ "node", "./lib/index.js" ]
