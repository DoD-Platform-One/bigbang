import crypto from "crypto";
import { Response, NextFunction } from "express";
import { AppRequest } from "./app";
import dotenv from "dotenv";
import fs from "fs";
import jwt from "jsonwebtoken";
import axios from "axios";
dotenv.config();

export const githubSigHeaderName = "X-Hub-Signature-256";
export const gitlabTokenHeaderName = "X-Gitlab-Token";
export const adminTokenHeaderName = "X-Admin-Token";

// generate a private key if one does not exist
let privateKey: string | Buffer = "";
// check if privatekey.pem exists
if (fs.existsSync("privatekey.pem")) {
  privateKey = fs.readFileSync("privatekey.pem");
}
// if not, generate one
else {
  privateKey = crypto.generateKeyPairSync("rsa", {
    modulusLength: 4096,
    publicKeyEncoding: { type: "spki", format: "pem" },
    privateKeyEncoding: { type: "pkcs8", format: "pem" },
  }).privateKey
}

const sigPrefix = "sha256="; //set this to your signature prefix if any
const gitHubSecret = process.env.GITHUB_WEBHOOK_SECRET ?? "";
const gitLabSecret = process.env.GITLAB_WEBHOOK_SECRET ?? "";
const adminDefaultSecret = "";
const adminSecret = process.env.ADMIN_TOKEN ?? adminDefaultSecret;

export const signPayloadJWT = (appId: number) => {
  const payload = {
    // Issued at time
    iat: Math.floor(Date.now() / 1000),
    // JWT expiration time (10 minutes maximum)
    exp: Math.floor(Date.now() / 1000) + 600,
    // GitHub App's identifier
    iss: appId,
  };

  return jwt.sign(payload, privateKey, { algorithm: "RS256" });
};

export const getGitHubAppAccessToken = async (
  appID: number,
  name: string,
  installationId: number
) => {
  const access_token_request_body = JSON.stringify({
    repository: name,
    permissions: { issues: "write", pull_requests: "write" },
  });



  const jwt = await signPayloadJWT(appID);
  // --header "Accept: application/vnd.github+json"
  const access_token_request = await axios.post(
    `https://api.github.com/app/installations/${installationId}/access_tokens`,
    access_token_request_body,
    {
      headers: {
        Authorization: `Bearer ${jwt}`,
        Accept: "application/vnd.github+json",
      },
    }
  );

  return access_token_request.data.token;
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const processWebHookSignature = function (body: any, signature: string) {
  const hmac = crypto.createHmac("SHA256", gitHubSecret);
  const signatureComputed = Buffer.from(
    sigPrefix + hmac.update(body).digest("hex"),
    "utf8"
  );
  return [signatureComputed.toString() === signature, signatureComputed];
};

export const validatePayload = (
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
