import serverless from 'serverless-http'  
import app from './app'

export const handler = serverless(app)