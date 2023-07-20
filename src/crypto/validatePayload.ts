import { NextFunction, Response } from "express";
import { AppRequest } from "../app.js";
import { githubSigHeaderName, gitlabTokenHeaderName, adminTokenHeaderName, processWebHookSignature } from "./appcrypto.js";


const gitLabSecret = process.env.GITLAB_WEBHOOK_SECRET ?? "";
const adminDefaultSecret = "";
const adminSecret = process.env.ADMIN_TOKEN ?? adminDefaultSecret;

const validatePayload = (
    req: AppRequest,
    res: Response,
    next: NextFunction
  ) => {
    const githubSignature = req.get(githubSigHeaderName);
    const gitlabToken = req.get(gitlabTokenHeaderName);
    const adminToken = req.get(adminTokenHeaderName);
  
    req.admin = false;
    if (adminToken === adminSecret && adminToken !== adminDefaultSecret) {
      req.admin = true;
      return next();
    }
  
    if (!githubSignature && !gitlabToken) {
      return res.status(401).send({ message: "signature required" });
    }
  
    if (githubSignature) {
      const [isVerified, signatureComputed] = processWebHookSignature(
        req.rawBody,
        githubSignature
      );
      if (!isVerified) {
        return res.status(401).send({
          message: {
            githubSignature,
            signatureComputed: signatureComputed.toString(),
            body: req.body,
          },
        });
      }
    } else {
      if (gitlabToken !== gitLabSecret) {
        return res.status(401).send({
          message: `Invaild Token`,
        });
      }
    }
    return next();
  };

  export default validatePayload;