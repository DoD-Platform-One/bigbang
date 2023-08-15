import fs from 'fs'
import path from 'path'

// have to hard code these values here
// experiencing an issue similar to this github issue: 
// https://github.com/jestjs/jest/issues/11644
const mappingFileName = 'project_map_test.json'
const mappingFilePath = '../src/assets/'

const mappingFilePathFull = path.join(__dirname, mappingFilePath + mappingFileName)
export default async function() {
    fs.unlinkSync(mappingFilePathFull)
}

export const clearMapping = async function() {
  fs.writeFileSync(mappingFilePathFull, '{}')
}