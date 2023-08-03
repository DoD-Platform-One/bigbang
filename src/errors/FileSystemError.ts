import ResponseError from "./ResponseError.js";


class GitError extends ResponseError {
    constructor(message: string) {
        super(message);
        this.status = 409
        this.name = "GitError"
    }
}

export default GitError