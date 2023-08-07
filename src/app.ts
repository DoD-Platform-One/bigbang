import express from 'express'
import validatePayload from "./crypto/validatePayload.js"
import { emitEvent } from './events/eventManager.js'
import "./events/pullRequest.js"
import "./events/mergeRequests.js"
import "./events/comment.js"
import "./events/pipeline.js"
import ResponseError from './errors/ResponseError.js';

// App
const app = express();

// setting up a raw body and admin values
export interface AppRequest extends express.Request {
  rawBody: string
  admin: boolean
}

app.get("/health", (_, res) => {
  res.status(200) 
  return res.send("OK")
})
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

app.post('/test', (_, res) => {
  res.status(200)
  res.send("hello world")
})

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
