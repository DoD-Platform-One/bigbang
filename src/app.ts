import express from 'express'
import { validatePayload } from "./appcrypto.js"
import adminRouter from './routes/admin.js';
import fs from 'fs'
import path from 'path'

import {format} from 'prettier'

import { createContext, emitter } from './events/eventManager.js'
import "./events/pullRequest.js"
import "./events/comment.js"

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
//Validate payload middleware
app.use(validatePayload)



//Gitlab webhook events

app.post('/repo-sync', async (req, res) => {
  // crete the context object for webhook consumption
  const context = await createContext(req.headers, req.body)
  if (!context){
    res.send("Not Supported")
  }

  // for events
  if (context.instance == 'github' || context.instance == 'gitlab') {
    emitter.emit(context.event, context)
    res.send("OK")
  }

  res.send("Not Supported")
})

app.post('/record', async (req) => {
  const context = await createContext(req.headers, req.body)
  if (!context){
    return
  }
  const filepath = path.join(__dirname, '..', 'test', 'fixtures', `${context.instance}-${context.event}.json`)
  const data = format(JSON.stringify(req.body), { parser: "json" })
  fs.writeFileSync(filepath, data, { flag: 'w' });
})

app.post('/test', (req, res) => {
  res.send("hello world")
})

app.use(adminRouter)

export default app
