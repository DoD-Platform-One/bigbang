import express from 'express'
import { validatePayload } from "./appcrypto"
import adminRouter from './routes/admin';
import fs from 'fs'
import path from 'path'

import {format} from 'prettier'

import { createContext, emitter } from './events/eventManager'
import "./events/pullRequest"
import "./events/comment"

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

app.post('/repo-sync', async (req) => {
  // crete the context object for webhook consumption
  const context = await createContext(req.headers, req.body)
  if (!context){
    return
  }

  // for events
  if (context.instance == 'github' || context.instance == 'gitlab') {
    emitter.emit(context.event, context)
  }

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
