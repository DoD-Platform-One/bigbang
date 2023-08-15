import {S3Client, GetObjectCommand, PutObjectCommand, GetBucketVersioningCommand} from '@aws-sdk/client-s3'
import fs from 'fs'
import dotenv from 'dotenv'
import { error, info, success } from '../../utils/console.js'
import S3BucketError from '../../errors/S3BucketError.js';
dotenv.config();

const client = new S3Client({})


export const checkAWSConnection = async () => {
    info("Checking AWS Connection");
    const command = new GetBucketVersioningCommand({
        Bucket: process.env.AWS_BUCKET,
    })
    try{
        await client.send(command)
        success("AWS Connection Successful")
        return true
    }catch(err){
        error(err.message)
        return false
    }
}

export const getProjectMapFile = async (filePathBase: string,fileName: string) => {
  info("Getting Project Map File")
  const command = new GetObjectCommand({
    Bucket: process.env.AWS_BUCKET,
    Key: fileName
  });

  try {
    const response = await client.send(command);
    // The Body object also has 'transformToByteArray' and 'transformToWebStream' methods.
    const str = await response.Body.transformToString();
    fs.writeFileSync(`${filePathBase}${fileName}`, str, "utf8")
  } catch (err) {
    if(err.$metadata.httpStatusCode === 404){
        return saveProjectMapFile(JSON.stringify({}), filePathBase, fileName)
    }else{
        throw new S3BucketError(err.message)
    }
  }
  return true
};

// save ProjectMap to S3
export const saveProjectMapFile = async (file: string, filePathBase: string, fileName: string) => {
    info("Saving Project Map File")
    // const projectMap = fs.readFileSync("./src/assets/project_map.json", "utf8")

    const command = new PutObjectCommand({
        Bucket: process.env.AWS_BUCKET,
        Key: fileName,
        Body: file
    });
    try{
        await client.send(command);
        if(!fs.existsSync(`${filePathBase}${fileName}`)){
            fs.writeFileSync(`${filePathBase}${fileName}`, file, "utf8")
        }
        success("Project Map File Saved")
    }catch(err){
        error(err.message)
        return false
    }
    return true
}


// saveProjectMapFile(JSON.stringify({}))
// fs.writeFileSync("./src/assets/project_map.json", JSON.stringify({}), "utf8")