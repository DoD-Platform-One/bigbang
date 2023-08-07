import {createContext } from '../../src/events/eventManager'
import {payload as issueCommentPayload} from '../fixtures/issueComment'
import {payload as pullRequestPayload} from '../fixtures/pullRequest'
import {gitlabNoteMergeRequest} from '../fixtures/gitlab-note.MergeRequest'
import { mockApi } from '../mocks/mocks'
import { UpdateConfigMapping } from '../../src/assets/projectMap'
import {clearMapping} from '../teardown'
import { Response } from 'express'
import { IEventContextObject, emitter } from '../../src/events/eventManagerTypes'
import NotImplementedError from '../../src/errors/NotImplementedError'
import ContextCreationError from '../../src/errors/ContextCreationError'

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

  it("test create context with no headers", async () => {
    const headers = {}
    const context = await createContext(headers, {type: "issue_comment.created",...issueCommentPayload}, {} as Response, () => null)
    expect(context.error).toBeInstanceOf(NotImplementedError)
  })

  it('test create context with no mapping', async () => {
    const headers = {
        "x-github-event": "issue_comment",
        "x-github-hook-installation-target-id": "1234"
    }
    const context = await createContext(headers, {type: "issue_comment.created",...issueCommentPayload}, {} as Response, () => null)
    expect(context.error).toBeInstanceOf(ContextCreationError)
  })

  it('test create context with uppercase headers', async () => {
    const headers = {
        "X-GitHub-Event": "issue_comment",
        "X-Github-Hook-Installation-Target-Id": "1234"
    }

    // configure the mapping file
    setupConfig()

    const context = await createContext(headers, {type: "issue_comment.created",...issueCommentPayload}, {} as Response, () => null)
    expect(context.error).toBeUndefined()
    expect(context?.eventName).toBeTruthy()
  })

  it('test create context with lowercase headers', async () => {
    const headers = {
        "x-github-event": "issue_comment",
        "x-github-hook-installation-target-id": "1234"
    }

    // configure the mapping file
    setupConfig()

    const context = await createContext(headers, {type: "issue_comment.created",...issueCommentPayload}, {} as Response, () => null)
    expect(context.error).toBeUndefined()
    expect(context?.eventName).toBe("issue_comment.created")
  })

  it('test mapping file is populated', async () => {
    const headers = {
        "x-github-event": "issue_comment",
        "x-github-hook-installation-target-id": "1234"
    }

    // configure the mapping file
    setupConfig()

    // deep copy of payload
    const payloadCopy = JSON.parse(JSON.stringify(issueCommentPayload))

    const context = await createContext(headers, payloadCopy, {} as Response, () => null)
    expect(context.error).toBeUndefined()
    expect(context?.eventName).toBe("issue_comment.created")
    expect(context?.mapping.github.projectId).toBe(pullRequestPayload.repository.id)
  })

  it('test context has correct properties', async () => {
    const headers = {
        "x-github-event": "issue_comment",
        "x-github-hook-installation-target-id": "1234"
    }

    // configure the mapping file
    setupConfig()

    // deep copy of payload
    const payloadCopy = JSON.parse(JSON.stringify(issueCommentPayload))

    const context = await createContext(headers, payloadCopy, {} as Response, () => null)
    expect(context.error).toBeUndefined()
    expect(context?.eventName).toBe("issue_comment.created")
    expect(context.event).toBe("issue_comment")
    expect(context.canInit).toBe(false)
    expect(context.action).toBe("created")
    expect(context.gitHubAccessToken).toBe("testToken")
    expect(context.isBot).toBe(false)
    expect(context?.mapping.github.projectId).toBe(issueCommentPayload.repository.id)
    expect(context?.installationId).toBe(1)
    expect(context?.appId).toBe(1234)
    expect(context?.projectName).toBe(issueCommentPayload.repository.name)
    expect(context?.requestNumber).toBe(issueCommentPayload.issue.number)
    expect(context.userName).toBe(issueCommentPayload.sender.login)
    expect(context.payload).toStrictEqual(issueCommentPayload)
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
        "x-gitlab-event": "Note Hook",
    }
    setupConfig()
    const context = await createContext(headers, {type: "note.created",...gitlabNoteMergeRequest}, {} as Response, () => null)
    expect(context.error).toBeUndefined()
    expect(context?.eventName).toBe("note.created")
    expect(context?.mapping.gitlab.projectId).toBe(1234)

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