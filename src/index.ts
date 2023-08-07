import serverless from 'serverless-http'
import app from './app.js'
import dotenv from 'dotenv'

dotenv.config();

  
const serverType = process.env.SERVER_TYPE ?? "express"
const port = process.env.PORT ?? "8080"


//verify status of httpsApp

export const handler = serverless(app)
if (serverType == "express") {
    console.log("starting application to listen on port: " + port);
    app.listen(port)
}
