import ResponseError from "./ResponseError.js";


class RequestError extends ResponseError {
    constructor(message: string, status: number) {
        super(message);
        this.status = status;
        this.name = "RequestError"
    }
}

export default RequestError