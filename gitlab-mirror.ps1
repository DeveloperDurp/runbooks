$ProjectName = Read-Host "What is the name of the project?"

$gitlabDefaultHeaders = @{
  "PRIVATE-TOKEN" = $GITLAB_TOKEN
  "Content-Type"="application/json"
}
$gitlabBaseURI = "https://gitlab.com/api/v4"

#Create Gitlab Repo
$irm = @{
  uri = "$gitlabBaseURI/projects"
  headers = $gitlabDefaultHeaders 
  method = "Post"
  body = @{
    "name" = $ProjectName
    "path" = $ProjectName
    "initialize_with_readme"="true"
    "visibility"="public"
  } | convertto-json 
}
$gitlabProject = Invoke-RestMethod @irm 

#Create repos in github/gitea and add to gitlab mirror
$repos = @(
  @{
    DefaultHeaders = @{
      "Authorization" = "Bearer $GITHUB_TOKEN"
      "Content-Type" = "application/vnd.github+json"
    }
    BaseURL = "https://api.github.com"
    token = $GITHUB_TOKEN
  },
  @{
    DefaultHeaders = @{
      "Authorization" = "Bearer $GITEA_TOKEN"
      "Content-Type" = "application/json"
    }
    BaseURL = "https://gitea.durp.info/api/v1"
    token = $GITEA_TOKEN
  }
)

foreach ($repo in $repos)
{
  $irm = @{
    uri = "$($repo.BaseURL)/user/repos"
    headers = $repo.DefaultHeaders 
    method = "Post"
    body = @{
      "name" = $ProjectName
    } | convertto-json 
  }
  $project = Invoke-RestMethod @irm 

  $clone = $project.clone_url -replace "https://","https://developerdurp:$($repo.token)@"

  $irm = @{
    uri = "$gitlabBaseURI/projects/$($gitlabProject.id)/remote_mirrors"
    headers = $gitlabDefaultHeaders 
    method = "Post"
    body = @{
      "url" = $clone
      "enabled" = "true"
    } | ConvertTo-Json
  }

  $mirror = Invoke-RestMethod @irm 

  $irm = @{
    uri = "$gitlabBaseURI/projects/$($gitlabProject.id)/remote_mirrors/$($mirror.id)/sync"
    headers = $gitlabDefaultHeaders 
    method = "Post"
  }

  Invoke-RestMethod @irm

}
