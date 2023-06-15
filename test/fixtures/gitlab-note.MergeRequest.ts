import { NoteMergeRequest } from "../../src/types/gitlab/objects";

export const gitlabNoteMergeRequest: NoteMergeRequest = {
  "object_kind": "note",
  "event_type": "note",
  "user": {
    "id": 2325,
    "name": "Patrick Kelly",
    "username": "snekcode",
    "avatar_url": "https://repo1.dso.mil/uploads/-/system/user/avatar/2325/avatar.png",
    "email": "[REDACTED]"
  },
  "project_id": 13380,
  "project": {
    "id": 13380,
    "name": "Podinfo",
    "description": "Tiny web application that showcases best practices of running microservices",
    "web_url": "https://repo1.dso.mil/snekcode/podinfo",
    "avatar_url": "https://repo1.dso.mil/uploads/-/system/project/avatar/13380/podinfo.jpg",
    "git_ssh_url": "git@repo1.dso.mil:snekcode/podinfo.git",
    "git_http_url": "https://repo1.dso.mil/snekcode/podinfo.git",
    "namespace": "Patrick Kelly",
    "visibility_level": 20,
    "path_with_namespace": "snekcode/podinfo",
    "default_branch": "main",
    "ci_config_path": "pipelines/sandbox.yaml@big-bang/pipeline-templates/pipeline-templates:master",
    "homepage": "https://repo1.dso.mil/snekcode/podinfo",
    "url": "git@repo1.dso.mil:snekcode/podinfo.git",
    "ssh_url": "git@repo1.dso.mil:snekcode/podinfo.git",
    "http_url": "https://repo1.dso.mil/snekcode/podinfo.git"
  },
  "object_attributes": {
    "attachment": null,
    "author_id": 2325,
    "change_position": null,
    "commit_id": null,
    "created_at": "2023-06-15 19:25:32 UTC",
    "discussion_id": "ab099d385ba80ca7dd19451016280ce2bac676fd",
    "id": 1341452,
    "line_code": null,
    "note": "test comment",
    "noteable_id": 142064,
    "noteable_type": "MergeRequest",
    "original_position": null,
    "position": null,
    "project_id": 13380,
    "resolved_at": null,
    "resolved_by_id": null,
    "resolved_by_push": null,
    "st_diff": null,
    "system": false,
    "type": null,
    "updated_at": "2023-06-15 19:25:32 UTC",
    "updated_by_id": null,
    "description": "test comment",
    "url": "https://repo1.dso.mil/snekcode/podinfo/-/merge_requests/10#note_1341452"
  },
  "repository": {
    "name": "Podinfo",
    "url": "git@repo1.dso.mil:snekcode/podinfo.git",
    "description": "Tiny web application that showcases best practices of running microservices",
    "homepage": "https://repo1.dso.mil/snekcode/podinfo"
  },
  "merge_request": {
    "assignee_id": null,
    "author_id": 26852,
    "created_at": "2023-06-14 23:12:32 UTC",
    "description": null,
    "head_pipeline_id": 1867691,
    "id": 142064,
    "iid": 10,
    "last_edited_at": null,
    "last_edited_by_id": null,
    "merge_commit_sha": null,
    "merge_error": null,
    "merge_params": { "force_remove_source_branch": true },
    "merge_status": "can_be_merged",
    "merge_user_id": null,
    "merge_when_pipeline_succeeds": false,
    "milestone_id": null,
    "source_branch": "PR-9",
    "source_project_id": 13380,
    "state_id": 1,
    "target_branch": "main",
    "target_project_id": 13380,
    "time_estimate": 0,
    "title": "PR-9",
    "updated_at": "2023-06-15 19:25:32 UTC",
    "updated_by_id": null,
    "url": "https://repo1.dso.mil/snekcode/podinfo/-/merge_requests/10",
    "source": {
      "id": 13380,
      "name": "Podinfo",
      "description": "Tiny web application that showcases best practices of running microservices",
      "web_url": "https://repo1.dso.mil/snekcode/podinfo",
      "avatar_url": "https://repo1.dso.mil/uploads/-/system/project/avatar/13380/podinfo.jpg",
      "git_ssh_url": "git@repo1.dso.mil:snekcode/podinfo.git",
      "git_http_url": "https://repo1.dso.mil/snekcode/podinfo.git",
      "namespace": "Patrick Kelly",
      "visibility_level": 20,
      "path_with_namespace": "snekcode/podinfo",
      "default_branch": "main",
      "ci_config_path": "pipelines/sandbox.yaml@big-bang/pipeline-templates/pipeline-templates:master",
      "homepage": "https://repo1.dso.mil/snekcode/podinfo",
      "url": "git@repo1.dso.mil:snekcode/podinfo.git",
      "ssh_url": "git@repo1.dso.mil:snekcode/podinfo.git",
      "http_url": "https://repo1.dso.mil/snekcode/podinfo.git"
    },
    "target": {
      "id": 13380,
      "name": "Podinfo",
      "description": "Tiny web application that showcases best practices of running microservices",
      "web_url": "https://repo1.dso.mil/snekcode/podinfo",
      "avatar_url": "https://repo1.dso.mil/uploads/-/system/project/avatar/13380/podinfo.jpg",
      "git_ssh_url": "git@repo1.dso.mil:snekcode/podinfo.git",
      "git_http_url": "https://repo1.dso.mil/snekcode/podinfo.git",
      "namespace": "Patrick Kelly",
      "visibility_level": 20,
      "path_with_namespace": "snekcode/podinfo",
      "default_branch": "main",
      "ci_config_path": "pipelines/sandbox.yaml@big-bang/pipeline-templates/pipeline-templates:master",
      "homepage": "https://repo1.dso.mil/snekcode/podinfo",
      "url": "git@repo1.dso.mil:snekcode/podinfo.git",
      "ssh_url": "git@repo1.dso.mil:snekcode/podinfo.git",
      "http_url": "https://repo1.dso.mil/snekcode/podinfo.git"
    },
    "last_commit": {
      "id": "5be8f4be74ad64d9c7964535c8deb2997d7ede24",
      "message": "test commit please ignore",
      "title": "test commit please ignore",
      "timestamp": "2023-05-30T16:28:26-05:00",
      "url": "https://repo1.dso.mil/snekcode/podinfo/-/commit/5be8f4be74ad64d9c7964535c8deb2997d7ede24",
      "author": {
        "name": "Mr. Snake",
        "email": "46388252+SnekCode@users.noreply.github.com"
      }
    },
    "work_in_progress": false,
    "total_time_spent": 0,
    "time_change": 0,
    "human_total_time_spent": null,
    "human_time_change": null,
    "human_time_estimate": null,
    "assignee_ids": [],
    "reviewer_ids": [],
    "labels": [],
    "state": "opened",
    "blocking_discussions_resolved": true,
    "first_contribution": false,
    "detailed_merge_status": "mergeable"
  }
}
