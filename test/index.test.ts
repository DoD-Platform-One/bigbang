import { Application } from 'probot'
// Requiring our app implementation
import myProbotApp from '../src'

const issuesOpenedPayload = require('./fixtures/issues.opened.json')

test('that we can run tests', () => {
  // your real tests go here
  expect(1 + 2 + 3).toBe(6)
})

describe('My Probot app', () => {
  let app: Application
  let github: any

  beforeEach(() => {
    app = new Application()
    // Initialize the app based on the code from index.ts
    app.load(myProbotApp)
    // This is an easy way to mock out the GitHub API
    github = {
      issues: {
        createComment: jest.fn().mockReturnValue(Promise.resolve({}))
      }
    }
    // Passes the mocked out GitHub API into out app instance
    app.auth = () => Promise.resolve(github)
  })

  test('creates a comment when an issue is opened', async () => {
    // Simulates delivery of an issues.opened webhook
    await app.receive({
      name: 'issues.opened',
      payload: issuesOpenedPayload
    })

    // This test passes if the code in your index.ts file calls `context.github.issues.createComment`
    expect(github.issues.createComment).toHaveBeenCalled()
  })
})

// For more information about testing with Jest see:
// https://facebook.github.io/jest/
