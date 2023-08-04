import express from 'express'
import validatePayload from "./crypto/validatePayload.js"
import { emitEvent } from './events/eventManager.js'
import {eventNames} from './events/eventManagerTypes.js'
import "./events/pullRequest.js"
import "./events/mergeRequests.js"
import "./events/comment.js"
import "./events/pipeline.js"
import RepoSyncError from './errors/RepoSyncError.js';
import { debug, warn } from './utils/console.js'

debug(`Registered events: \n\t${eventNames.join("\n\t")}`)

// App
const app = express();
// disable x-powered-by header for one extra layer of security through obscurity
app.disable('x-powered-by')

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

app.post('/test', (_, res) => {
  res.status(200)
  res.send("hello world")
})

// Error handler
app.use((err: Error | RepoSyncError , req: AppRequest, res: express.Response, next: express.NextFunction) => {
  if (err instanceof RepoSyncError) {
    err.consoleFunction(err.message)
    err.effectFunction()
    res.status(err.status).send(err.message)
    return next()
  }else {
    warn(`Something broke: ${err.message}`)
    res.status(500).send(`Something broke: ${err.message}`)
    return next()
  }
})


export default app
