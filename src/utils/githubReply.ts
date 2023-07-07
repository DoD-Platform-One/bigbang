const githubReplyParser = (comment: string): [boolean, string, string] => {

    // ^>.* - starts with a > and then any character this is the syntax for github replies
    // \[.*\] - matches markdown syntax for a link [text]
    // \(.*note_(\d+)\) - noteID is in the () link part of markdown syntax 
    // the (\d+) is a capture group that will be returned by the match function
    const noteIdQuery = /^>.*\[.*\]\(.*note_(\d+)\)/
    const noteIdMatch = comment.match(noteIdQuery)

    if (!noteIdMatch) {
        return [false, undefined, undefined]
    }

    const noteId = noteIdMatch[1]

    // remove all lines in the comment that start with a > 
    // until there are no more lines that start with a > 
    // then allow the rest of the comment to be posted including any more > lines after
    // e.g > [Gitlab Comment Mirrored Here](https://repo1.dso.mil/snekcode/podinfo/-/merge_requests/24#note_1374704)\r\n> \r\n> test\r\n\r\ntest reply to gitlab discussion?
    // becomes test reply to gitlab discussion?

    let strippedComment = comment
    while (strippedComment.startsWith(">")) {
        strippedComment = strippedComment.replace(/(?:>.*)\w*\r?\n/,"").trimLeft()
    }

    return [true, noteId, strippedComment]
}


export default githubReplyParser