import express from 'express'
import {validatePayload} from "./appcrypto"
import adminRouter from './routes/admin';
import fs from 'fs'
import path from 'path'

// App
const app = express();

// setting up a raw body and admin values
export interface AppRequest extends express.Request {
  rawBody: string
  admin: boolean
}

app.use(
  express.json({
  verify: function (req: AppRequest, res, buf) {
    req.rawBody = buf.toString()
  }
})
)

app.use(validatePayload)

//Validate payload middleware

app.post('/Repo_Sync', (req,res) => {
  console.log(req.body);
  
  res.send("Hello Repo Sync")
})

app.post('/record', (req, res) => {
  const filename = `${req.headers['x-github-event']}.${req.body.action}.json`
  // make a path to the root director of the project and then add the path to the test/fixtures folder
  const filepath = path.join(__dirname, '..', 'test', 'fixtures', filename)
  
  fs.writeFileSync(filepath, JSON.stringify(req.body), {flag: 'ax'});
})

app.post('/test', (req,res) => {
  res.send("hello world")
})

app.use(adminRouter)

export default app
