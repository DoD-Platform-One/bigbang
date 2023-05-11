import {AppRequest} from '../app'
import {Router} from 'express'
import fs from 'fs'
import path from 'path' 
const adminRouter = Router()

adminRouter.get('/admin/logs/:name', (req: AppRequest, res) => {

    // should never get to this point but double check
    if(!req.admin){
        return res.status(401).send({message: "You are not admin"})
    }
    const filepath = path.join('src', 'logs', `${req.params.name}.log`)
    if(!fs.existsSync(filepath)){
        res.status(400).send(`No log file named ${req.params.name} exists`)
    }

    const logfile = fs.readFileSync(filepath)
    return res.status(200).send(logfile.toString())
    })

export default adminRouter
