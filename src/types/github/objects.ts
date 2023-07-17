export interface PullRequestPayload {
    action: string;
    number: number;
    pull_request: Pullrequest;
    repository: Repository;
    sender: User;
    installation: Installation;
  }

type IssueActions = "created" | "edited" | "deleted";


 export interface IssueCommentPayload {
    action: IssueActions;
    issue: Issue;
    comment: Comment;
    repository: Repository;
    sender: User;
    installation: Installation;
  }

interface Issue {
    url: string;
    repository_url: string;
    labels_url: string;
    comments_url: string;
    events_url: string;
    html_url: string;
    id: number;
    node_id: string;
    number: number;
    title: string;
    user: User;
    labels: string[];
    state: string;
    locked: boolean;
    assignee?: string | null;
    assignees: string[];
    milestone?: string | null;
    comments: number;
    created_at: string;
    updated_at: string;
    closed_at?: string | null;
    author_association: string;
    active_lock_reason?: string | null;
    draft: boolean;
    pull_request: {
        url: string;
        html_url: string;
        diff_url: string;
        patch_url: string;
        merged_at?: string | null;
      };
    body?: string | null;
    reactions: Reactions;
    timeline_url: string;
    performed_via_github_app?: string | null;
    state_reason?: string | null;
  }
  
  interface Reactions {
    url: string;
    total_count: number;
    '+1': number;
    '-1': number;
    laugh: number;
    hooray: number;
    confused: number;
    heart: number;
    rocket: number;
    eyes: number;
  }

  interface Comment {
    url: string;
    html_url: string;
    issue_url: string;
    id: number;
    node_id: string;
    user: User;
    created_at: string;
    updated_at: string;
    author_association: string;
    body: string;
    reactions: Reactions;
    performed_via_github_app?: string | null;
  }
  
  interface Installation {
    id: number;
    node_id: string;
  }
  
  interface Repository {
    id: number;
    node_id: string;
    name: string;
    full_name: string;
    private: boolean;
    owner: User;
    html_url: string;
    description?: string | null;
    fork: boolean;
    url: string;
    forks_url: string;
    keys_url: string;
    collaborators_url: string;
    teams_url: string;
    hooks_url: string;
    issue_events_url: string;
    events_url: string;
    assignees_url: string;
    branches_url: string;
    tags_url: string;
    blobs_url: string;
    git_tags_url: string;
    git_refs_url: string;
    trees_url: string;
    statuses_url: string;
    languages_url: string;
    stargazers_url: string;
    contributors_url: string;
    subscribers_url: string;
    subscription_url: string;
    commits_url: string;
    git_commits_url: string;
    comments_url: string;
    issue_comment_url: string;
    contents_url: string;
    compare_url: string;
    merges_url: string;
    archive_url: string;
    downloads_url: string;
    issues_url: string;
    pulls_url: string;
    milestones_url: string;
    notifications_url: string;
    labels_url: string;
    releases_url: string;
    deployments_url: string;
    created_at: string;
    updated_at: string;
    pushed_at: string;
    git_url: string;
    ssh_url: string;
    clone_url: string;
    svn_url: string;
    homepage?: string | null;
    size: number;
    stargazers_count: number;
    watchers_count: number;
    language?: string | null;
    has_issues: boolean;
    has_projects: boolean;
    has_downloads: boolean;
    has_wiki: boolean;
    has_pages: boolean;
    has_discussions: boolean;
    forks_count: number;
    mirror_url?: string | null;
    archived: boolean;
    disabled: boolean;
    open_issues_count: number;
    license: License;
    allow_forking: boolean;
    is_template: boolean;
    web_commit_signoff_required: boolean;
    topics: string[];
    visibility: string;
    forks: number;
    open_issues: number;
    watchers: number;
    default_branch: string;

    allow_squash_merge?: boolean | null;
    allow_merge_commit?: boolean | null;
    allow_rebase_merge?: boolean | null;
    allow_auto_merge?: boolean | null;
    delete_branch_on_merge?: boolean | null;
    allow_update_branch?: boolean | null;
    use_squash_pr_title_as_default?: boolean | null;
    squash_merge_commit_message?: string | null;
    squash_merge_commit_title?: string | null;

    merge_commit_message?: string | null;
    merge_commit_title?: string | null;
  }
  
  interface Pullrequest {
    url: string;
    id: number;
    node_id: string;
    html_url: string;
    diff_url: string;
    patch_url: string;
    issue_url: string;
    number: number;
    state: string;
    locked: boolean;
    title: string;
    user: User;
    body?: string | null;
    created_at: string;
    updated_at: string;
    closed_at?: string | null;
    merged_at?: string | null;
    merge_commit_sha?: string | null;
    assignee?: string | null;
    assignees: string[];
    requested_reviewers: string[];
    requested_teams: string[];
    labels: string[];
    milestone?: string | null;
    draft: boolean;
    commits_url: string;
    review_comments_url: string;
    review_comment_url: string;
    comments_url: string;
    statuses_url: string;
    head: Head;
    base: Head;
    _links: Links;
    author_association: string;
    auto_merge?: string | null;
    active_lock_reason?: string | null;
    merged: boolean;
    mergeable?: string | null;
    rebaseable?: string | null;
    mergeable_state: string;
    merged_by?: string | null;
    comments: number;
    review_comments: number;
    maintainer_can_modify: boolean;
    commits: number;
    additions: number;
    deletions: number;
    changed_files: number;
  }
  
  interface Links {
    self: Self;
    html: Self;
    issue: Self;
    comments: Self;
    review_comments: Self;
    review_comment: Self;
    commits: Self;
    statuses: Self;
  }
  
  interface Self {
    href: string;
  }
  
  interface Head {
    label: string;
    ref: string;
    sha: string;
    user: User;
    repo: Repository;
  }
  
  interface License {
    key: string;
    name: string;
    spdx_id: string;
    url: string;
    node_id: string;
  }
  
  interface User {
    login: string;
    id: number;
    node_id: string;
    avatar_url: string;
    gravatar_id: string;
    url: string;
    html_url: string;
    followers_url: string;
    following_url: string;
    gists_url: string;
    starred_url: string;
    subscriptions_url: string;
    organizations_url: string;
    repos_url: string;
    events_url: string;
    received_events_url: string;
    type: string;
    site_admin: boolean;
  }

  //create interface for the response of the github api for push payload
  export interface PullRequestSyncPayload {
    action: string;
    number: number;
    ref: string;
    before: string;
    after: string;
    created: boolean;
    pull_request: Pullrequest
    deleted: boolean;
    forced: boolean;
    base_ref?: string | null;
    installation?: Installation | null;
    compare: string;
    commits: Commit[];
    head_commit: Commit;
    repository: Repository;
    sender: Sender;
  }

  interface Commit {
    id: string;
    tree_id: string;
    distinct: boolean;
    message: string;
    timestamp: Date;
    url: string;
  }

  interface Sender {
    login: string;
    id: number;
    node_id: string;
    avatar_url: string;
    gravatar_id: string;
    url: string;
    html_url: string;
    followers_url: string;
    following_url: string;
    gists_url: string;
    starred_url: string;
    subscriptions_url: string;
    organizations_url: string;
    repos_url: string;
    events_url: string;
    received_events_url: string;
    type: string;
    site_admin: boolean;
  }

