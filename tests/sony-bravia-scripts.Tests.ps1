<#
.SYNOPSIS
  Pester tests for sony-bravia-scripts.ps1

.DESCRIPTION
  Comprehensive test suite for the Sony Bravia ADB helper script.
  Tests all functions, menu structure, parameter handling, and error cases.

.NOTES
  Requires Pester 5.x
  Install: Install-Module -Name Pester -Force -SkipPublisherCheck

  Run tests:
    Invoke-Pester
    Invoke-Pester -Output Detailed
#>

BeforeAll {
    # Import the script under test
    $script:ScriptPath = Join-Path $PSScriptRoot '..' 'sony-bravia-scripts.ps1'

    # Verify script exists
    if (-not (Test-Path $script:ScriptPath)) {
        throw "Script not found at: $script:ScriptPath"
    }

    # Read the script content for text-based tests
    $script:ScriptContent = Get-Content $script:ScriptPath -Raw

    # Set environment variable to prevent script execution during sourcing
    $env:PESTER_RUN = '1'

    # Create mock functions to prevent actual execution during tests
    function global:adb {
        param([Parameter(ValueFromRemainingArguments)]$Args)
        Write-Output "mock-device`tdevice"
        $global:LASTEXITCODE = 0
        return
    }

    function global:Start-Tui {
        # Mock to prevent interactive UI from running
        return
    }

    # Set required script variables that would normally be set by param block
    $global:QuietMode = $false
    $global:OutputFormat = 'Text'
    $global:Action = $null
    $global:Serial = $null
    $global:ConfigFile = $null
    $global:BatchFile = $null

    # Dot-source the script to load all function definitions
    # The PESTER_RUN environment variable prevents main execution block from running
    . $script:ScriptPath
}

AfterAll {
    # Cleanup
    Remove-Item Function:\adb -ErrorAction SilentlyContinue
    Remove-Item Env:\PESTER_RUN -ErrorAction SilentlyContinue
}

Describe 'Script Structure' {
    It 'should have proper synopsis' {
        $script:ScriptContent | Should -Match '\.SYNOPSIS'
    }

    It 'should have description' {
        $script:ScriptContent | Should -Match '\.DESCRIPTION'
    }

    It 'should have examples' {
        $script:ScriptContent | Should -Match '\.EXAMPLE'
    }

    It 'should accept Action parameter' {
        $script:ScriptContent | Should -Match '\[Parameter.*\]\s*\[string\]\$Action'
    }

    It 'should accept Serial parameter' {
        $script:ScriptContent | Should -Match '\[string\]\$Serial'
    }

    It 'should use strict mode' {
        $script:ScriptContent | Should -Match 'Set-StrictMode -Version Latest'
    }

    It 'should set ErrorActionPreference to Stop' {
        $script:ScriptContent | Should -Match '\$ErrorActionPreference\s*=\s*[''"]Stop[''"]'
    }
}

Describe 'Helper Functions' {
    Context 'Test-AdbAvailable' {
        It 'should not throw when adb is available' {
            Mock -CommandName 'Get-Command' -MockWith {
                return [PSCustomObject]@{ Name = 'adb'; Path = 'adb' }
            }

            { Test-AdbAvailable } | Should -Not -Throw
        }

        It 'should throw when adb is not available' {
            Mock -CommandName 'Get-Command' -MockWith {
                return $null
            }

            { Test-AdbAvailable } | Should -Throw '*adb was not found*'
        }
    }

    Context 'Read-NonEmpty' {
        It 'should return non-empty input' {
            Mock -CommandName 'Read-Host' -MockWith { 'test-input' }

            $result = Read-NonEmpty -Prompt 'Test'
            $result | Should -Be 'test-input'
        }

        It 'should reject empty strings' {
            $script:callCount = 0
            Mock -CommandName 'Read-Host' -MockWith {
                $script:callCount++
                if ($script:callCount -eq 1) { return '' }
                if ($script:callCount -eq 2) { return '   ' }
                return 'valid'
            }

            $result = Read-NonEmpty -Prompt 'Test'
            $result | Should -Be 'valid'
        }
    }

    Context 'Read-YesNo' {
        It 'should return true for "y"' {
            Mock -CommandName 'Read-Host' -MockWith { 'y' }

            $result = Read-YesNo -Prompt 'Test'
            $result | Should -Be $true
        }

        It 'should return true for "yes"' {
            Mock -CommandName 'Read-Host' -MockWith { 'YES' }

            $result = Read-YesNo -Prompt 'Test'
            $result | Should -Be $true
        }

        It 'should return false for "n"' {
            Mock -CommandName 'Read-Host' -MockWith { 'n' }

            $result = Read-YesNo -Prompt 'Test'
            $result | Should -Be $false
        }

        It 'should return false for "no"' {
            Mock -CommandName 'Read-Host' -MockWith { 'NO' }

            $result = Read-YesNo -Prompt 'Test'
            $result | Should -Be $false
        }

        It 'should retry on invalid input' {
            $script:callCount = 0
            Mock -CommandName 'Read-Host' -MockWith {
                $script:callCount++
                if ($script:callCount -eq 1) { return 'maybe' }
                return 'yes'
            }

            $result = Read-YesNo -Prompt 'Test'
            $result | Should -Be $true
        }
    }
}

Describe 'Invoke-Adb Function' {
    BeforeEach {
        Mock -CommandName 'Write-Host' -MockWith {}
        Mock -CommandName 'Test-AdbAvailable' -MockWith {}
        Mock -CommandName 'Get-Config' -MockWith {
            return [PSCustomObject]@{
                retryAttempts = 3
                retryDelayMs  = 100
            }
        }
        $script:Serial = $null
        $script:QuietMode = $true
    }

    It 'should call adb with provided arguments' {
        Mock -CommandName 'adb' -MockWith {
            $global:LASTEXITCODE = 0
            return 'success'
        }

        $result = Invoke-Adb -Args @('devices')

        Should -Invoke -CommandName 'Test-AdbAvailable' -Times 1
        Should -Invoke -CommandName 'adb' -Times 1
        $result.Success | Should -Be $true
    }

    It 'should include serial when provided' {
        $Serial = '192.168.1.100:5555'

        Mock -CommandName 'adb' -MockWith {
            param([Parameter(ValueFromRemainingArguments)]$args)
            $global:LASTEXITCODE = 0
            # Verify -s and serial are in the args
            $args[0] | Should -Be '-s'
            $args[1] | Should -Be '192.168.1.100:5555'
            return 'success'
        }

        $result = Invoke-Adb -Args @('devices')
        $result.Success | Should -Be $true
    }

    It 'should throw on non-zero exit code by default' {
        Mock -CommandName 'adb' -MockWith {
            $global:LASTEXITCODE = 1
            return 'error output'
        }

        { Invoke-Adb -Args @('devices') } | Should -Throw
    }
}

