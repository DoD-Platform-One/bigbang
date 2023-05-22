import crypto from 'crypto'
import {Response, NextFunction} from 'express'
import { AppRequest } from './app';
import dotenv from 'dotenv'
import fs from 'fs'
import jwt from 'jsonwebtoken'
dotenv.config();

export const githubSigHeaderName = 'X-Hub-Signature-256';
export const gitlabTokenHeaderName = 'X-Gitlab-Token';
export const adminTokenHeaderName = 'X-Admin-Token';

const privateKey = fs.readFileSync('privatekey.pem');

const sigPrefix = 'sha256='; //set this to your signature prefix if any
const gitHubSecret = process.env.GITHUB_WEBHOOK_SECRET ?? "";
const gitLabSecret = process.env.GITLAB_WEBHOOK_SECRET ?? "";
const adminDefaultSecret = ""
const adminSecret = process.env.ADMIN_TOKEN ?? adminDefaultSecret;
const appId = process.env.APP_ID ?? "";


export const signPayloadJWT = () => {
  
  const payload = {
    // Issued at time
    iat: Math.floor(Date.now() / 1000),
    // JWT expiration time (10 minutes maximum)
    exp: Math.floor(Date.now() / 1000) + 600,
    // GitHub App's identifier
    iss: appId
  };

  return jwt.sign(payload, privateKey, { algorithm: 'RS256'});
}

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
