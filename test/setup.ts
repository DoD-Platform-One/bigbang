import fs from 'fs'
import path from 'path'

import { execSync } from 'child_process'


// @ts-ignore this is fine
import { mappingFilePath, mappingFileName } from 'src/assets/projectMap.js'
export default async function() {
  execSync("echo printenv")
  // override ./test/fixtures/project_map_test.json to be {}
  const mappingFilePathFull = path.join(__dirname, mappingFilePath + mappingFileName)
  fs.writeFileSync(mappingFilePathFull, '{}')
}