import RepoSyncError from "./RepoSyncError.js";


class MappingError extends RepoSyncError {
    constructor(message: string) {
        super(message);
        this.status = 404
        this.name = "MappingError"
    }
}

export default MappingError