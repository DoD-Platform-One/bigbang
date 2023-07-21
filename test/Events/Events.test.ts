import {createContext } from '../../src/events/eventManager'
import {payload as issueCommentPayload} from '../fixtures/issueComment'
import {payload as pullRequestPayload} from '../fixtures/pullRequest'
import {gitlabNoteMergeRequest} from '../fixtures/gitlab-note.MergeRequest'
import { mockApi } from '../mocks/mocks'
import { UpdateConfigMapping } from '../../src/assets/projectMap'
import {clearMapping} from '../teardown'
import { Response } from 'express'
import { IEventContextObject, emitter } from '../../src/events/eventManagerTypes'

const setupConfig = () => UpdateConfigMapping({
  projectName: pullRequestPayload.repository.name,
  gitHubDefaultBranch: pullRequestPayload.repository.default_branch,
  gitHubIssueNumber: pullRequestPayload.number,
  gitHubProjectId: pullRequestPayload.repository.id,
  gitHubApiUrl: pullRequestPayload.repository.url,
  gitHubCloneUrl: pullRequestPayload.repository.clone_url,
  gitHubSourceBranch: pullRequestPayload.pull_request.head.ref,
  gitLabSourceBranch: pullRequestPayload.pull_request.head.ref,
  // gitlab v
  gitLabMergeRequestNumber: 12,
  gitLabProjectId: 1234,
  gitLabProjectUrl: "https://gitlab.com/owner/repo",
  gitLabDefaultBranch: "master",
  appID: 1234,
  installationID: 1,
})

describe('Create GitHub Context',  () => {
  // before each test, mock the api call to /app/installations/1/access_tokens
  // const uri = /\/app\/installations\/\d+\/access_tokens/

  beforeEach(() => {
    mockApi("github","post", "/app/installations/1/access_tokens", {token: "testToken"})
  })

  it('test create context with uppercase headers', async () => {
    const headers = {
        "X-GitHub-Event": "issue_comment",
        "X-GitHub-Hook-Installation-Target-Id": "1234"
    }

    const context = await createContext(headers, {type: "issue_comment.created",...issueCommentPayload}, {} as Response, () => null)
    expect(context?.event).toBeTruthy()
  })

  it('test create context with lowercase headers', async () => {
    const headers = {
        "x-gitHub-event": "issue_comment",
        "x-github-hook-installation-target-id": "1234"
    }

    const context = await createContext(headers, {type: "issue_comment.created",...issueCommentPayload}, {} as Response, () => null)
    expect(context?.event).toBe("issue_comment.created")
  })

  it('test mapping file is populated', async () => {
    const headers = {
        "x-gitHub-event": "issue_comment",
        "x-github-hook-installation-target-id": "1234"
    }

    // configure the mapping file
    setupConfig()

    // deep copy of payload
    const payloadCopy = JSON.parse(JSON.stringify(issueCommentPayload))

    const context = await createContext(headers, payloadCopy, {} as Response, () => null)
    expect(context?.event).toBe("issue_comment.created")
    expect(context?.mapping.github.projectID).toBe(pullRequestPayload.repository.id)
  })
})

describe ('Create GitLab Context', () => {

  beforeEach(() => {
    // ensure config mapping is empty
    clearMapping()
    mockApi("github","post", "/app/installations/1/access_tokens", {token: "testToken"})
  })

  it('test create context with uppercase headers', async () => {
    const headers = {
        "X-Gitlab-Event": "note",
    }
    setupConfig()
    const context = await createContext(headers, {type: "note.created",...gitlabNoteMergeRequest}, {} as Response, () => null)
    expect(context?.event).toBe("note.created")
    expect(context?.mapping.gitlab.projectID).toBe(1234)

  })

  it('test undefined context with no mapping object for project name', async () => {
    const headers = {
        "x-gitlab-event": "note",
    }
    const context = await createContext(headers, {type: "note.created",...gitlabNoteMergeRequest}, {} as Response, () => null)
    expect(context.isFailed).toBe(true)
  })
})

describe('Event Emmiter Tests', () => {

  it('Test Event Emitter', () => {
    const arrayCheck: string[] = []
    const callback = () => {
        arrayCheck.push("testResult")
    }
    emitter.on("push", callback)
    emitter.emit("push", {} as IEventContextObject)
    expect(arrayCheck).toStrictEqual(["testResult"])
  })
})