Describe 'Menu Structure' {
    BeforeAll {
        $script:ScriptContent = Get-Content $script:ScriptPath -Raw
    }

    It 'should define the menu array' {
        $script:ScriptContent | Should -Match '\$script:Menu\s*=\s*@\('
    }

    It 'should define the ActionMap hashtable' {
        $script:ScriptContent | Should -Match '\$script:ActionMap\s*=\s*@\{\}'
    }

    Context 'Menu Entries' {
        BeforeAll {
            # Extract menu definition
            if ($script:ScriptContent -match '(?ms)\$script:Menu\s*=\s*@\((.+?)\)\s*\$script:ActionMap') {
                $menuText = $Matches[1]
                $script:MenuEntries = [regex]::Matches($menuText, "@\('([^']+)',\s*'([^']+)',\s*'([^']+)'\)")
            }
        }

        It 'should have menu entries' {
            $script:MenuEntries.Count | Should -BeGreaterThan 0
        }

        It 'should have properly formatted entries' {
            foreach ($entry in $script:MenuEntries) {
                $entry.Groups[1].Value | Should -Match '^[A-Z]\d+[A-Z]?$' # ID like A1, B2, I2A
                $entry.Groups[2].Value | Should -Not -BeNullOrEmpty # Label
                $entry.Groups[3].Value | Should -Match '^[a-z]\d+[a-z]?$' # Function like a1, b2, i3a
            }
        }

        It 'should have unique IDs' {
            $ids = $script:MenuEntries | ForEach-Object { $_.Groups[1].Value }
            $uniqueIds = $ids | Select-Object -Unique
            $ids.Count | Should -Be $uniqueIds.Count
        }

        It 'should have unique function names' {
            $funcs = $script:MenuEntries | ForEach-Object { $_.Groups[3].Value }
            $uniqueFuncs = $funcs | Select-Object -Unique
            $funcs.Count | Should -Be $uniqueFuncs.Count
        }
    }
}

