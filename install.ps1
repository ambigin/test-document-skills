<#
.SYNOPSIS
  Install test-document-skills skills for Claude Code and/or GitHub Copilot.

.DESCRIPTION
  Run without parameters for an interactive picker. Every parameter you pass skips its prompt.

  Install locations:
    Claude Code     global: ~\.claude\skills     project: <project>\.claude\skills
    GitHub Copilot  global: ~\.copilot\skills    project: <project>\.github\skills

  Works with Windows PowerShell 5.1 and PowerShell 7.

.PARAMETER Agent
  claude, copilot, or both (claude,copilot).
.PARAMETER Scope
  global (your user account) or project.
.PARAMETER ProjectDir
  Project root for -Scope project (default: current directory).
.PARAMETER Skills
  Skill names to install (comma-separated).
.PARAMETER All
  Select every skill.
.PARAMETER Link
  Link skills with a directory junction instead of copying them (needs a local clone).
.PARAMETER Uninstall
  Remove the selected skills instead of installing them.
.PARAMETER List
  Show available skills and where they are installed, then exit.
.PARAMETER DryRun
  Show what would happen without changing anything.
.PARAMETER Yes
  Don't ask for confirmation.
.PARAMETER Ref
  Branch or tag to download when not run from a clone (default: main).
.PARAMETER NoTui
  Use numbered prompts instead of the arrow-key menu.

.EXAMPLE
  .\install.ps1
.EXAMPLE
  .\install.ps1 -Agent claude,copilot -Scope project -Skills test-case-generator,bug-report-generator
.EXAMPLE
  irm https://raw.githubusercontent.com/ambigin/test-document-skills/main/install.ps1 | iex
