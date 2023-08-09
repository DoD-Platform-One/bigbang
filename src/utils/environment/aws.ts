import {S3Client, GetObjectCommand, PutObjectCommand, GetBucketVersioningCommand} from '@aws-sdk/client-s3'
import fs from 'fs'
import dotenv from 'dotenv'
import { log, error } from '../console.js'
import S3BucketError from '../../errors/S3BucketError.js';
dotenv.config();

const client = new S3Client({})


export const checkAWSConnection = async () => {
    log("Checking AWS Connection");
    const command = new GetBucketVersioningCommand({
        Bucket: process.env.AWS_BUCKET,
    })
    try{
        await client.send(command)
        log("AWS Connection Successful")
        return true
    }catch(err){
        error(err.message)
        return false
    }
}

export const getProjectMapFile = async () => {
    log("Getting Project Map File")
  const command = new GetObjectCommand({
    Bucket: process.env.AWS_BUCKET,
    Key: "project_map.json"
  });

  try {
    const response = await client.send(command);
    // The Body object also has 'transformToByteArray' and 'transformToWebStream' methods.
    const str = await response.Body.transformToString();
    fs.writeFileSync("./src/assets/project_map.json", str, "utf8")
  } catch (err) {
    throw new S3BucketError("File not found in S3")
  }
};

// save ProjectMap to S3
export const saveProjectMapFile = async (file: string) => {
    log("Saving Project Map File")
    // const projectMap = fs.readFileSync("./src/assets/project_map.json", "utf8")

    const command = new PutObjectCommand({
        Bucket: process.env.AWS_BUCKET,
        Key: "project_map.json",
        Body: file
    });
    try{
        await client.send(command);
        if(!fs.existsSync("./src/assets/project_map.json")){
            fs.writeFileSync("./src/assets/project_map.json", file, "utf8")
        }
    }catch(err){
        error(err.message)
    }
}


// saveProjectMapFile(JSON.stringify({}))
// fs.writeFileSync("./src/assets/project_map.json", JSON.stringify({}), "utf8")