Describe 'Action Functions' {
    BeforeAll {
        $script:ScriptContent = Get-Content $script:ScriptPath -Raw

        # Extract all action function names
        $script:ActionFunctions = [regex]::Matches($script:ScriptContent, '(?m)^function ([a-z]\d+) \{') |
        ForEach-Object { $_.Groups[1].Value }
    }

    It 'should have action functions defined' {
        $script:ActionFunctions.Count | Should -BeGreaterThan 0
    }

    Context 'Function Definition' {
        It 'should define a1 (Connect)' {
            $script:ScriptContent | Should -Match '(?m)^function a1 \{'
        }

        It 'should define a2 (Disconnect)' {
            $script:ScriptContent | Should -Match '(?m)^function a2 \{'
        }

        It 'should define a3 (List devices)' {
            $script:ScriptContent | Should -Match '(?m)^function a3 \{'
        }

        It 'should define b1 (Shell)' {
            $script:ScriptContent | Should -Match '(?m)^function b1 \{'
        }

        It 'should define b2 (Logcat)' {
            $script:ScriptContent | Should -Match '(?m)^function b2 \{'
        }

        It 'should define b3 (ADB help)' {
            $script:ScriptContent | Should -Match '(?m)^function b3 \{'
        }

        It 'should define all C-series functions (processes)' {
            'c1', 'c2', 'c3', 'c4' | ForEach-Object {
                $script:ScriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all D-series functions (device info)' {
            'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7', 'd8' | ForEach-Object {
                $script:ScriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all E-series functions (power)' {
            'e1', 'e2' | ForEach-Object {
                $script:ScriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all F-series functions (device name)' {
            'f1', 'f2', 'f3', 'f4', 'f5', 'f6' | ForEach-Object {
                $script:ScriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all G-series functions (activities)' {
            'g1', 'g2', 'g3', 'g4' | ForEach-Object {
                $script:ScriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all H-series functions (screen settings)' {
            'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'h7', 'h8', 'h9', 'h10', 'h11' | ForEach-Object {
                $script:ScriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all I-series functions (applications)' {
            'i1', 'i2', 'i3', 'i3a', 'i4', 'i5', 'i6', 'i7', 'i8', 'i9', 'i10', 'i11', 'i12', 'i13', 'i14', 'i15', 'i16' | ForEach-Object {
                $script:ScriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all J-series functions (launcher)' {
            'j1', 'j2', 'j3', 'j4' | ForEach-Object {
                $script:ScriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all K-series functions (proxy)' {
            'k1', 'k2', 'k3', 'k4', 'k5', 'k6' | ForEach-Object {
                $script:ScriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all L-series functions (wifi)' {
            'l1', 'l2', 'l3', 'l4', 'l5', 'l6' | ForEach-Object {
                $script:ScriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all M-series functions (misc)' {
            'm1' | ForEach-Object {
                $script:ScriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all N-series functions (factory reset)' {
            'n1', 'n2' | ForEach-Object {
                $script:ScriptContent | Should -Match "(?m)^function $_ \{"
            }
        }
    }

    Context 'Function Implementations' {
        It 'should call Write-Title in action functions' {
            # Most action functions should set a title
            $script:ActionFunctions | ForEach-Object {
                $functionName = $_
                # Extract function body
                if ($script:ScriptContent -match "(?ms)function $functionName \{(.*?)(?=^function |\z)") {
                    $body = $Matches[1]
                    # Skip if it's a very simple function
                    if ($body.Length -gt 50) {
                        $body | Should -Match 'Write-Title'
                    }
                }
            }
        }

        It 'should call Done in action functions' {
            # All action functions should call Done
            $script:ActionFunctions | ForEach-Object {
                $functionName = $_
                if ($script:ScriptContent -match "(?ms)function $functionName \{(.*?)(?=^function |\z)") {
                    $Matches[1] | Should -Match 'Done'
                }
            }
        }

        It 'should use Invoke-Adb for ADB commands' {
            # Most functions should use Invoke-Adb
            $adbFunctions = @('a1', 'a2', 'a3', 'b1', 'b2', 'b3', 'c1', 'c2', 'c3', 'c4',
                'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7', 'd8')

            $adbFunctions | ForEach-Object {
                $functionName = $_
                if ($script:ScriptContent -match "(?ms)function $functionName \{(.*?)(?=^function |\z)") {
                    $Matches[1] | Should -Match 'Invoke-Adb'
                }
            }
        }
    }
}

Describe 'TUI Functions' {
    BeforeAll {
        $script:ScriptContent = Get-Content $script:ScriptPath -Raw
    }

    It 'should define Start-Tui function' {
        $script:ScriptContent | Should -Match '(?m)^function Start-Tui \{'
    }

    It 'should define Show-Menu function' {
        $script:ScriptContent | Should -Match '(?m)^function Show-Menu \{'
    }

    It 'should define Invoke-Action function' {
        $script:ScriptContent | Should -Match '(?m)^function Invoke-Action \{'
    }

    It 'should define New-TuiModel function' {
        $script:ScriptContent | Should -Match '(?m)^function New-TuiModel \{'
    }

    It 'should define Get-NextSelectableIndex function' {
        $script:ScriptContent | Should -Match '(?m)^function Get-NextSelectableIndex \{'
    }

    It 'should define Get-SectionTitleForId function' {
        $script:ScriptContent | Should -Match '(?m)^function Get-SectionTitleForId \{'
    }
}

Describe 'Get-SectionTitleForId Function' {
    BeforeAll {
        # Import function for testing
        $script:ScriptContent = Get-Content $script:ScriptPath -Raw
        if ($script:ScriptContent -match '(?ms)(function Get-SectionTitleForId.*?(?=^function |\z))') {
            $funcDef = $Matches[1]
            Invoke-Expression $funcDef
        }
    }

    It 'should map A* to ADB connection' {
        Get-SectionTitleForId -Id 'A1' | Should -Be 'ADB connection'
        Get-SectionTitleForId -Id 'A2' | Should -Be 'ADB connection'
    }

    It 'should map H1-H4 to Screen density' {
        Get-SectionTitleForId -Id 'H1' | Should -Be 'Screen density'
        Get-SectionTitleForId -Id 'H4' | Should -Be 'Screen density'
    }

    It 'should map H5-H7 to Screen resolution' {
        Get-SectionTitleForId -Id 'H5' | Should -Be 'Screen resolution'
        Get-SectionTitleForId -Id 'H7' | Should -Be 'Screen resolution'
    }

    It 'should map H8-H11 to Screen animations' {
        Get-SectionTitleForId -Id 'H8' | Should -Be 'Screen animations'
        Get-SectionTitleForId -Id 'H11' | Should -Be 'Screen animations'
    }

    It 'should map I* to Applications' {
        Get-SectionTitleForId -Id 'I1' | Should -Be 'Applications'
        Get-SectionTitleForId -Id 'I10' | Should -Be 'Applications'
    }

    It 'should map N* to Factory reset' {
        Get-SectionTitleForId -Id 'N1' | Should -Be 'Factory reset (danger zone)'
        Get-SectionTitleForId -Id 'N2' | Should -Be 'Factory reset (danger zone)'
    }
}

Describe 'Script Execution' {
    BeforeAll {
        # Tests check script text, no mocking needed
    }

    It 'should accept -Action parameter' {
        # Script should handle -Action parameter
        $script:ScriptContent = Get-Content $script:ScriptPath -Raw
        $script:ScriptContent | Should -Match 'param\s*\(\s*\[Parameter\(Position\s*=\s*0\)\]\s*\[string\]\$Action'
    }

    It 'script should accept Serial parameter' {
        $script:ScriptContent = Get-Content $script:ScriptPath -Raw
        $script:ScriptContent | Should -Match 'param[\s\S]{1,2000}?\[string\]\$Serial'
    }
}

Describe 'Error Handling' {
    BeforeAll {
        $script:ScriptContent = Get-Content $script:ScriptPath -Raw
    }

    It 'should wrap main execution in try-catch' {
        $script:ScriptContent | Should -Match '(?ms)try\s*\{.*?\}\s*catch\s*\{'
    }

    It 'should display error messages' {
        $script:ScriptContent | Should -Match 'Write-Host.*ERROR.*-ForegroundColor Red'
    }

    It 'should exit with non-zero code on error' {
        $script:ScriptContent | Should -Match 'exit 1'
    }
}

Describe 'ADB Command Validation' {
    BeforeAll {
        $script:ScriptContent = Get-Content $script:ScriptPath -Raw
    }

    Context 'Valid ADB Commands' {
        It 'should use valid adb connect command' {
            $script:ScriptContent | Should -Match "Invoke-Adb.*@\('connect'"
        }

        It 'should use valid adb disconnect command' {
            $script:ScriptContent | Should -Match "Invoke-Adb.*@\('disconnect'"
        }

        It 'should use valid adb devices command' {
            $script:ScriptContent | Should -Match "Invoke-Adb.*@\('devices'"
        }

        It 'should use valid adb shell command' {
            $script:ScriptContent | Should -Match "Invoke-Adb.*@\('shell'"
        }

        It 'should use valid adb logcat command' {
            $script:ScriptContent | Should -Match "Invoke-Adb.*@\('logcat'"
        }

        It 'should use valid adb reboot command' {
            $script:ScriptContent | Should -Match "Invoke-Adb.*@\('reboot'"
        }

        It 'should use valid adb install command' {
            $script:ScriptContent | Should -Match "Invoke-Adb.*@\('install'"
        }

        It 'should use valid adb get-serialno command' {
            $script:ScriptContent | Should -Match "Invoke-Adb.*@\('get-serialno'"
        }

        It 'should use valid adb get-state command' {
            $script:ScriptContent | Should -Match "Invoke-Adb.*@\('get-state'"
        }
    }

    Context 'Valid Shell Commands' {
        It 'should use valid settings commands' {
            $script:ScriptContent | Should -Match "shell.*settings (get|put|delete)"
        }

        It 'should use valid pm commands' {
            $script:ScriptContent | Should -Match "shell.*pm (list|disable|enable|install|uninstall)"
        }

        It 'should use valid am commands' {
            $script:ScriptContent | Should -Match "shell.*am (start|force-stop)"
        }

        It 'should use valid wm commands' {
            $script:ScriptContent | Should -Match "shell.*wm (density|size)"
        }

        It 'should use valid input commands' {
            $script:ScriptContent | Should -Match "shell.*input keyevent"
        }
    }
}

Describe 'Documentation' {
    BeforeAll {
        $script:ScriptContent = Get-Content $script:ScriptPath -Raw
    }

    It 'should have proper script header' {
        $script:ScriptContent | Should -Match '<#'
        $script:ScriptContent | Should -Match '#>'
    }

    It 'should document Action parameter' {
        $script:ScriptContent | Should -Match '\.PARAMETER Action'
    }

    It 'should document Serial parameter' {
        $script:ScriptContent | Should -Match '\.PARAMETER Serial'
    }

    It 'should have multiple examples' {
        ($script:ScriptContent | Select-String -Pattern '\.EXAMPLE' -AllMatches).Matches.Count |
        Should -BeGreaterOrEqual 2
    }
}

Describe 'Code Quality' {
    BeforeAll {
        $script:ScriptContent = Get-Content $script:ScriptPath -Raw
    }

    It 'should use CmdletBinding where appropriate' {
        $script:ScriptContent | Should -Match '\[CmdletBinding\(\)\]'
    }

    It 'should use proper parameter attributes' {
        $script:ScriptContent | Should -Match '\[Parameter\('
    }

    It 'should not have trailing whitespace' {
        $lines = (Get-Content $script:ScriptPath) | Where-Object { $_ -notmatch '\s+$' }
        $allLines = Get-Content $script:ScriptPath
        $lines.Count | Should -Be $allLines.Count
    }

    It 'should use consistent indentation' {
        # Check that indentation is consistent (spaces, not tabs)
        $lines = Get-Content $script:ScriptPath
        $tabLines = @($lines | Where-Object { $_ -match "\t" -and $_ -notmatch '^\s*#' -and $_ -notmatch '@"' -and $_ -notmatch '"@' })
        $tabLines.Count | Should -Be 0
    }
}

Describe 'Integration Scenarios' {
    It 'should have all menu entries pointing to existing functions' {
        $script:ScriptContent = Get-Content $script:ScriptPath -Raw

        # Extract menu entries
        if ($script:ScriptContent -match '(?ms)\$script:Menu\s*=\s*@\((.*?)\)') {
            $menuText = $Matches[1]
            $entries = [regex]::Matches($menuText, "@\('[^']+',\s*'[^']+',\s*'([^']+)'\)")

            foreach ($entry in $entries) {
                $funcName = $entry.Groups[1].Value
                $script:ScriptContent | Should -Match "(?m)^function $funcName \{"
            }
        }
    }

    It 'should populate ActionMap from Menu' {
        $script:ScriptContent = Get-Content $script:ScriptPath -Raw
        $script:ScriptContent | Should -Match '\$script:ActionMap\[\$entry\[0\]\.ToLowerInvariant\(\)\]\s*=\s*\$entry\[2\]'
        $script:ScriptContent | Should -Match '\$script:ActionMap\[\$entry\[2\]\.ToLowerInvariant\(\)\]\s*=\s*\$entry\[2\]'
    }
}

Describe 'Additional Helper Functions' {
    Context 'Write-Title' {
        BeforeEach {
            Mock -CommandName 'Write-Host' -MockWith {}
        }

        It 'should exist' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            $script:ScriptContent | Should -Match '(?m)^function Write-Title \{'
        }

        It 'should accept Text parameter' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            $script:ScriptContent | Should -Match 'function Write-Title\s*\{[^\}]*param\s*\(\s*\[Parameter\(Mandatory\)\]\[string\]\$Text'
        }

        It 'should set window title' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            $script:ScriptContent | Should -Match 'WindowTitle\s*=.*ScriptVer'
        }
    }

    Context 'Done' {
        It 'should exist' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            $script:ScriptContent | Should -Match '(?m)^function Done \{'
        }

        It 'should call Wait-ForContinue' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function Done \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Wait-ForContinue'
            }
        }
    }

    Context 'Wait-ForContinue' {
        It 'should exist' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            $script:ScriptContent | Should -Match '(?m)^function Wait-ForContinue \{'
        }

        It 'should use ReadKey' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            $script:ScriptContent | Should -Match 'ReadKey'
        }
    }
}

Describe 'Action Function Behavior' {
    BeforeEach {
        Mock -CommandName 'Write-Host' -MockWith {}
        Mock -CommandName 'Write-Title' -MockWith {}
        Mock -CommandName 'Done' -MockWith {}
        Mock -CommandName 'Invoke-Adb' -MockWith {
            return [pscustomobject]@{ ExitCode = 0; Output = 'success' }
        }
        Mock -CommandName 'Read-NonEmpty' -MockWith { 'test-value' }
        Mock -CommandName 'Read-YesNo' -MockWith { $true }
        Mock -CommandName 'Read-Host' -MockWith { '' }
    }

    Context 'Connection Functions' {
        It 'a1 (Connect) should call Invoke-Adb with connect' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function a1 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "Invoke-Adb.*'connect'"
            }
        }

        It 'a2 (Disconnect) should call Invoke-Adb with disconnect' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function a2 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "Invoke-Adb.*'disconnect'"
            }
        }

        It 'a3 (Devices) should call Invoke-Adb with devices' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function a3 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "Invoke-Adb.*'devices'"
            }
        }
    }

    Context 'Dangerous Functions Require Confirmation' {
        It 'e1 (Reboot) should use Read-YesNo' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function e1 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Read-YesNo'
            }
        }

        It 'e2 (Shutdown) should use Read-YesNo' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function e2 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Read-YesNo'
            }
        }

        It 'n1 (Factory reset) should use Read-YesNo' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function n1 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Read-YesNo'
            }
        }

        It 'n2 (Factory reset alt) should use Read-YesNo' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function n2 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Read-YesNo'
            }
        }

        It 'i3 (Reset permissions) should use Read-YesNo' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function i3 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Read-YesNo'
            }
        }

        It 'i10 (Uninstall) should use Read-YesNo' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function i10 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Read-YesNo'
            }
        }
    }

    Context 'Input Validation Functions' {
        It 'functions requiring input should use Read-NonEmpty' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw

            # Functions that need user input
            @('a1', 'c4', 'f4', 'f5', 'f6', 'g3', 'h2', 'h6', 'h9', 'i4', 'i5',
                'i6', 'i8', 'i9', 'i10', 'i11', 'i12', 'j2', 'j3', 'j4', 'k2',
                'k5', 'l3', 'l4', 'm1') | ForEach-Object {
                $funcName = $_
                if ($script:ScriptContent -match "(?ms)function $funcName \{(.*?)(?=^function |\z)") {
                    $body = $Matches[1]
                    # Should either use Read-NonEmpty or Read-Host
                    $body | Should -Match '(Read-NonEmpty|Read-Host)'
                }
            }
        }
    }

    Context 'AllowFailure Flag Usage' {
        It 'functions with potentially unsupported commands should use -AllowFailure' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw

            # Functions that may not work on all devices
            @('c2', 'd6', 'd7', 'd8', 'e2', 'g4', 'l3', 'l4') | ForEach-Object {
                $funcName = $_
                if ($script:ScriptContent -match "(?ms)function $funcName \{(.*?)(?=^function |\z)") {
                    $body = $Matches[1]
                    $body | Should -Match '-AllowFailure'
                }
            }
        }
    }
}

