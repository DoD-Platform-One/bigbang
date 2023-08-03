import serverless from 'serverless-http'
import { checkEnv } from './utils/environment.js';
import dotenv from 'dotenv'
import { success, Underscore } from './utils/console.js';
dotenv.config();
checkEnv()


// import app from './app.js'

// lazy load the express app until after env checks are done
const {default: app} = await import('./app.js')
const serverType = process.env.SERVER_TYPE ?? "express"
const port = process.env.PORT ?? "8080"

// Check that the environment is set up correctly

export const handler = serverless(app)

if (serverType == "express") {
    success("starting application to listen on port: " + Underscore + port);
    app.listen(port)
}
