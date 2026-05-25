# 1. Environment initialization

if (Test-Path "/opt/homebrew/bin/brew") {
    & /opt/homebrew/bin/brew shellenv | Invoke-Expression
}

Import-Module PSReadLine
Import-Module PSFzf
Import-Module Terminal-Icons
Import-Module posh-git
Import-Module nvm

# 2. Navigation and configuration functions

Function GoRoot {Set-Location -Path ~/}
Function GoDesktop {Set-Location -Path ~/Desktop}
Function GoProj {Set-Location -Path ~/_proj}
Function GoDocuments {Set-Location -Path ~/Documents}
Function OpenZshConfig {code ~/.zshrc }
Function OpenFishConfig {code ~/.config/fish/config.fish }
Function OpenPwshConfig {code ~/.config/powershell/Microsoft.PowerShell_profile.ps1 }

Set-Alias -Name "desktop" -Value GoDesktop
Set-Alias -Name "root" -Value GoRoot
Set-Alias -Name "proj" -Value GoProj
Set-Alias -Name "documents" -Value GoDocuments

Set-Alias -Name "zshconfig" -Value OpenZshConfig
Set-Alias -Name "fishconfig" -Value OpenFishConfig
Set-Alias -Name "pwshconfig" -Value OpenPwshConfig

Set-Alias -Name "t" -Value "terraform"
Set-Alias -Name "d" -Value "docker"
Set-Alias -Name "p" -Value "podman"
Set-Alias -Name "k" -Value "kubectl"
Set-Alias -Name "g" -Value "git"
Set-Alias -Name "tf" -Value "sh ./terraform.sh"

# 3. Environment Variables

# Azure DevOps
$env:POSH_AZURE_ENABLED = $true
$env:AZDO_ORG_SERVICE_URL = "https://dev.azure.com/pagopaspa"

# Aws
$env:AWS_DEFAULT_PROFILE = "default"

# Terraform StateGraph Config
$env:TF_HTTP_USERNAME = "session"
$env:TF_HTTP_PASSWORD = "<password>"
$env:STATEGRAPH_API_KEY = "$env:TF_HTTP_PASSWORD"
$env:STATEGRAPH_API_BASE = "https://stategraph.dev.dx.pagopa.it"

# GitHub PAT (Registry)
$env:CR_PAT = "<pat>"

# GPG & Cryptography
$env:GPG_TTY = $(tty)
gpgconf --launch gpg-agent

# Oh My Posh
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Krusty93/OhMyPoshCustomThemes/refs/heads/main/MacOS/oh-my-posh.json" | Invoke-Expression

$env:POSH_AZURE_ENABLED = $true

# 4. Shell Behavior
# Opzioni Fzf
Set-PsFzfOption -PSReadLineChordProvider 'Ctrl+f' -PSReadLineChordReverseHistory 'Ctrl+r'

# Shortcuts for navigation across words
Set-PSReadlineKeyHandler -Key Alt+LeftArrow -Function ShellBackwardWord
Set-PSReadlineKeyHandler -Key Alt+RightArrow -Function ShellForwardWord

# Quick search in history
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Restpre Predictive IntelliSense (last 10 commands)
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

# Native autocomplete for external cli tools
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
     param($commandName, $wordToComplete, $cursorPosition)
         dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
         }
}

# 5. az cli & Terraform automation

function az {
    $azExe = Get-Command az -CommandType Application | Select-Object -ExpandProperty Source
    
    & $azExe $args

    $isAccountSet = ($args.Count -ge 2 -and $args[0] -eq "account" -and $args[1] -eq "set")
    $isLogin = ($args.Count -ge 1 -and $args[0] -eq "login")

    if ($? -and ($isAccountSet -or $isLogin)) {
        Write-Host "`n[Sync] Allineamento ARM_SUBSCRIPTION_ID per Terraform..." -ForegroundColor Cyan
        $currentSubId = & $azExe account show --query id -o tsv 2>$null
        if ($currentSubId) {
            $env:ARM_SUBSCRIPTION_ID = $currentSubId
            Write-Host "[Sync] ARM_SUBSCRIPTION_ID impostata su: $currentSubId" -ForegroundColor Green
        }
    }
}

# 6. Startup execution

# Configure Node.js
Set-NodeVersion v22.0.0

# Azure auto sync at terminal startup
if (Get-Command az -ErrorAction SilentlyContinue) {
    $initialSub = az account show --query id -o tsv 2>$null
    if ($initialSub) { 
        $env:ARM_SUBSCRIPTION_ID = $initialSub 
    }
}
