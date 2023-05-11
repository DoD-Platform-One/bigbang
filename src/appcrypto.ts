import crypto from 'crypto'
import {Response, NextFunction} from 'express'
import { AppRequest } from './app';
import dotenv from 'dotenv'
dotenv.config();

export const githubSigHeaderName = 'X-Hub-Signature-256';
export const gitlabTokenHeaderName = 'X-Gitlab-Token';
export const adminTokenHeaderName = 'X-Admin-Token';

const sigPrefix = 'sha256='; //set this to your signature prefix if any
const gitHubSecret = process.env.GITHUB_WEBHOOK_SECRET ?? "";
const gitLabSecret = process.env.GITLAB_WEBHOOK_SECRET ?? "";
const adminDefaultSecret = ""
const adminSecret = process.env.ADMIN_TOKEN ?? adminDefaultSecret;


export const processWebHookSignature = function (body: any , signature: any) {
  const hmac = crypto.createHmac('SHA256', gitHubSecret)
  const signatureComputed = Buffer.from(sigPrefix + hmac.update(body).digest('hex'), 'utf8')
  return [signatureComputed.toString() === signature, signatureComputed]
}

export const validatePayload = (req: AppRequest, res: Response, next: NextFunction) => {
    
    const githubSignature = req.get(githubSigHeaderName)
    const gitlabToken = req.get(gitlabTokenHeaderName)
    const adminToken = req.get(adminTokenHeaderName)
    
    req.admin = false
    if(adminToken === adminSecret && adminToken !== adminDefaultSecret){
      req.admin = true
      return next()
    }
    
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
      if(gitlabToken !== gitLabSecret){
        return res.status(401).send({
          message: `Invaild Token`
        })
      }
    }
    return next()
}
