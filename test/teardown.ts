import fs from 'fs'
import path from 'path'

export default async function() {
    const mappingFilePath = path.join(__dirname, './fixtures/project_map_test.json')
    fs.unlinkSync(mappingFilePath)
  }

export const clearMapping = async function() {
  const mappingFilePath = path.join(__dirname, './fixtures/project_map_test.json')
  fs.writeFileSync(mappingFilePath, '{}')
  }