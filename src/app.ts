import express from 'express'

import {validatePayload} from "./appcrypto"

// App
const app = express();

// setting up a raw body
export interface RawBodyReq extends express.Request {
  rawBody: string
}

app.use(
  express.json({
  verify: function (req: RawBodyReq, res, buf) {
    req.rawBody = buf.toString()
  }
})
)

app.use(validatePayload)

//Validate payload middleware

app.post('/Repo_Sync', (req,res) => {
  res.send(req.body)
})

app.post('/test', (req,res) => {
  res.send("hello world")
})

export default app