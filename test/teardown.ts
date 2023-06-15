import fs from 'fs'
import path from 'path'

export default async function() {
    // override ./test/fixtures/project_map_test.json to be {}
    const mappingFilePath = path.join(__dirname, './fixtures/project_map_test.json')
    fs.writeFileSync(mappingFilePath, '{}')
  }