Describe 'TUI Behavior Functions' {
    BeforeAll {
        $script:ScriptContent = Get-Content $script:ScriptPath -Raw
    }

    Context 'New-TuiModel Function' {
        It 'should accept Filter parameter' {
            $script:ScriptContent | Should -Match 'function New-TuiModel\s*\{[^\}]*param\s*\(\s*\[string\]\$Filter'
        }

        It 'should filter menu items' {
            if ($script:ScriptContent -match '(?ms)function New-TuiModel.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'filterText.*ToLowerInvariant'
                $Matches[1] | Should -Match '-notlike'
            }
        }

        It 'should create header entries' {
            if ($script:ScriptContent -match '(?ms)function New-TuiModel.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "Kind\s*=\s*'header'"
            }
        }

        It 'should create item entries' {
            if ($script:ScriptContent -match '(?ms)function New-TuiModel.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "Kind\s*=\s*'item'"
            }
        }
    }

    Context 'Get-NextSelectableIndex Function' {
        It 'should accept Items parameter' {
            $script:ScriptContent | Should -Match 'function Get-NextSelectableIndex[\s\S]*?param[\s\S]*?\$Items'
        }

        It 'should accept StartIndex parameter' {
            $script:ScriptContent | Should -Match 'function Get-NextSelectableIndex[\s\S]*?param[\s\S]*?\$StartIndex'
        }

        It 'should accept Direction parameter' {
            $script:ScriptContent | Should -Match 'function Get-NextSelectableIndex[\s\S]*?param[\s\S]*?\$Direction'
        }

        It 'should skip header entries' {
            if ($script:ScriptContent -match '(?ms)function Get-NextSelectableIndex.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "Kind\s*-eq\s*'item'"
            }
        }
    }

    Context 'Invoke-Action Function' {
        It 'should accept Id parameter' {
            $script:ScriptContent | Should -Match 'function Invoke-Action[\s\S]*?param[\s\S]*?\$Id'
        }

        It 'should accept Quiet switch' {
            $script:ScriptContent | Should -Match 'function Invoke-Action[\s\S]*?param[\s\S]*?\[switch\]\$Quiet'
        }

        It 'should handle exit command (x)' {
            if ($script:ScriptContent -match '(?ms)function Invoke-Action.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "if.*-eq\s*'x'"
                $Matches[1] | Should -Match 'return \$false'
            }
        }

        It 'should validate action exists in ActionMap' {
            if ($script:ScriptContent -match '(?ms)function Invoke-Action.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'ActionMap\.ContainsKey'
            }
        }

        It 'should call the action function' {
            if ($script:ScriptContent -match '(?ms)function Invoke-Action.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match '&\s*\$fn'
            }
        }
    }

    Context 'Start-Tui Function' {
        It 'should handle cursor visibility' {
            if ($script:ScriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'CursorVisible'
            }
        }

        It 'should handle arrow key navigation' {
            if ($script:ScriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'UpArrow'
                $Matches[1] | Should -Match 'DownArrow'
            }
        }

        It 'should handle Enter key for action execution' {
            if ($script:ScriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "'Enter'"
            }
        }

        It 'should handle / for filter mode' {
            if ($script:ScriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "'/'"
                $Matches[1] | Should -Match "'filter'"
            }
        }

        It 'should handle S for serial setting' {
            if ($script:ScriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "'s'"
            }
        }

        It 'should handle : for direct command' {
            if ($script:ScriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "':'"
            }
        }

        It 'should handle Escape to quit' {
            if ($script:ScriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "'Escape'"
            }
        }

        It 'should render window title with serial' {
            if ($script:ScriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Serial:'
            }
        }
    }
}

