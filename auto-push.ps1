


# SKY BUSINESS - GITHUB AUTO PUSH

$ErrorActionPreference = "Stop"

$Branch = "main"
$Remote = "origin"
$DelaySeconds = 2

function Get-GitStatus {
    $result = @(git status --porcelain)

    if ($LASTEXITCODE -ne 0) {
        throw "Git status failed"
    }

    return ($result -join "`n")
}

Write-Host "===================================="
Write-Host "      SKY BUSINESS AUTO PUSH"
Write-Host "===================================="

git rev-parse --show-toplevel | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "Not a Git repository"
}

$currentBranch = git branch --show-current

if ($currentBranch -ne $Branch) {
    throw "Please switch to main branch"
}

git remote get-url $Remote | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "GitHub remote not found"
}

Write-Host "Repository : Connected"
Write-Host "Branch     : $Branch"
Write-Host "Status     : Running"
Write-Host "===================================="

$lastStatus = Get-GitStatus

while ($true) {
    try {
        Start-Sleep -Seconds 1

        $currentStatus = Get-GitStatus

        if ($currentStatus -eq $lastStatus) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($currentStatus)) {
            $lastStatus = $currentStatus
            continue
        }

        Write-Host "Changes detected..."

        Start-Sleep -Seconds $DelaySeconds

        $stableStatus = Get-GitStatus

        if ($stableStatus -ne $currentStatus) {
            $lastStatus = $stableStatus
            continue
        }

        git add -A

        if ($LASTEXITCODE -ne 0) {
            throw "Git add failed"
        }

        $staged = @(git diff --cached --name-only)

        if ($LASTEXITCODE -ne 0) {
            throw "Git diff failed"
        }

        if ($staged.Count -gt 0) {
            $message = "Auto update: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

            git commit -m $message

            if ($LASTEXITCODE -ne 0) {
                throw "Git commit failed"
            }

            Write-Host "Pushing to GitHub..."

            git push $Remote HEAD

            if ($LASTEXITCODE -ne 0) {
                throw "Git push failed"
            }

            Write-Host "SUCCESS: GitHub updated!" -ForegroundColor Green
        }

        $lastStatus = Get-GitStatus
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        Write-Host "Retrying in 5 seconds..."
        Start-Sleep -Seconds 5
        $lastStatus = Get-GitStatus
    }
}
