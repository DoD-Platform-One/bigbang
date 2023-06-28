FROM node:18

# Create app directory

COPY src /app/src
COPY package.json /app/.
COPY tsconfig.json /app/.
COPY privatekey.pem /app/.
COPY .env /app/.

WORKDIR /app
# config env variables
ENV PORT=8080
RUN echo $PORT > .env
RUN npm install ionic --loglevel verbose
RUN npm run build

EXPOSE $PORT
CMD [ "node", "./lib/index.js" ]
