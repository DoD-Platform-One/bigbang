import ResponseError from "./ResponseError.js";


class MappingError extends ResponseError {
    constructor(message: string) {
        super(message);
        this.status = 404
        this.name = "MappingError"
    }
}

export default MappingError