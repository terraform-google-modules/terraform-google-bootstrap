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
	"testing"

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
	if resp.StatusCode != 404 && err != nil {
		gl.t.Fatalf("got status code %d, error %s", resp.StatusCode, err.Error())
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
