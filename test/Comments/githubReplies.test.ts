import githubCommentParser from '../../src/events/utils/githubReply'

describe('Test github replies',  () => {
    // > > #### snekcode [commented](https://repo1.dso.mil/snekcode/podinfo/-/merge_requests/23#note_1373973):\r\n> > this is a reply\r\n> \r\n> ok thanks for the reply\r\n\r\nyou're welcome!
    it('Regex test to grab the note id from the url if it exists', async () => {
        const comment = "> > #### snekcode [commented](https://repo1.dso.mil/snekcode/podinfo/-/merge_requests/23#note_1373973):\r\n> > this is a reply\r\n> \r\n> ok thanks for the reply\r\n\r\nyou're welcome!"
        const [isReply, noteId] = githubCommentParser(comment)
        expect(isReply).toBe(true)
        expect(noteId).toBe("1373973")
    })

    it('returns only false if the comment is not a reply', async () => {
        const comment = "this is a comment with note_1373973 in it but not a reply since there are no > s in the front"
        const [isReply, noteId] = githubCommentParser(comment)
        expect(isReply).toBe(false)
        expect(noteId).toBe(undefined)
    })
    it('returns only false if the note id is not inside the markdown html syntax', () =>{
        const comment = "> #### 23#note_1373973"
        const [isReply, noteId] = githubCommentParser(comment)
        expect(isReply).toBe(false)
        expect(noteId).toBe(undefined)
    })

    // > [Gitlab Comment Mirrored Here](https://repo1.dso.mil/snekcode/podinfo/-/merge_requests/24#note_1374704)\r\n> \r\n> test\r\n\r\ntest reply to gitlab discussion?
    it('strips out the > from the comment', () => {
        const comment = "> [Gitlab Comment Mirrored Here](https://repo1.dso.mil/snekcode/podinfo/-/merge_requests/24#note_1374704)\r\n> \r\n> test\r\n\r\ntest reply to gitlab discussion?"
        const [isReply, noteId, strippedComment] = githubCommentParser(comment)
        expect(isReply).toBe(true)
        expect(noteId).toBe("1374704")
        expect(strippedComment).toBe("test reply to gitlab discussion?")
    })

    it('strips out the > from the comment but not any > after the base of the comment', () => {
        const comment = "> [Gitlab Comment Mirrored Here](https://repo1.dso.mil/snekcode/podinfo/-/merge_requests/24#note_1374704)\r\n> \r\n> test\r\n\r\ntest reply to gitlab discussion?\r\n> This is a quote that needs to stay!"
        const [isReply, noteId, strippedComment] = githubCommentParser(comment)
        expect(isReply).toBe(true)
        expect(noteId).toBe("1374704")
        expect(strippedComment).toBe("test reply to gitlab discussion?\r\n> This is a quote that needs to stay!")
    })
})