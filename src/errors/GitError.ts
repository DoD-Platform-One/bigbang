import RepoSyncError from "./RepoSyncError.js";


class GitError extends RepoSyncError {
    constructor(message: string) {
        super(message);
        this.status = 409
        this.name = "GitError"
    }
}

export default GitError