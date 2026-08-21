// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//	http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package utils

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/xanzy/go-gitlab"
)

const (
	GitlabGroup   = "terraform-google-bootstrap"
	gitlabGroupID = 108396266
)

type GitLabClient struct {
	t         *testing.T
	client    *gitlab.Client
	group     string
	namespace int
	repo      string
	Project   *gitlab.Project
}

func NewGitLabClient(t *testing.T, token, projectName string) *GitLabClient {
	t.Helper()
	client, err := gitlab.NewClient(token)
	if err != nil {
		t.Fatal(err.Error())
	}
	return &GitLabClient{
		t:         t,
		client:    client,
		group:     GitlabGroup,
		namespace: gitlabGroupID,
		repo:      projectName,
	}
}

func (gl *GitLabClient) ProjectName() string {
	return fmt.Sprintf("%s/%s", gl.group, gl.repo)
}

func (gl *GitLabClient) GetProject() *gitlab.Project {
	proj, resp, err := gl.client.Projects.GetProject(gl.ProjectName(), nil)
	if err != nil {
		status := 0
		if resp != nil {
			status = resp.StatusCode
		}
		gl.t.Fatalf("failed to retrieve GitLab project %s (status code %d): %v", gl.ProjectName(), status, err)
	}
	gl.Project = proj
	return proj
}

// GetOpenMergeRequest gets the last opened merge request for a given branch if it exists.
func (gl *GitLabClient) GetOpenMergeRequest(branch string) *gitlab.MergeRequest {
	opts := gitlab.ListProjectMergeRequestsOptions{
		State:        gitlab.Ptr("opened"),
		SourceBranch: gitlab.Ptr(branch),
	}
	mergeRequests, _, err := gl.client.MergeRequests.ListProjectMergeRequests(gl.ProjectName(), &opts)
	if err != nil {
		gl.t.Fatal(err.Error())
	}
	if len(mergeRequests) == 0 {
		return nil
	}
	return mergeRequests[len(mergeRequests)-1]
}

func (gl *GitLabClient) CreateMergeRequest(title, branch, base string) *gitlab.MergeRequest {
	opts := gitlab.CreateMergeRequestOptions{
		Title:        gitlab.Ptr(title),
		SourceBranch: gitlab.Ptr(branch),
		TargetBranch: gitlab.Ptr(base),
	}
	mergeRequest, _, err := gl.client.MergeRequests.CreateMergeRequest(gl.ProjectName(), &opts)
	if err != nil {
		gl.t.Fatal(err.Error())
	}
	return mergeRequest
}

func (gl *GitLabClient) CloseMergeRequest(mr *gitlab.MergeRequest) {
	_, err := gl.client.MergeRequests.DeleteMergeRequest(gl.ProjectName(), mr.IID)
	if err != nil {
		gl.t.Fatal(err.Error())
	}
}

func (gl *GitLabClient) AcceptMergeRequest(mr *gitlab.MergeRequest, commitMessage string) *gitlab.MergeRequest {
	opts := gitlab.AcceptMergeRequestOptions{
		ShouldRemoveSourceBranch: gitlab.Ptr(true),
	}
	merged, resp, err := gl.client.MergeRequests.AcceptMergeRequest(gl.ProjectName(), mr.IID, &opts)
	if err != nil {
		gl.t.Fatal(err.Error())
	}
	if resp.StatusCode != 200 {
		gl.t.Fatalf("failed to accept merge request %v", resp)
	}
	return merged
}

// DeleteWebhookByKey deletes webhooks for the project that contain the given key in their URL.
func (gl *GitLabClient) DeleteWebhookByKey(webhookKey string) {
	if webhookKey == "" {
		gl.t.Log("Webhook key is empty, skipping deletion.")
		return
	}

	opts := &gitlab.ListProjectHooksOptions{
		PerPage: 100,
		Page:    1,
	}

	for {
		hooks, resp, err := gl.client.Projects.ListProjectHooks(gl.ProjectName(), opts)
		if err != nil {
			gl.t.Fatal(err.Error())
		}

		for _, hook := range hooks {
			if strings.Contains(hook.URL, webhookKey) {
				_, err := gl.client.Projects.DeleteProjectHook(gl.ProjectName(), hook.ID)
				if err != nil {
					gl.t.Fatal(err.Error())
				}
				gl.t.Logf("Deleted GitLab webhook with ID %d and URL %s", hook.ID, hook.URL)
			}
		}

		if resp.NextPage == 0 {
			break
		}
		opts.Page = resp.NextPage
	}
}

// CleanStaleWebhooks removes Cloud Build webhooks older than maxAge (e.g. 1 hour)
// to prevent hook limit exhaustion while preserving active webhooks from concurrent test runs.
func (gl *GitLabClient) CleanStaleWebhooks(maxAge time.Duration) {
	opts := &gitlab.ListProjectHooksOptions{
		PerPage: 100,
		Page:    1,
	}

	for {
		hooks, resp, err := gl.client.Projects.ListProjectHooks(gl.ProjectName(), opts)
		if err != nil {
			gl.t.Logf("Warning: could not list GitLab webhooks for %s: %v", gl.ProjectName(), err)
			return
		}

		gl.t.Logf("GitLab project %s currently has %d/100 webhooks registered", gl.ProjectName(), len(hooks))

		for _, hook := range hooks {
			if strings.Contains(hook.URL, "cloudbuild.googleapis.com") {
				if hook.CreatedAt != nil && time.Since(*hook.CreatedAt) > maxAge {
					_, err := gl.client.Projects.DeleteProjectHook(gl.ProjectName(), hook.ID)
					if err != nil {
						gl.t.Logf("Warning: failed to delete stale webhook ID %d: %v", hook.ID, err)
					} else {
						gl.t.Logf("Cleaned up stale GitLab webhook ID %d (age: %v, URL: %s)", hook.ID, time.Since(*hook.CreatedAt).Round(time.Minute), hook.URL)
					}
				} else if hook.CreatedAt != nil {
					gl.t.Logf("Preserving active/recent webhook ID %d (age: %v)", hook.ID, time.Since(*hook.CreatedAt).Round(time.Second))
				}
			}
		}

		if resp.NextPage == 0 {
			break
		}
		opts.Page = resp.NextPage
	}
}

