param(
    [string]$Owner,
    [string]$RepoName,
    [switch]$Private
)

function PromptIfEmpty([string]$value, [string]$prompt) {
    if ([string]::IsNullOrWhiteSpace($value)) {
        return Read-Host $prompt
    }
    return $value
}

$Owner = PromptIfEmpty $Owner 'GitHub owner (user or org)'
$RepoName = PromptIfEmpty $RepoName 'Repository name'

Write-Host "Initializing git repository (if needed)..."
if (-not (Test-Path .git)) {
    git init
}

Write-Host "Adding files and committing..."
git add .
if (-not (git rev-parse --verify HEAD 2>$null)) {
    git commit -m "chore: initial commit"
} else {
    try {
        git commit -m "chore: update"
    } catch {
        Write-Host "Nothing to commit"
    }
}

$visibility = if ($Private) { '--private' } else { '--public' }

Write-Host "Creating repo on GitHub (gh CLI must be installed and authenticated)..."
gh repo create "$Owner/$RepoName" $visibility --source=. --remote=origin --push

if ($LASTEXITCODE -ne 0) {
    Write-Host "gh repo create failed. You can create the repo manually on github.com and then run the manual push commands described in README_GIT.md" -ForegroundColor Yellow
} else {
    Write-Host "Repository created and pushed successfully." -ForegroundColor Green
}
