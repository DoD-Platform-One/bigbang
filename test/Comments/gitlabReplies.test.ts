import gitlabReplyParser from '../../src/utils/gitlabReply'

describe('Test github replies',  () => {
    // > > #### snekcode [commented](https://repo1.dso.mil/snekcode/podinfo/-/merge_requests/23#note_1373973):\r\n> > this is a reply\r\n> \r\n> ok thanks for the reply\r\n\r\nyou're welcome!
    it('Regex test to grab the issuecomment id from the url if it exists', async () => {
        const comment = "> > #### snekcode [commented](https://github.com/SnekCode/podinfo/pull/29#issuecomment-1615280053):\r\n> > this is a reply\r\n> \r\n> ok thanks for the reply\r\n\r\nyou're welcome!"
        const [isReply, noteId] = gitlabReplyParser(comment)
        expect(isReply).toBe(true)
        expect(noteId).toBe("1615280053")
    })

    it('returns only false if the comment is not a reply', async () => {
        const comment = "this is a comment with issuecomment-1615280053 in it but its not a URL"
        const [isReply, noteId] = gitlabReplyParser(comment)
        expect(isReply).toBe(false)
        expect(noteId).toBe(undefined)
    })

})