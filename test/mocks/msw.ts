// src/mocks/server.js
import { setupServer } from 'msw/node';
import { rest, graphql} from 'msw';

// This configures a request mocking server with the given request handlers.
const server = setupServer();

export { server, rest, graphql };
