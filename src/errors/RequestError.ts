import RepoSyncError from "./RepoSyncError.js";


class RequestError extends RepoSyncError {
    constructor(message: string, status: number) {
        super(message);
        this.status = status;
        this.name = "RequestError"
    }
}

export default RequestError