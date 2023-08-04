import RepoSyncError from "./RepoSyncError.js";
import { info } from "../utils/console.js";

class MappingError extends RepoSyncError {
    consoleFunction = info
    constructor(message: string) {
        super(message);
        this.status = 404
        this.name = "MappingError"
    }
}

export default MappingError