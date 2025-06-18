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
	"context"
	"testing"

	"github.com/google/go-github/v72/github"
)

const (
	GitHubOwner = "infra-manager-bootstrap-module"
	GitHubAppID = "68754904" // Found in the URL of your Cloud Build GitHub app configuration settings
)

type GitHubClient struct {
	t          *testing.T
	client     *github.Client
	owner      string
	repoName   string
	Repository *github.Repository
}

func NewGitHubClient(t *testing.T, token, repo string) *GitHubClient {
	t.Helper()
	client := github.NewClient(nil).WithAuthToken(token)
	return &GitHubClient{
		t:        t,
		client:   client,
		owner:    GitHubOwner,
		repoName: repo,
	}
}

// GetOpenPullRequest gets an open pull request for a given branch if it exists.
func (gh *GitHubClient) GetOpenPullRequest(ctx context.Context, branch string) *github.PullRequest {
	opts := &github.PullRequestListOptions{
		State: "open",
		Head:  branch,
	}
	prs, resp, err := gh.client.PullRequests.List(ctx, gh.owner, gh.repoName, opts)
	if resp.StatusCode != 422 && err != nil {
		gh.t.Fatal(err.Error())
	}
	if len(prs) == 0 {
		return nil
	}
	return prs[0]
}

func (gh *GitHubClient) CreatePullRequest(ctx context.Context, title, branch, base string) *github.PullRequest {
	newPR := &github.NewPullRequest{
		Title: github.String(title),
		Head:  github.String(branch),
		Base:  github.String(base),
	}
	pr, _, err := gh.client.PullRequests.Create(ctx, gh.owner, gh.repoName, newPR)
	if err != nil {
		gh.t.Fatal(err.Error())
	}
	return pr
}

func (gh *GitHubClient) MergePullRequest(ctx context.Context, pr *github.PullRequest, commitTitle, commitMessage string) *github.PullRequestMergeResult {
	result, _, err := gh.client.PullRequests.Merge(ctx, gh.owner, gh.repoName, *pr.Number, commitMessage, nil)
	if err != nil {
		gh.t.Fatal(err.Error())
	}
	return result
}

func (gh *GitHubClient) ClosePullRequest(ctx context.Context, pr *github.PullRequest) {
	pr.State = github.String("closed")
	_, _, err := gh.client.PullRequests.Edit(ctx, gh.owner, gh.repoName, *pr.Number, pr)
	if err != nil {
		gh.t.Fatal(err.Error())
	}
}

func (gh *GitHubClient) GetRepository(ctx context.Context) *github.Repository {
	repo, resp, err := gh.client.Repositories.Get(ctx, gh.owner, gh.repoName)
	if resp.StatusCode != 404 && err != nil {
		gh.t.Fatal(err.Error())
	}
	gh.Repository = repo
	return repo
}
