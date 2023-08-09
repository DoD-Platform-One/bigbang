/* eslint-disable @typescript-eslint/no-unused-vars */
// better console.logs / warns and errors

export const Reset = "\x1b[0m"
export const Bright = "\x1b[1m"
export const Dim = "\x1b[2m"
export const Underscore = "\x1b[4m"
export const Blink = "\x1b[5m"
export const Reverse = "\x1b[7m"
export const Hidden = "\x1b[8m"
export const FgBlack = "\x1b[30m"
export const FgRed = "\x1b[31m"
export const FgGreen = "\x1b[32m"
export const FgYellow = "\x1b[33m"
export const FgBlue = "\x1b[34m"
export const FgCyan = "\x1b[36m"
export const FgWhite = "\x1b[37m"
export const FgGray = "\x1b[90m"
export const BgBlack = "\x1b[40m"
export const BgRed = "\x1b[41m"
export const BgGreen = "\x1b[42m"
export const BgYellow = "\x1b[43m"
export const BgBlue = "\x1b[44m"
export const BgMagenta = "\x1b[45m"
export const BgCyan = "\x1b[46m"
export const BgWhite = "\x1b[47m"
export const BgGray = "\x1b[100m"


export const log = (message: string) => {
    console.log(message)
}

export const warn = (message: string) => {
    if(process.env.NODE_ENV === "development"){
        console.warn(`${FgYellow}${message}${Reset}`)
    }else{
        console.warn(`Warning: ${message}`)
    }
}

export const error = (message: string) => {
    if(process.env.NODE_ENV === "development"){
        console.error(`${FgRed}${message}${Reset}`)
    }else{
        console.error(`Error: ${message}`)
    }
}

export const info = (message: string) => {
    if(process.env.NODE_ENV === "development"){
        console.info(`${FgBlue}${message}${Reset}`)
    }else{
        console.info(`Info: ${message}`)
    }
}

export const debug = (message: string) => {
    if(process.env.NODE_ENV === "development"){
        console.debug(`${FgGray}${message}${Reset}`)
    }else{
        console.debug(`Debug: ${message}`)
    }
}

export const trace = (message: string) => {
    if(process.env.NODE_ENV === "development"){
        console.trace(`${FgGray}${message}${Reset}`)
    }else{
        console.trace(`Trace: ${message}`)
    }
}

export const success = (message: string) => {
    if(process.env.NODE_ENV === "development"){
        console.log(`${FgGreen}${message}${Reset}`)
    }else{
        console.log(`Success: ${message}`)
    }
}

export const fail = (message: string) => {
    if(process.env.NODE_ENV === "development"){
        console.error(`${FgRed}${message}${Reset}`)
    }else{
        console.error(`Fail: ${message}`)
    }
}