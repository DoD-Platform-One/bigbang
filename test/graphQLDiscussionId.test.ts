import { getDiscussionId } from '../src/queries/discussion.js';
import {server, graphql} from './mocks/msw.js';

describe('graph ql tests', () => {
    
    beforeAll(() => server.listen())

    it('gets a discussion id from a note id', async () => {

        const idValue = "testdiscussionid"
        // setting up the mock graphql server and the response
        server.use(graphql.operation((req, res, ctx) => {
            return res(
                ctx.data({
                    note: {
                        discussion: {
                            id: `gid://gitlab/Discussion/${idValue}`
                        }
                    }
                })
            )
        }))
        const discussionId = await getDiscussionId("1374700")
        expect(discussionId).toEqual(idValue)
    })

    afterAll(() => {
        // Clean up once the tests are done.
        server.close()
      })
})