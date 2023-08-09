import serverless from 'serverless-http'
import { checkEnv } from './utils/environment/environment.js';
import { success } from './utils/console.js';
import dotenv from 'dotenv'

dotenv.config();

await checkEnv()


// lazy load the express app until after env checks are done
const {default: app} = await import('./app.js')
const serverType = process.env.SERVER_TYPE ?? "express"
const port = process.env.PORT ?? "8080"

export const handler = serverless(app)
if (serverType == "express") {
    success("starting application to listen on port: " + port);
    app.listen(port)
}
