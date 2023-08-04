import { warn } from "../utils/console.js";

class RepoSyncError extends Error {
    status: number
    consoleFunction = warn
    constructor(message: string) {
        super(message);
        this.status = 500
    }

    public effectFunction () {
        return
    }
}

export default RepoSyncError