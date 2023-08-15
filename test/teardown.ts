import fs from 'fs'
import path from 'path'
import {mappingFileName,mappingFilePath} from '../src/assets/projectMap'

const mappingFilePathFull = path.join(__dirname, mappingFilePath + mappingFileName)
export default async function() {
    fs.unlinkSync(mappingFilePathFull)
  }

export const clearMapping = async function() {
  fs.writeFileSync(mappingFilePathFull, '{}')
  }