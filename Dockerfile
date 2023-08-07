FROM registry1.dso.mil/ironbank/opensource/nodejs/nodejs18:18.17.0 AS builder

# Create app directory
USER root
RUN mkdir -p /app
WORKDIR /app
COPY package.json /app/.
RUN npm install
COPY src /app/src
COPY tsconfig.json /app/.
COPY privatekey.pem /app/.
COPY .env /app/.
COPY certs /app/certs
RUN npm run build

# config env variables
ENV NODE_ENV production
ENV PORT=9000
RUN echo $PORT > .env

EXPOSE $PORT
USER node

CMD [ "node", "./lib/index.js" ]