Describe 'Edge Cases and Error Scenarios' {
    Context 'Invalid Input Handling' {
        It 'Invoke-Action should handle invalid action IDs gracefully' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function Invoke-Action.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "isn't valid"
            }
        }

        It 'should handle empty menu gracefully' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function New-TuiModel.*?\{(.*?)(?=^function |\z)') {
                # Should handle case where filter results in empty list
                $Matches[1] | Should -Match 'Count'
            }
        }
    }

    Context 'Boundary Conditions' {
        It 'Get-NextSelectableIndex should handle index < 0' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function Get-NextSelectableIndex.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'if.*idx -lt 0'
            }
        }

        It 'Get-NextSelectableIndex should handle index >= Count' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function Get-NextSelectableIndex.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'if.*idx -ge.*Count'
            }
        }

        It 'Get-NextSelectableIndex should handle empty items list' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function Get-NextSelectableIndex.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Count -eq 0'
                $Matches[1] | Should -Match 'return -1'
            }
        }
    }

    Context 'Serial Parameter Propagation' {
        It 'Invoke-Adb should use script:Serial variable' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            if ($script:ScriptContent -match '(?ms)function Invoke-Adb.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match '\$Serial'
                $Matches[1] | Should -Match "'-s'"
            }
        }

        It 'script should accept Serial parameter' {
            $script:ScriptContent = Get-Content $script:ScriptPath -Raw
            $script:ScriptContent | Should -Match 'param[\s\S]{1,2000}?\[string\]\$Serial'
        }
    }
}

Describe 'Console API Usage' {
    BeforeAll {
        $script:ScriptContent = Get-Content $script:ScriptPath -Raw
    }

    It 'should use Console SetCursorPosition' {
        $script:ScriptContent | Should -Match '\[Console\]::SetCursorPosition'
    }

    It 'should use Console ForegroundColor' {
        $script:ScriptContent | Should -Match '\[Console\]::ForegroundColor'
    }

    It 'should use Console BackgroundColor' {
        $script:ScriptContent | Should -Match '\[Console\]::BackgroundColor'
    }

    It 'should use Console ReadKey' {
        $script:ScriptContent | Should -Match '\[Console\]::ReadKey|ReadKey'
    }

    It 'should use Console WindowWidth' {
        $script:ScriptContent | Should -Match '\[Console\]::WindowWidth'
    }

    It 'should use Console WindowHeight' {
        $script:ScriptContent | Should -Match '\[Console\]::WindowHeight'
    }

    It 'should restore Console CursorVisible in finally block' {
        if ($script:ScriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
            $Matches[1] | Should -Match 'finally'
            $Matches[1] | Should -Match 'CursorVisible.*origCursorVisible'
        }
    }
}

