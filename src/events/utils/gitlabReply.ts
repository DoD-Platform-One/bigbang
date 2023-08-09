const gitlabReplyParser = (comment: string): [boolean, string] => {
    // https://github.com/SnekCode/podinfo/pull/26#issuecomment-1615065156
    const issueCommentQuery = /https:\/\/.*issuecomment-(\d+)/
    const issueCommentMatch = comment.match(issueCommentQuery)

    if (!issueCommentMatch) {
        return [false, undefined]
    }

    const issueCommentId = issueCommentMatch[1]

    return [true, issueCommentId]
}

export default gitlabReplyParser
