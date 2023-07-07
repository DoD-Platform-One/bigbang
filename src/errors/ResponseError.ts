
class ResponseError extends Error {
    status: number
    constructor(message: string) {
        super(message);
        this.status = 500
    }
}

export default ResponseError