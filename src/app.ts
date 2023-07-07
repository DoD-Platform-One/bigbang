import express from 'express'
import { validatePayload } from "./appcrypto.js"
import adminRouter from './routes/admin.js';
import fs from 'fs'
import path from 'path'

import {format} from 'prettier'

import { createContext, emitEvent } from './events/eventManager.js'
import "./events/pullRequest.js"
import "./events/mergeRequests.js"
import "./events/comment.js"
import ResponseError from './errors/ResponseError.js';

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
app.post('/repo-sync', async (req, res, next) => {
  emitEvent(req, res, next)  
})


app.post('/record', async (req, res, next) => {
  const context = await createContext(req.headers, req.body, res, next)
  if (!context){
    return
  }
  const __dirname = path.resolve(path.dirname(''));
  const filepath = path.join(__dirname, 'test', 'fixtures', `${context.instance}-${context.event}.json`)
  const data = format(JSON.stringify(req.body), { parser: "json" })
  fs.writeFileSync(filepath, data, { flag: 'w' });
})

app.post('/test', (req, res) => {
  res.send("hello world")
})

app.use(adminRouter)

// Error handler
app.use((err: Error | ResponseError, req: AppRequest, res: express.Response, next: express.NextFunction) => {
  if (err instanceof ResponseError) {
    res.status(err.status).send(err.message)
    return next()
  }else {  
    res.status(500).send('Something broke!')
    return next()
  }
})


export default app
