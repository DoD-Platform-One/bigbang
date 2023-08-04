import RepoSyncError from "./RepoSyncError.js";
import { debug } from "../utils/console.js";


class NotImplementedError extends RepoSyncError {
    consoleFunction = debug
    constructor(message: string) {
        super(message);
        this.status = 501
        this.name = "NotImplemented"
    }
}

export default NotImplementedError