.EXAMPLE
  & ([scriptblock]::Create((irm https://raw.githubusercontent.com/ambigin/test-document-skills/main/install.ps1))) -All -Agent claude -Scope global -Yes
#>
param(
    [string[]]$Agent,
    [string]$Scope,
    [string]$ProjectDir,
    [string[]]$Skills,
    [switch]$All,
    [switch]$Link,
    [switch]$Uninstall,
    [switch]$List,
    [switch]$DryRun,
    [switch]$Yes,
    [string]$Ref = 'main',
    [switch]$NoTui,
    [switch]$Help
)

# Everything lives in one function so that `irm ... | iex` doesn't leave
# variables behind in the caller's session, and never calls `exit` there.
function Invoke-LeapfrogInstaller {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'

    $repo = 'ambigin/test-document-skills'
    $userHome = $env:USERPROFILE
    if (-not $userHome) { $userHome = $HOME }

    if ($Help) {
        Write-Host @'
Install test-document-skills skills for Claude Code and/or GitHub Copilot.

Usage: install.ps1 [options]

Run without options for an interactive picker. Every option you pass skips its prompt.

  -Agent LIST        claude, copilot, or claude,copilot
  -Scope SCOPE       global (your user account) or project
  -ProjectDir PATH   Project root for -Scope project (default: current directory)
  -Skills LIST       Comma-separated skill names
  -All               Select every skill
  -Link              Link skills with a directory junction instead of copying (needs a local clone)
  -Uninstall         Remove the selected skills instead of installing them
  -List              Show available skills and where they are installed, then exit
  -DryRun            Show what would happen without changing anything
  -Yes               Don't ask for confirmation
  -Ref REF           Branch or tag to download when not run from a clone (default: main)
  -NoTui             Use numbered prompts instead of the arrow-key menu
  -Help              Show this help

Install locations:
  Claude Code     global: ~\.claude\skills     project: <project>\.claude\skills
  GitHub Copilot  global: ~\.copilot\skills    project: <project>\.github\skills
'@
        return
    }

    # -----------------------------------------------------------------------
    # Output helpers

    function Write-Seg([string]$Text, [string]$Color) {
        if ($Color) { Write-Host $Text -NoNewline -ForegroundColor $Color } else { Write-Host $Text -NoNewline }
    }
    function Write-Warn([string]$Text) { Write-Seg '! ' Yellow; Write-Host $Text }
    function Write-Info([string]$Text) { Write-Host $Text -ForegroundColor DarkGray }

    function Get-Fitted([string]$Text, [int]$Room) {
        if ($Text.Length -le $Room) { return $Text }
        if ($Room -lt 10) { return '' }
        return $Text.Substring(0, $Room - 3) + '...'
    }

    # Skill descriptions use a few typographic characters that older consoles
    # can't show.
    function ConvertTo-Plain([string]$Text) {
        return $Text.Replace([string][char]0x2014, '-').Replace([string][char]0x2013, '-').
            Replace([string][char]0x2265, '>=').Replace([string][char]0x2264, '<=').
            Replace([string][char]0x2019, "'").Replace([string][char]0x201C, '"').Replace([string][char]0x201D, '"')
    }

    # -----------------------------------------------------------------------
    # Input and menus

    $useTui = $false
    if (-not $NoTui) {
        try {
            $useTui = (-not [Console]::IsInputRedirected) -and (-not [Console]::IsOutputRedirected)
            if ($useTui) { [void][Console]::CursorVisible }
        } catch { $useTui = $false }
    }

    function Read-Answer([string]$Prompt) {
        Write-Host $Prompt -NoNewline
        if ([Console]::IsInputRedirected) {
            $line = [Console]::In.ReadLine()
            if ($null -eq $line) { throw 'no input available; pass the choices as parameters (see -Help) and add -Yes' }
            Write-Host ''
            return $line
        }
        return (Read-Host)
    }

    function Confirm-Step([string]$Question) {
        if ($Yes) { return $true }
        $answer = (Read-Answer "$Question [Y/n] ").Trim()
        return ($answer -eq '' -or $answer -match '^(y|yes)$')
    }

    function Stop-Cancelled { throw (New-Object OperationCanceledException 'Cancelled.') }

    # Items are objects with Label, Desc and Tag. Returns the picked indices.
    function Select-Menu([string]$Title, [object[]]$Items, [bool]$Multi, [int[]]$Preselect) {
        if ($useTui) { return (Select-MenuTui $Title $Items $Multi $Preselect) }
        return (Select-MenuNumbered $Title $Items $Multi $Preselect)
    }

    function Select-MenuTui([string]$Title, [object[]]$Items, [bool]$Multi, [int[]]$Preselect) {
        $n = $Items.Count
        $sel = New-Object bool[] $n
        foreach ($i in $Preselect) { $sel[$i] = $true }
        $cur = 0
        if (-not $Multi -and $Preselect.Count -gt 0) { $cur = $Preselect[0] }
        $labelW = ($Items | ForEach-Object { $_.Label.Length } | Measure-Object -Maximum).Maximum

        Write-Host ''
        Write-Host $Title -ForegroundColor White
        if ($Multi) {
            Write-Info 'Up/Down move - Space toggle - A all - N none - Enter confirm - Q quit'
        } else {
            Write-Info 'Up/Down move - Enter select - Q quit'
        }

        $msg = ''
        $top = -1
        [Console]::CursorVisible = $false
        try {
            while ($true) {
                $width = [Console]::BufferWidth - 1
                if ($top -ge 0) { [Console]::SetCursorPosition(0, $top) }
                for ($i = 0; $i -lt $n; $i++) {
                    $item = $Items[$i]
                    $isCur = ($i -eq $cur)
                    $pointer = ' '
                    if ($isCur) { $pointer = '>' }
                    $used = 3
                    Write-Seg " $pointer " Cyan
                    if ($Multi) {
                        if ($sel[$i]) { Write-Seg '[x] ' Green } else { Write-Seg '[ ] ' }
                        $used += 4
                    }
                    $labelColor = ''
                    if ($isCur) { $labelColor = 'Cyan' }
                    Write-Seg $item.Label.PadRight($labelW + 2) $labelColor
                    $used += $labelW + 2
                    $tag = ''
                    if ($item.Tag) { $tag = "  [$($item.Tag)]" }
                    $desc = Get-Fitted $item.Desc ($width - $used - $tag.Length)
                    Write-Seg $desc DarkGray
                    $used += $desc.Length
                    if ($tag) {
                        $tagColor = 'Yellow'
                        if ($item.Tag -eq 'installed') { $tagColor = 'Green' }
                        Write-Seg $tag $tagColor
                        $used += $tag.Length
                    }
                    Write-Host (' ' * [Math]::Max(0, $width - $used))
                }
                Write-Host ($msg.PadRight($width)) -ForegroundColor Yellow
                $msg = ''
                if ($top -lt 0) { $top = [Console]::CursorTop - ($n + 1) }

                $key = [Console]::ReadKey($true)
                $ch = [string]$key.KeyChar
                if ($key.Key -eq 'UpArrow' -or $ch -eq 'k') {
                    $cur = ($cur + $n - 1) % $n
                } elseif ($key.Key -eq 'DownArrow' -or $ch -eq 'j') {
                    $cur = ($cur + 1) % $n
                } elseif ($key.Key -eq 'Spacebar') {
                    if ($Multi) { $sel[$cur] = -not $sel[$cur] }
                } elseif ($Multi -and $ch -eq 'a') {
                    for ($i = 0; $i -lt $n; $i++) { $sel[$i] = $true }
                } elseif ($Multi -and $ch -eq 'n') {
                    for ($i = 0; $i -lt $n; $i++) { $sel[$i] = $false }
                } elseif ($key.Key -eq 'Escape' -or $ch -eq 'q') {
                    Stop-Cancelled
                } elseif ($key.Key -eq 'Enter') {
                    if (-not $Multi) { return , @($cur) }
                    $picked = @()
                    for ($i = 0; $i -lt $n; $i++) { if ($sel[$i]) { $picked += $i } }
                    if ($picked.Count -gt 0) { return , $picked }
                    $msg = 'Select at least one item with Space (or press A for all).'
                }
            }
        } finally {
            [Console]::CursorVisible = $true
        }
    }

    function Select-MenuNumbered([string]$Title, [object[]]$Items, [bool]$Multi, [int[]]$Preselect) {
        $n = $Items.Count
        $labelW = ($Items | ForEach-Object { $_.Label.Length } | Measure-Object -Maximum).Maximum
        $width = 100
        try { if (-not [Console]::IsOutputRedirected) { $width = [Console]::BufferWidth - 1 } } catch { }
        Write-Host ''
        Write-Host $Title -ForegroundColor White
        for ($i = 0; $i -lt $n; $i++) {
            $tag = ''
            if ($Items[$i].Tag) { $tag = " [$($Items[$i].Tag)]" }
            Write-Seg ('  {0,2}) {1}  ' -f ($i + 1), $Items[$i].Label.PadRight($labelW))
            Write-Seg (Get-Fitted $Items[$i].Desc ($width - $labelW - $tag.Length - 8)) DarkGray
            Write-Host $tag
        }
        while ($true) {
            if ($Multi) { $prompt = 'Enter numbers separated by commas, or "all": ' } else { $prompt = 'Enter a number: ' }
            $answer = (Read-Answer $prompt).Trim()
            if ($answer -eq '' -and $Preselect.Count -gt 0) { return , $Preselect }
            $picked = @()
            $ok = $true
            if ($Multi -and $answer -eq 'all') {
                $picked = @(0..($n - 1))
            } else {
                foreach ($tok in ($answer -split '[,\s]+' | Where-Object { $_ })) {
                    $num = 0
                    if ([int]::TryParse($tok, [ref]$num) -and $num -ge 1 -and $num -le $n) {
                        if ($picked -notcontains ($num - 1)) { $picked += ($num - 1) }
                    } else {
                        $ok = $false
                    }
                }
            }
            if (-not $Multi -and $picked.Count -ne 1) { $ok = $false }
            if ($ok -and $picked.Count -gt 0) { return , $picked }
            Write-Host 'Invalid choice, try again.' -ForegroundColor Yellow
        }
    }

    # -----------------------------------------------------------------------
    # Validate parameters

    $agents = @()
    foreach ($a in ($Agent -split ',' | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })) {
        if ($a -eq 'claude' -or $a -eq 'copilot') {
            if ($agents -notcontains $a) { $agents += $a }
        } elseif ($a -eq 'all' -or $a -eq 'both') {
            $agents = @('claude', 'copilot')
        } else {
            throw "unknown agent '$a' (use claude and/or copilot)"
        }
    }
    $scopeValue = ''
    if ($Scope) {
        $scopeValue = $Scope.ToLower()
        if ($scopeValue -ne 'global' -and $scopeValue -ne 'project') { throw "-Scope must be 'global' or 'project'" }
    }

    function Resolve-ProjectDir([string]$Dir) {
        if ($Dir -eq '~' -or $Dir.StartsWith('~\') -or $Dir.StartsWith('~/')) { $Dir = $userHome + $Dir.Substring(1) }
        if (-not (Test-Path -LiteralPath $Dir -PathType Container)) { return $null }
        return (Resolve-Path -LiteralPath $Dir).ProviderPath
    }
    $projectPath = ''
    if ($ProjectDir) {
        $projectPath = Resolve-ProjectDir $ProjectDir
        if (-not $projectPath) { throw "project directory not found: $ProjectDir" }
    }

    # -----------------------------------------------------------------------
    # Skills source

    $tmpDir = $null
    try {
        $scriptDir = $PSScriptRoot
        if ($scriptDir -and (Test-Path -LiteralPath (Join-Path $scriptDir 'skills') -PathType Container)) {
            $skillsRoot = Join-Path $scriptDir 'skills'
            $sourceLabel = "local clone ($scriptDir)"
        } else {
            if ($Link) { throw '-Link needs a local clone of the repo; run .\install.ps1 from inside it' }
            $tmpDir = Join-Path ([IO.Path]::GetTempPath()) ('leapfrog-skills-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $tmpDir | Out-Null
            $zip = Join-Path $tmpDir 'repo.zip'
            $url = "https://codeload.github.com/$repo/zip/$Ref"
            Write-Info "Downloading $repo@$Ref ..."
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
            $hint = 'If the repo is private, sign in with "gh auth login" or set GITHUB_TOKEN, or clone the repo and run install.ps1 from it.'
            try {
                Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
            } catch {
                # Private repos need credentials: use a token from the environment or the GitHub CLI.
                $token = $env:GITHUB_TOKEN
                if (-not $token) { $token = $env:GH_TOKEN }
                if (-not $token -and (Get-Command gh -CommandType Application -ErrorAction SilentlyContinue)) {
                    $ErrorActionPreference = 'Continue'
                    $token = [string](& gh auth token 2>$null)
                    if ($LASTEXITCODE -ne 0) { $token = '' }
                    $ErrorActionPreference = 'Stop'
                }
                if (-not $token) { throw "couldn't download $url ($($_.Exception.Message)). $hint" }
                Write-Info 'Retrying with your GitHub credentials ...'
                $apiUrl = "https://api.github.com/repos/$repo/zipball/$Ref"
                $headers = @{ Authorization = "Bearer $($token.Trim())"; 'User-Agent' = 'test-document-skills-installer' }
                try {
                    Invoke-WebRequest -Uri $apiUrl -Headers $headers -OutFile $zip -UseBasicParsing
                } catch {
                    throw "couldn't download $apiUrl ($($_.Exception.Message)). $hint"
                }
            }
            Expand-Archive -LiteralPath $zip -DestinationPath $tmpDir -Force
            $skillsRoot = Get-ChildItem -LiteralPath $tmpDir -Directory |
                ForEach-Object { Join-Path $_.FullName 'skills' } |
                Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
                Select-Object -First 1
            if (-not $skillsRoot) { throw 'the downloaded archive has no skills folder' }
            $sourceLabel = "GitHub $repo@$Ref"
        }

        # Returns the first sentence of the SKILL.md frontmatter description,
        # joining the lines of a folded (>) block.
        function Get-SkillSummary([string]$Path) {
            $lines = [IO.File]::ReadAllLines($Path)
            if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') { return '' }
            $desc = ''
            $grab = $false
            for ($i = 1; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                if ($line.Trim() -eq '---') { break }
                if ($line -match '^description:\s*(.*)$') {
                    $desc = $Matches[1].Trim()
                    if ($desc -match '^[>|][-+]?$') { $desc = '' }
                    $grab = $true
                    continue
                }
                if ($grab -and $line -match '^\s+\S') {
                    $desc = ($desc + ' ' + $line.Trim()).Trim()
                    continue
                }
                $grab = $false
            }
            $desc = $desc.Trim('"', "'")
            $dot = $desc.IndexOf('. ')
            if ($dot -ge 0) { $desc = $desc.Substring(0, $dot + 1) }
            return (ConvertTo-Plain $desc)
        }

        $allSkills = @()
        foreach ($dir in (Get-ChildItem -LiteralPath $skillsRoot -Directory | Sort-Object Name)) {
            $skillFile = Join-Path $dir.FullName 'SKILL.md'
            if (-not (Test-Path -LiteralPath $skillFile)) { continue }
            $allSkills += [pscustomobject]@{ Name = $dir.Name; Desc = (Get-SkillSummary $skillFile) }
        }
        if ($allSkills.Count -eq 0) { throw "no skills found in $skillsRoot" }
        $skillNames = @($allSkills | ForEach-Object { $_.Name })

        $selected = @()
        foreach ($s in ($Skills -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
            if ($skillNames -notcontains $s) { throw "unknown skill '$s' (run with -List to see them)" }
            if ($selected -notcontains $s) { $selected += $s }
        }

        # -------------------------------------------------------------------
        # Install targets and status

        function Get-AgentLabel([string]$Name) {
            if ($Name -eq 'claude') { return 'Claude Code' }
            return 'GitHub Copilot'
        }

        function Get-TargetRoot([string]$AgentName, [string]$ScopeName) {
            if ($ScopeName -eq 'global') {
                if ($AgentName -eq 'claude') { return (Join-Path $userHome '.claude\skills') }
                return (Join-Path $userHome '.copilot\skills')
            }
            if ($AgentName -eq 'claude') { return (Join-Path $projectPath '.claude\skills') }
            return (Join-Path $projectPath '.github\skills')
        }

        function Test-IsLink([string]$Path) {
            $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
            return ($null -ne $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint))
        }

        function Get-TreeHashes([string]$Root) {
            $map = @{}
            $prefix = (Resolve-Path -LiteralPath $Root).ProviderPath.TrimEnd('\').Length
            foreach ($f in (Get-ChildItem -LiteralPath $Root -Recurse -File -Force)) {
                $map[$f.FullName.Substring($prefix)] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
            }
            return $map
        }

        # Returns none, linked, installed (same files) or outdated (files differ).
        function Get-SkillStatus([string]$Name, [string]$Dest) {
            if (Test-IsLink $Dest) { return 'linked' }
            if (-not (Test-Path -LiteralPath $Dest -PathType Container)) { return 'none' }
            $a = Get-TreeHashes (Join-Path $skillsRoot $Name)
            $b = Get-TreeHashes $Dest
            if ($a.Count -ne $b.Count) { return 'outdated' }
            foreach ($k in $a.Keys) { if ($b[$k] -ne $a[$k]) { return 'outdated' } }
            return 'installed'
        }

        # Combined status across the chosen agents, for the picker.
        function Get-StatusTag([string]$Name) {
            $have = 0
            $outdated = $false
            foreach ($a in $agents) {
                $st = Get-SkillStatus $Name (Join-Path (Get-TargetRoot $a $scopeValue) $Name)
                if ($st -ne 'none') { $have++ }
                if ($st -eq 'outdated') { $outdated = $true }
            }
            if ($outdated) { return 'update available' }
            if ($have -eq 0) { return '' }
            if ($have -lt $agents.Count) { return 'partly installed' }
            return 'installed'
        }

        # -------------------------------------------------------------------
        # -List

        if ($List) {
            if (-not $projectPath) { $projectPath = (Get-Location).ProviderPath }
            $listAgents = $agents
            if ($listAgents.Count -eq 0) { $listAgents = @('claude', 'copilot') }
            $listScopes = @('global', 'project')
            if ($scopeValue) { $listScopes = @($scopeValue) }
            $labelW = ($skillNames | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
            $width = 100
            try { if (-not [Console]::IsOutputRedirected) { $width = [Console]::BufferWidth - 1 } } catch { }
            Write-Host "Skills from $sourceLabel" -ForegroundColor White
            Write-Host ''
            foreach ($skill in $allSkills) {
                Write-Seg ('  ' + $skill.Name.PadRight($labelW) + '  ') Cyan
                Write-Host (Get-Fitted $skill.Desc ($width - $labelW - 4))
                $where = @()
                foreach ($sc in $listScopes) {
                    foreach ($a in $listAgents) {
                        $st = Get-SkillStatus $skill.Name (Join-Path (Get-TargetRoot $a $sc) $skill.Name)
                        if ($st -eq 'outdated') { $where += , @("$a/$sc (update available)", 'Yellow') }
                        elseif ($st -ne 'none') { $where += , @("$a/$sc ($st)", 'Green') }
                    }
                }
                if ($where.Count -gt 0) {
                    Write-Seg (' ' * ($labelW + 3))
                    foreach ($w in $where) { Write-Seg ('  ' + $w[0]) $w[1] }
                    Write-Host ''
                }
            }
            Write-Host ''
            Write-Info "Project status is for $projectPath"
            return
        }

        # -------------------------------------------------------------------
        # Interactive choices

        Write-Host 'test-document-skills skill installer' -ForegroundColor White
        Write-Info "Source: $sourceLabel"
        if ($Uninstall) { Write-Warn 'Uninstall mode: selected skills will be removed.' }

        if ($agents.Count -eq 0) {
            $items = @(
                [pscustomobject]@{ Label = 'Claude Code'; Desc = '~\.claude\skills or <project>\.claude\skills'; Tag = '' },
                [pscustomobject]@{ Label = 'GitHub Copilot'; Desc = '~\.copilot\skills or <project>\.github\skills'; Tag = '' }
            )
            foreach ($i in (Select-Menu 'Which assistants should get the skills?' $items $true @(0))) {
                $agents += @('claude', 'copilot')[$i]
            }
        }

        $askProjectDir = $false
        if (-not $scopeValue) {
            $items = @(
                [pscustomobject]@{ Label = 'Global'; Desc = 'Your user account: available in every project'; Tag = '' },
                [pscustomobject]@{ Label = 'Project'; Desc = 'One project only: commit it to share with your team'; Tag = '' }
            )
            $pick = @(Select-Menu 'Where should they go?' $items $false @(0))
            if ($pick[0] -eq 0) { $scopeValue = 'global' } else { $scopeValue = 'project'; $askProjectDir = $true }
        }

        if ($scopeValue -eq 'project' -and -not $projectPath) {
            $cwd = (Get-Location).ProviderPath
            if ($askProjectDir) {
                while (-not $projectPath) {
                    Write-Host ''
                    $answer = (Read-Answer "Project directory [$cwd]: ").Trim()
                    if (-not $answer) { $answer = $cwd }
                    $projectPath = Resolve-ProjectDir $answer
                    if (-not $projectPath) { Write-Warn "Directory not found: $answer" }
                }
            } else {
                $projectPath = $cwd
            }
        }
        if ($scopeValue -eq 'project' -and -not (Test-Path -LiteralPath (Join-Path $projectPath '.git'))) {
            Write-Warn "$projectPath is not the root of a git repository."
        }

        if ($All) {
            $selected = $skillNames
        } elseif ($selected.Count -eq 0) {
            $items = @()
            foreach ($skill in $allSkills) {
                $tag = Get-StatusTag $skill.Name
                # When uninstalling, only offer skills that are actually there.
                if ($Uninstall -and -not $tag) { continue }
                $items += [pscustomobject]@{ Label = $skill.Name; Desc = $skill.Desc; Tag = $tag }
            }
            if ($items.Count -eq 0) {
                Write-Host ''
                Write-Host 'No skills are installed there, so there is nothing to remove.'
                return
            }
            $title = 'Which skills do you want to install?'
            if ($Uninstall) { $title = 'Which skills should be removed?' }
            foreach ($i in (Select-Menu $title $items $true @())) { $selected += $items[$i].Label }
        }

        # -------------------------------------------------------------------
        # Plan, confirm, apply

        $plan = @()
        Write-Host ''
        Write-Host 'Plan' -ForegroundColor White
        foreach ($s in $selected) {
            foreach ($a in $agents) {
                $dest = Join-Path (Get-TargetRoot $a $scopeValue) $s
                $st = Get-SkillStatus $s $dest
                if ($Uninstall) {
                    if ($st -eq 'none') {
                        Write-Info ('  - {0,-28} not installed for {1}, skipping' -f $s, (Get-AgentLabel $a))
                        continue
                    }
                    $action = 'remove'
                } elseif ($st -eq 'none') {
                    $action = 'install'
                } elseif ($st -eq 'outdated') {
                    $action = 'update'
                } else {
                    $action = 'reinstall'
                }
                $plan += [pscustomobject]@{ Skill = $s; Agent = $a; Dest = $dest }
                Write-Host ('  {0,-9} {1,-32} -> {2}' -f $action, $s, $dest)
            }
        }

        if ($plan.Count -eq 0) {
            Write-Host ''
            Write-Host 'Nothing to do.'
            return
        }
        if ($DryRun) {
            Write-Host ''
            Write-Info 'Dry run: nothing was changed.'
            return
        }
        Write-Host ''
        if (-not (Confirm-Step 'Proceed?')) { Stop-Cancelled }

        function Remove-SkillDir([string]$Path) {
            if (Test-IsLink $Path) {
                # Deletes only the junction, never the folder it points to.
                [IO.Directory]::Delete($Path)
            } elseif (Test-Path -LiteralPath $Path) {
                Remove-Item -LiteralPath $Path -Recurse -Force
            }
        }

        Write-Host ''
        $ok = 0
        $failed = 0
        foreach ($p in $plan) {
            try {
                if ($Uninstall) {
                    Remove-SkillDir $p.Dest
                } else {
                    $src = Join-Path $skillsRoot $p.Skill
                    New-Item -ItemType Directory -Force -Path (Split-Path $p.Dest -Parent) | Out-Null
                    Remove-SkillDir $p.Dest
                    if ($Link) {
                        New-Item -ItemType Junction -Path $p.Dest -Target $src | Out-Null
                    } else {
                        Copy-Item -LiteralPath $src -Destination $p.Dest -Recurse -Force
                    }
                }
                $ok++
                Write-Seg '  [ok] ' Green
                Write-Seg "$($p.Skill) "
                Write-Info "($(Get-AgentLabel $p.Agent))"
            } catch {
                $failed++
                Write-Seg '  [failed] ' Red
                Write-Seg "$($p.Skill) "
                Write-Info "($(Get-AgentLabel $p.Agent)): $($_.Exception.Message)"
            }
        }

        Write-Host ''
        if ($Uninstall) {
            Write-Host "Removed $ok, failed $failed."
            if ($failed -gt 0) { throw "$failed item(s) could not be removed" }
            return
        }
        Write-Host "Installed $ok, failed $failed."

        # -------------------------------------------------------------------
        # Dependencies and next steps

        function Test-Native([string]$Exe, [string[]]$Arguments) {
            $ErrorActionPreference = 'Continue'
            try {
                & $Exe @Arguments *> $null
                return ($LASTEXITCODE -eq 0)
            } catch {
                return $false
            }
        }

        function Find-Python {
            foreach ($py in @('python', 'python3', 'py')) {
                if (-not (Get-Command $py -CommandType Application -ErrorAction SilentlyContinue)) { continue }
                if (Test-Native $py @('-c', 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)')) { return $py }
            }
            return $null
        }

        $needsOpenpyxl = $false
        foreach ($s in $selected) {
            $hit = Get-ChildItem -LiteralPath (Join-Path $skillsRoot $s) -Recurse -Filter '*.py' -File |
                Select-String -Pattern 'openpyxl' -SimpleMatch -List
            if ($hit) { $needsOpenpyxl = $true }
        }

        if ($needsOpenpyxl) {
            $py = Find-Python
            if (-not $py) {
                Write-Host ''
                Write-Warn "Python 3.8+ wasn't found. These skills need it (with openpyxl) to create .xlsx files."
            } elseif (-not (Test-Native $py @('-c', 'import openpyxl'))) {
                Write-Host ''
                Write-Warn 'The Python package openpyxl is missing. These skills use it to create .xlsx files.'
                if (-not $Yes -and (Confirm-Step "Install it now with '$py -m pip install --user openpyxl'?")) {
                    $ErrorActionPreference = 'Continue'
                    & $py -m pip install --user openpyxl
                    if ($LASTEXITCODE -ne 0) { Write-Warn 'pip failed. Install openpyxl yourself with pip.' }
                    $ErrorActionPreference = 'Stop'
                } else {
                    Write-Info "  To install it later: $py -m pip install openpyxl"
                }
            }
        }

        Write-Host ''
        Write-Host 'Next steps' -ForegroundColor White
        foreach ($a in $agents) {
            if ($a -eq 'claude') {
                Write-Host "  - Claude Code: start a new session, then type /$($selected[0]) or just describe your task."
            } else {
                Write-Host '  - GitHub Copilot: reload VS Code and use Copilot Chat in agent mode. If the skills'
                Write-Host '    do not show up, turn on the chat.useAgentSkills setting.'
            }
        }
        if ($scopeValue -eq 'project') {
            Write-Host "  - Commit the skills folder in $projectPath so your team gets them too."
        }
        if ($failed -gt 0) { throw "$failed item(s) could not be installed" }
    } finally {
        if ($tmpDir -and (Test-Path -LiteralPath $tmpDir)) {
            Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

$leapfrogExitCode = 0
try {
    Invoke-LeapfrogInstaller
} catch [OperationCanceledException] {
    Write-Host ''
    Write-Host 'Cancelled.'
    $leapfrogExitCode = 1
} catch {
    Write-Host "error: $($_.Exception.Message)" -ForegroundColor Red
    $leapfrogExitCode = 1
}
# Only exit when run as a script file; under `irm | iex` exit would close the user's shell.
if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') { exit $leapfrogExitCode }
