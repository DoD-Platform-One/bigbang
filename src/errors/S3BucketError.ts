class S3BucketError extends Error {
    constructor(message: string) {
        super(message);
        this.name = "S3BucketError";
    }
}

export default S3BucketError