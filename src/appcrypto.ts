import crypto from 'crypto'
import {Response, NextFunction} from 'express'
import { RawBodyReq } from './app';


export const githubSigHeaderName = 'X-Hub-Signature-256';
export const gitlabTokenHeaderName = 'X-Gitlab-Token'

const sigPrefix = 'sha256='; //set this to your signature prefix if any
const github_secret = process.env.GITHUB_WEBHOOK_SECRET;
const gitlab_token = process.env.GITLAB_WEBHOOK_SECRET;


export const processWebHookSignature = function (body: any , signature: any) {
  const hmac = crypto.createHmac('SHA256', github_secret)
  const signatureComputed = Buffer.from(sigPrefix + hmac.update(body).digest('hex'), 'utf8')
  return [signatureComputed.toString() === signature, signatureComputed]
}

export const validatePayload = (req: RawBodyReq, res: Response, next: NextFunction) => {
    
    const githubSignature = req.get(githubSigHeaderName)
    const gitlabToken = req.get(gitlabTokenHeaderName)
    
    if(!githubSignature && !gitlabToken){
        return res.status(401).send({message: "signature required"})
      }

    if(githubSignature){
      const [isVerified, signatureComputed] =  processWebHookSignature(req.rawBody, githubSignature)
      if(!isVerified){
        return res.status(401).send({
          message: {githubSignature,
                    signatureComputed: signatureComputed.toString(),
                    body: req.body
                   }
        });
      }
    }
    else{
      if(gitlabToken !== gitlab_token){
        return res.status(401).send({
          message: `Invaild Token`
        })
      }
    }
    return next()
}