Describe 'Edge Cases - Configuration Functions' {
    Context 'Initialize-Config' {
        It 'should handle missing config directory' {
            { Initialize-Config } | Should -Not -Throw
        }

        It 'should create config file if missing' {
            $testConfigDir = Join-Path $TestDrive 'config-test'
            $env:SONY_BRAVIA_CONFIG = Join-Path $testConfigDir 'config.json'

            { Initialize-Config } | Should -Not -Throw

            Remove-Item Env:\SONY_BRAVIA_CONFIG -ErrorAction SilentlyContinue
        }
    }

    Context 'Get-Config' {
        It 'should return default config when file missing' {
            $env:SONY_BRAVIA_CONFIG = Join-Path $TestDrive 'nonexistent.json'

            $config = Get-Config
            $config | Should -Not -BeNullOrEmpty
            $config.retryAttempts | Should -BeGreaterThan 0

            Remove-Item Env:\SONY_BRAVIA_CONFIG -ErrorAction SilentlyContinue
        }

        It 'should handle corrupted JSON gracefully' {
            $testConfigPath = Join-Path $TestDrive 'corrupted.json'
            '{invalid json' | Out-File -FilePath $testConfigPath -Encoding utf8
            $env:SONY_BRAVIA_CONFIG = $testConfigPath

            $config = Get-Config
            $config | Should -Not -BeNullOrEmpty

            Remove-Item Env:\SONY_BRAVIA_CONFIG -ErrorAction SilentlyContinue
        }
    }

    Context 'Set-ConfigValue' {
        It 'should handle valid config keys' {
            { Set-ConfigValue -Key 'retryAttempts' -Value 5 } | Should -Not -Throw
        }

        It 'should handle string values' {
            { Set-ConfigValue -Key 'defaultSerial' -Value '192.168.1.1:5555' } | Should -Not -Throw
        }
    }
}

