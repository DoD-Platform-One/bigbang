export interface NoteMergeRequest {
    object_kind: string;
    event_type: string;
    user: User;
    project_id: number;
    project: Project;
    object_attributes: NoteObjectAttributes;
    repository: Repository;
    merge_request: Mergerequest;
  }
  
  interface Mergerequest {
    assignee_id?: string | null;
    author_id: number;
    created_at: string;
    description?: string | null;
    head_pipeline_id: number;
    id: number;
    iid: number;
    last_edited_at?: string | null;
    last_edited_by_id?: string | null;
    merge_commit_sha?: string | null;
    merge_error?: string | null;
    merge_params: Mergeparams;
    merge_status: string;
    merge_user_id?: string | null;
    merge_when_pipeline_succeeds: boolean;
    milestone_id?: string | null;
    source_branch: string;
    source_project_id: number;
    state_id: number;
    target_branch: string;
    target_project_id: number;
    time_estimate: number;
    title: string;
    updated_at: string;
    updated_by_id?: string | null;
    url: string;
    source: Project;
    target: Project;
    last_commit: Lastcommit;
    work_in_progress: boolean;
    total_time_spent: number;
    time_change: number;
    human_total_time_spent?: string | null;
    human_time_change?: string | null;
    human_time_estimate?: string | null;
    assignee_ids: string[];
    reviewer_ids: string[];
    labels: string[];
    state: string;
    blocking_discussions_resolved: boolean;
    first_contribution: boolean;
    detailed_merge_status: string;
  }
  
  interface Lastcommit {
    id: string;
    message: string;
    title: string;
    timestamp: string;
    url: string;
    author: Author;
  }
  
  interface Mergeparams {
    force_remove_source_branch: boolean;
  }
  
  interface NoteObjectAttributes {
    attachment?: string | null;
    author_id: number;
    change_position?: string | null;
    commit_id?: string | null;
    created_at: string;
    discussion_id: string;
    id: number;
    line_code?: string | null;
    note: string;
    noteable_id: number;
    noteable_type: string;
    original_position?: string | null;
    position?: string | null;
    project_id: number;
    resolved_at?: string | null;
    resolved_by_id?: string | null;
    resolved_by_push?: string | null;
    st_diff?: string | null;
    system: boolean;
    type?: string | null;
    updated_at: string;
    updated_by_id?: string | null;
    description: string;
    url: string;
  }
  
  interface Project {
    id: number;
    name: string;
    description: string;
    web_url: string;
    avatar_url: string;
    git_ssh_url: string;
    git_http_url: string;
    namespace: string;
    visibility_level: number;
    path_with_namespace: string;
    default_branch: string;
    ci_config_path: string;
    homepage: string;
    url: string;
    ssh_url: string;
    http_url: string;
  }
  
  interface User {
    id: number;
    name: string;
    username: string;
    avatar_url: string;
    email: string;
  }



  export interface MergeRequest {
    object_kind: string;
    event_type: string;
    user: User;
    project: Project;
    object_attributes: MergeRequestObjectAttributes;
    labels: string[];
    changes: Changes;
    repository: Repository;
  }
  
  interface Repository {
    name: string;
    url: string;
    description: string;
    homepage: string;
  }
  
  interface Changes {
    state_id: Stateid;
    updated_at: Updatedat;
  }
  
  interface Updatedat {
    previous: string;
    current: string;
  }
  
  interface Stateid {
    previous: number;
    current: number;
  }
  
  interface MergeRequestObjectAttributes {
    assignee_id?: string | null;
    author_id: number;
    created_at: string;
    description?: string | null;
    head_pipeline_id: number;
    id: number;
    iid: number;
    last_edited_at?: string | null;
    last_edited_by_id?: string | null;
    merge_commit_sha?: string | null;
    merge_error?: string | null;
    merge_params: Mergeparams;
    merge_status: string;
    merge_user_id?: string | null;
    merge_when_pipeline_succeeds: boolean;
    milestone_id?: string | null;
    source_branch: string;
    source_project_id: number;
    state_id: number;
    target_branch: string;
    target_project_id: number;
    time_estimate: number;
    title: string;
    updated_at: string;
    updated_by_id?: string | null;
    url: string;
    source: Project;
    target: Project;
    last_commit: Lastcommit;
    work_in_progress: boolean;
    total_time_spent: number;
    time_change: number;
    human_total_time_spent?: string | null;
    human_time_change?: string | null;
    human_time_estimate?: string | null;
    assignee_ids: string[];
    reviewer_ids: string[];
    labels: string[];
    state: string;
    blocking_discussions_resolved: boolean;
    first_contribution: boolean;
    detailed_merge_status: string;
    action: string;
  }
  
  interface Author {
    name: string;
    email: string;
  }


interface PushOptions {
    NOTIMPLEMENTED: "NOTIMPLEMENTED";
}

export interface Push {
    action: string,
    object_kind: string,
    event_name: string,
    before: string,
    after: string,
    ref: string,
    checkout_sha: string,
    message: string,
    user_id: number,
    user_name: string,
    user_username: string,
    user_email: string,
    user_avatar: string,
    project_id: number,
    project: Project,
    commits: string[],
    total_commits_count: number,
    push_options: PushOptions,
    repository: Repository,
  }