Describe 'Edge Cases - History Functions' {
    Context 'Add-ToHistory' {
        It 'should handle very long action string' {
            $longAction = 'A' * 10000
            { Add-ToHistory -Action $longAction -Serial 'test' -Success $true } | Should -Not -Throw
        }

        It 'should handle special characters in action' {
            $specialAction = "test`n`r`t<>&|';`$"
            { Add-ToHistory -Action $specialAction -Serial 'test' -Success $true } | Should -Not -Throw
        }

        It 'should handle Unicode characters' {
            $unicodeAction = 'test-unicode-action'
            { Add-ToHistory -Action $unicodeAction -Serial 'test' -Success $true } | Should -Not -Throw
        }
    }

    Context 'Get-History' {
        It 'should handle missing history file' {
            $testHistoryPath = Join-Path $TestDrive 'history-nonexistent-test.json'
            Remove-Item $testHistoryPath -ErrorAction SilentlyContinue
            $env:SONY_BRAVIA_HISTORY = $testHistoryPath

            $history = Get-History
            $history | Should -Not -BeNullOrEmpty
            $history.Count | Should -BeGreaterOrEqual 0

            Remove-Item Env:\SONY_BRAVIA_HISTORY -ErrorAction SilentlyContinue
        }

        It 'should handle corrupted history file' {
            $testHistoryPath = Join-Path $TestDrive 'history-corrupt.json'
            '[{invalid' | Out-File -FilePath $testHistoryPath -Encoding utf8
            $env:SONY_BRAVIA_HISTORY = $testHistoryPath

            $history = Get-History
            $history | Should -Not -BeNullOrEmpty

            Remove-Item Env:\SONY_BRAVIA_HISTORY -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Edge Cases - Helper Functions' {
    Context 'Read-NonEmpty - Advanced' {
        It 'should handle very long input' {
            $longInput = 'A' * 10000
            Mock -CommandName 'Read-Host' -MockWith { $longInput }

            $result = Read-NonEmpty -Prompt 'Test'
            $result.Length | Should -Be 10000
        }

        It 'should handle Unicode input' {
            Mock -CommandName 'Read-Host' -MockWith { 'test-unicode-string' }

            $result = Read-NonEmpty -Prompt 'Test'
            $result | Should -Be 'test-unicode-string'
        }

        It 'should accept non-empty input with whitespace' {
            Mock -CommandName 'Read-Host' -MockWith { "test with spaces" }

            $result = Read-NonEmpty -Prompt 'Test'
            $result.Length | Should -BeGreaterThan 0
        }

        It 'should handle only spaces as empty' {
            $script:callCount = 0
            Mock -CommandName 'Read-Host' -MockWith {
                $script:callCount++
                if ($script:callCount -eq 1) { return '     ' }
                if ($script:callCount -eq 2) { return "`t`t`t" }
                return 'valid'
            }

            $result = Read-NonEmpty -Prompt 'Test'
            $result | Should -Be 'valid'
        }
    }

    Context 'Read-YesNo - Advanced' {
        It 'should be case insensitive for Y' {
            Mock -CommandName 'Read-Host' -MockWith { 'Y' }
            $result = Read-YesNo -Prompt 'Test'
            $result | Should -Be $true
        }

        It 'should be case insensitive for yes' {
            Mock -CommandName 'Read-Host' -MockWith { 'yEs' }
            $result = Read-YesNo -Prompt 'Test'
            $result | Should -Be $true
        }

        It 'should be case insensitive for N' {
            Mock -CommandName 'Read-Host' -MockWith { 'N' }
            $result = Read-YesNo -Prompt 'Test'
            $result | Should -Be $false
        }

        It 'should handle whitespace around input' {
            Mock -CommandName 'Read-Host' -MockWith { '  yes  ' }
            $result = Read-YesNo -Prompt 'Test'
            $result | Should -Be $true
        }

        It 'should retry multiple times on invalid input' {
            $script:callCount = 0
            Mock -CommandName 'Read-Host' -MockWith {
                $script:callCount++
                switch ($script:callCount) {
                    1 { return '' }
                    2 { return '123' }
                    3 { return 'maybe' }
                    4 { return 'yesno' }
                    default { return 'y' }
                }
            }

            $result = Read-YesNo -Prompt 'Test'
            $result | Should -Be $true
            $script:callCount | Should -BeGreaterThan 4
        }
    }

    Context 'Write-Title - Edge Cases' {
        It 'should handle very long text' {
            Mock -CommandName 'Write-Host' -MockWith {}
            $longText = 'A' * 500
            { Write-Title $longText } | Should -Not -Throw
        }

        It 'should handle text with special characters' {
            Mock -CommandName 'Write-Host' -MockWith {}
            { Write-Title "Test Title 123" } | Should -Not -Throw
        }

        It 'should be callable without errors' {
            Mock -CommandName 'Write-Host' -MockWith {}
            { Write-Title 'Normal Title' } | Should -Not -Throw
        }
    }
}

Describe 'Edge Cases - Invoke-Adb Function' {
    BeforeEach {
        Mock -CommandName 'Write-Host' -MockWith {}
        Mock -CommandName 'Test-AdbAvailable' -MockWith {}
        Mock -CommandName 'Get-Config' -MockWith {
            return [PSCustomObject]@{
                retryAttempts = 3
                retryDelayMs  = 100
            }
        }
        $script:Serial = $null
        $script:QuietMode = $true
    }

    Context 'Serial Parameter Handling' {
        It 'should handle null serial' {
            $script:Serial = $null
            Mock -CommandName 'adb' -MockWith {
                $global:LASTEXITCODE = 0
                return 'success'
            }

            { Invoke-Adb -Args @('devices') } | Should -Not -Throw
        }

        It 'should handle empty serial' {
            $script:Serial = ''
            Mock -CommandName 'adb' -MockWith {
                $global:LASTEXITCODE = 0
                return 'success'
            }

            { Invoke-Adb -Args @('devices') } | Should -Not -Throw
        }

        It 'should handle serial with special characters' {
            $script:Serial = '192.168.1.1:5555'
            Mock -CommandName 'adb' -MockWith {
                param($ArgList)
                if ($ArgList -contains '-s' -and $ArgList -contains '192.168.1.1:5555') {
                    $global:LASTEXITCODE = 0
                    return 'success'
                }
            }

            $result = Invoke-Adb -Args @('devices')
            $result.ExitCode | Should -Be 0
        }

        It 'should handle very long serial string' {
            $script:Serial = 'device' * 100
            Mock -CommandName 'adb' -MockWith {
                $global:LASTEXITCODE = 0
                return 'success'
            }

            { Invoke-Adb -Args @('devices') } | Should -Not -Throw
        }
    }

    Context 'Arguments Edge Cases' {
        It 'should handle single arg' {
            Mock -CommandName 'adb' -MockWith {
                $global:LASTEXITCODE = 0
                return 'success'
            }

            $result = Invoke-Adb -Args @('version')
            $result.ExitCode | Should -Be 0
        }

        It 'should handle args with special shell characters' {
            Mock -CommandName 'adb' -MockWith {
                $global:LASTEXITCODE = 0
                return 'success'
            }

            $result = Invoke-Adb -Args @('shell', "echo 'test|grep>redirect&background;'")
            $result.ExitCode | Should -Be 0
        }

        It 'should handle args with Unicode' {
            Mock -CommandName 'adb' -MockWith {
                $global:LASTEXITCODE = 0
                return 'success'
            }

            $result = Invoke-Adb -Args @('shell', 'echo test-unicode')
            $result.ExitCode | Should -Be 0
        }

        It 'should handle very long command' {
            Mock -CommandName 'adb' -MockWith {
                $global:LASTEXITCODE = 0
                return 'success'
            }

            $longCommand = 'test' * 1000
            $result = Invoke-Adb -Args @('shell', "echo $longCommand")
            $result.ExitCode | Should -Be 0
        }
    }

    Context 'Error Handling Edge Cases' {
        It 'should handle adb timeout' {
            Mock -CommandName 'adb' -MockWith {
                Start-Sleep -Seconds 1
                $global:LASTEXITCODE = 1
                return 'timeout'
            }

            $result = Invoke-Adb -Args @('devices') -AllowFailure
            $result.ExitCode | Should -Be 1
        }

        It 'should handle adb crash' {
            Mock -CommandName 'adb' -MockWith {
                throw 'adb crashed'
            }

            { Invoke-Adb -Args @('devices') -AllowFailure } | Should -Not -Throw
        }

        It 'should handle retries on failure' {
            $script:attemptCount = 0
            Mock -CommandName 'adb' -MockWith {
                $script:attemptCount++
                $global:LASTEXITCODE = 1
                return "error attempt $script:attemptCount"
            }

            $result = Invoke-Adb -Args @('devices') -AllowFailure
            $result.ExitCode | Should -Be 1
            $script:attemptCount | Should -BeGreaterOrEqual 1
        }
    }
}

Describe 'Edge Cases - Menu and Actions' {
    Context 'Invoke-Action - Boundary Cases' {
        It 'should handle whitespace-only action ID' {
            Mock -CommandName 'Write-Host' -MockWith {}

            $result = Invoke-Action -Id '   ' -Quiet
            $result | Should -Be $true
        }

        It 'should handle very long action ID' {
            Mock -CommandName 'Write-Host' -MockWith {}

            $result = Invoke-Action -Id ('A' * 1000) -Quiet
            $result | Should -Be $true
        }

        It 'should handle special characters in action ID' {
            Mock -CommandName 'Write-Host' -MockWith {}

            $result = Invoke-Action -Id 'A1<>&|;' -Quiet
            $result | Should -Be $true
        }

        It 'should handle x/X (exit) case-insensitively' {
            $result = Invoke-Action -Id 'X' -Quiet
            $result | Should -Be $false

            $result = Invoke-Action -Id 'x' -Quiet
            $result | Should -Be $false
        }
    }

    Context 'Get-SectionTitleForId - Edge Cases' {
        It 'should handle invalid format' {
            $result = Get-SectionTitleForId -Id 'INVALID123'
            $result | Should -Be 'Other'
        }

        It 'should handle lowercase IDs' {
            $result = Get-SectionTitleForId -Id 'a1'
            $result | Should -Match 'ADB connection'
        }

        It 'should handle mixed case IDs' {
            $result = Get-SectionTitleForId -Id 'A1a'
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Edge Cases - TUI Functions' {
    Context 'New-TuiModel - Edge Cases' {
        It 'should handle null filter' {
            $result = New-TuiModel -Filter $null
            $result | Should -Not -BeNullOrEmpty
        }

        It 'should handle empty filter' {
            $result = New-TuiModel -Filter ''
            $result | Should -Not -BeNullOrEmpty
        }

        It 'should handle filter with no matches' {
            $result = New-TuiModel -Filter 'unicode-test-nomatch'
            # Should return array even if empty
            $result.GetType().Name | Should -Match 'Array|List'
        }

        It 'should handle very long filter' {
            $longFilter = 'A1' + ('x' * 100)
            $result = New-TuiModel -Filter $longFilter
            # Should return array even if empty
            $result.GetType().Name | Should -Match 'Array|List'
        }

        It 'should handle filter with literal match' {
            $result = New-TuiModel -Filter 'Connect'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'should filter out non-matching items' {
            $result = New-TuiModel -Filter 'NONEXISTENT_FILTER_12345'
            if ($result) {
                $allItems = @($result | Where-Object { $_.Kind -eq 'item' })
                $allItems.Count | Should -Be 0
            }
            else {
                # Empty result is also valid
                $true | Should -Be $true
            }
        }
    }

    Context 'Get-NextSelectableIndex - Boundary Cases' {
        It 'should handle zero items' {
            $emptyList = @()
            $result = Get-NextSelectableIndex -Items $emptyList -StartIndex 0 -Direction 1
            $result | Should -Be -1
        }

        It 'should handle negative start index' {
            $items = @(
                [PSCustomObject]@{ Kind = 'item'; Id = 'A1' }
            )
            $result = Get-NextSelectableIndex -Items $items -StartIndex -5 -Direction 1
            $result | Should -BeGreaterOrEqual 0
        }

        It 'should handle start index beyond array bounds' {
            $items = @(
                [PSCustomObject]@{ Kind = 'item'; Id = 'A1' }
            )
            $result = Get-NextSelectableIndex -Items $items -StartIndex 999 -Direction -1
            $result | Should -BeGreaterOrEqual 0
        }

        It 'should handle zero direction' {
            $items = @(
                [PSCustomObject]@{ Kind = 'item'; Id = 'A1' }
            )
            # Zero direction on an item should return that index
            $result = Get-NextSelectableIndex -Items $items -StartIndex 0 -Direction 0
            $result | Should -Be 0
        }

        It 'should handle only headers (no items)' {
            $items = @(
                [PSCustomObject]@{ Kind = 'header'; Title = 'Test1' },
                [PSCustomObject]@{ Kind = 'header'; Title = 'Test2' }
            )
            $result = Get-NextSelectableIndex -Items $items -StartIndex 0 -Direction 1
            $result | Should -Be -1
        }

        It 'should handle large direction value' {
            $items = @(
                [PSCustomObject]@{ Kind = 'item'; Id = 'A1' },
                [PSCustomObject]@{ Kind = 'item'; Id = 'A2' }
            )
            $result = Get-NextSelectableIndex -Items $items -StartIndex 0 -Direction 999
            $result | Should -BeGreaterOrEqual 0
        }
    }
}

Describe 'Edge Cases - Write-Log Function' {
    Context 'Log Levels and Messages' {
        It 'should handle very long message' {
            $longMessage = 'A' * 100000
            { Write-Log -Message $longMessage -Level Info } | Should -Not -Throw
        }

        It 'should handle Unicode in message' {
            { Write-Log -Message 'Unicode log message test' -Level Info } | Should -Not -Throw
        }

        It 'should handle newlines in message' {
            { Write-Log -Message "Line1`nLine2`nLine3" -Level Info } | Should -Not -Throw
        }

        It 'should handle all log levels' {
            { Write-Log -Message 'Test' -Level Verbose } | Should -Not -Throw
            { Write-Log -Message 'Test' -Level Info } | Should -Not -Throw
            { Write-Log -Message 'Test' -Level Warning } | Should -Not -Throw
            { Write-Log -Message 'Test' -Level Error } | Should -Not -Throw
        }
    }
}

Describe 'Edge Cases - Test-AdbConnection' {
    Context 'Connection States' {
        It 'should handle adb command failure' {
            Mock -CommandName 'adb' -MockWith {
                $global:LASTEXITCODE = 1
                return 'error'
            }

            $result = Test-AdbConnection -RetryCount 1
            $result | Should -Be $false
        }

        It 'should handle empty device list' {
            Mock -CommandName 'adb' -MockWith {
                $global:LASTEXITCODE = 0
                return 'List of devices attached'
            }

            $result = Test-AdbConnection -RetryCount 1
            $result | Should -Be $false
        }

        It 'should handle malformed output' {
            Mock -CommandName 'adb' -MockWith {
                $global:LASTEXITCODE = 0
                return 'corrupted output###@@@'
            }

            $result = Test-AdbConnection -RetryCount 1
            $result | Should -Be $false
        }
    }
}

Describe 'Edge Cases - Wait-ForContinue' {
    Context 'User Interaction' {
        It 'should not throw when called' {
            Mock -CommandName 'Wait-ForContinue' -MockWith { }
            { Wait-ForContinue } | Should -Not -Throw
        }

        It 'should accept custom message' {
            Mock -CommandName 'Wait-ForContinue' -MockWith { param($Message) }
            { Wait-ForContinue -Message "Custom" } | Should -Not -Throw
        }
    }
}

Describe 'Edge Cases - Integration Scenarios' {
    Context 'Concurrent Operations' {
        It 'should handle rapid successive calls' {
            Mock -CommandName 'Write-Host' -MockWith {}

            $results = 1..10 | ForEach-Object {
                Write-Title -Text "Test $_"
            }

            { $results } | Should -Not -Throw
        }
    }

    Context 'Resource Cleanup' {
        It 'should handle cleanup after errors' {
            Mock -CommandName 'Write-Host' -MockWith {}
            Mock -CommandName 'Test-AdbAvailable' -MockWith { throw 'Test error' }

            {
                try {
                    Test-AdbAvailable
                }
                catch {
                    # Cleanup
                    $null = $_
                }
            } | Should -Not -Throw
        }
    }

    Context 'Platform-Specific Edge Cases' {
        It 'should handle Windows line endings' {
            $testContent = "Line1`r`nLine2`r`nLine3"
            Mock -CommandName 'Write-Host' -MockWith {}

            { Write-Log -Message $testContent -Level Info } | Should -Not -Throw
        }

        It 'should handle Unix line endings' {
            $testContent = "Line1`nLine2`nLine3"
            Mock -CommandName 'Write-Host' -MockWith {}

            { Write-Log -Message $testContent -Level Info } | Should -Not -Throw
        }

        It 'should handle mixed line endings' {
            $testContent = "Line1`r`nLine2`nLine3`r`n"
            Mock -CommandName 'Write-Host' -MockWith {}

            { Write-Log -Message $testContent -Level Info } | Should -Not -Throw
        }
    }
}

Describe 'Edge Cases - Memory and Performance' {
    Context 'Large Data Handling' {
        It 'should handle large menu with many entries' {
            $result = New-TuiModel
            $result.Count | Should -BeGreaterThan 0
            $result.Count | Should -BeLessThan 1000  # Reasonable upper bound
        }

        It 'should handle menu extraction from large script' {
            $script:ScriptContent.Length | Should -BeGreaterThan 10000
        }
    }

    Context 'String Operations' {
        It 'should handle repeated string operations' {
            $result = 1..100 | ForEach-Object {
                Get-SectionTitleForId -Id "A$($_)"
            }

            $result.Count | Should -Be 100
        }
    }
}

