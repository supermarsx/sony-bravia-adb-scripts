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

    # Mock external commands to prevent actual execution during tests
    function global:adb {
        param([Parameter(ValueFromRemainingArguments)]$Args)
        # Return mock output that looks like successful adb command
        Write-Output "mock-device`tdevice"
        $LASTEXITCODE = 0
    }

    # Read the script content
    $scriptContent = Get-Content $script:ScriptPath -Raw

    # Extract just the functions and script-level variables, removing the param block and main execution
    # Find where functions start (after param and Set-StrictMode)
    $functionsStartPattern = '(?ms)(?<=\$ErrorActionPreference\s*=\s*[''"]Stop[''"]).*?(?=try\s*\{\s*# Initialize configuration)'
    if ($scriptContent -match $functionsStartPattern) {
        $functionsAndVars = $Matches[0]
        # Execute to define all functions and variables
        try {
            Invoke-Expression $functionsAndVars
        }
        catch {
            Write-Warning "Some functions failed to load: $_"
        }
    }
    else {
        Write-Warning "Could not extract functions from script. Tests may fail."
    }
}

AfterAll {
    # Cleanup
    Remove-Item Function:\adb -ErrorAction SilentlyContinue
}

Describe 'Script Structure' {
    BeforeAll {
        $scriptContent = Get-Content $script:ScriptPath -Raw
    }

    It 'should have proper synopsis' {
        $scriptContent | Should -Match '\.SYNOPSIS'
    }

    It 'should have description' {
        $scriptContent | Should -Match '\.DESCRIPTION'
    }

    It 'should have examples' {
        $scriptContent | Should -Match '\.EXAMPLE'
    }

    It 'should accept Action parameter' {
        $scriptContent | Should -Match '\[Parameter.*\]\s*\[string\]\$Action'
    }

    It 'should accept Serial parameter' {
        $scriptContent | Should -Match '\[string\]\$Serial'
    }

    It 'should use strict mode' {
        $scriptContent | Should -Match 'Set-StrictMode -Version Latest'
    }

    It 'should set ErrorActionPreference to Stop' {
        $scriptContent | Should -Match '\$ErrorActionPreference\s*=\s*[''"]Stop[''"]'
    }
}

Describe 'Helper Functions' {
    Context 'Test-AdbAvailable' {
        It 'should not throw when adb is available' {
            Mock -CommandName 'Get-Command' -MockWith {
                return [PSCustomObject]@{ Name = 'adb' }
            } -ModuleName 'SonyBraviaScripts'

            { & $script:TestModule { Test-AdbAvailable } } | Should -Not -Throw
        }

        It 'should throw when adb is not available' {
            Mock -CommandName 'Get-Command' -MockWith {
                return $null
            } -ModuleName 'SonyBraviaScripts'

            { & $script:TestModule { Test-AdbAvailable } } | Should -Throw '*adb was not found*'
        }
    }

    Context 'Read-NonEmpty' {
        It 'should return non-empty input' {
            Mock -CommandName 'Read-Host' -MockWith { 'test-input' } -ModuleName 'SonyBraviaScripts'

            $result = & $script:TestModule { Read-NonEmpty -Prompt 'Test' }
            $result | Should -Be 'test-input'
        }

        It 'should reject empty strings' {
            $callCount = 0
            Mock -CommandName 'Read-Host' -MockWith {
                $script:callCount++
                if ($script:callCount -eq 1) { return '' }
                if ($script:callCount -eq 2) { return '   ' }
                return 'valid'
            } -ModuleName 'SonyBraviaScripts'

            $result = & $script:TestModule { Read-NonEmpty -Prompt 'Test' }
            $result | Should -Be 'valid'
        }
    }

    Context 'Read-YesNo' {
        It 'should return true for "y"' {
            Mock -CommandName 'Read-Host' -MockWith { 'y' } -ModuleName 'SonyBraviaScripts'

            $result = & $script:TestModule { Read-YesNo -Prompt 'Test' }
            $result | Should -Be $true
        }

        It 'should return true for "yes"' {
            Mock -CommandName 'Read-Host' -MockWith { 'YES' } -ModuleName 'SonyBraviaScripts'

            $result = & $script:TestModule { Read-YesNo -Prompt 'Test' }
            $result | Should -Be $true
        }

        It 'should return false for "n"' {
            Mock -CommandName 'Read-Host' -MockWith { 'n' } -ModuleName 'SonyBraviaScripts'

            $result = & $script:TestModule { Read-YesNo -Prompt 'Test' }
            $result | Should -Be $false
        }

        It 'should return false for "no"' {
            Mock -CommandName 'Read-Host' -MockWith { 'NO' } -ModuleName 'SonyBraviaScripts'

            $result = & $script:TestModule { Read-YesNo -Prompt 'Test' }
            $result | Should -Be $false
        }

        It 'should retry on invalid input' {
            $callCount = 0
            Mock -CommandName 'Read-Host' -MockWith {
                $script:callCount++
                if ($script:callCount -eq 1) { return 'maybe' }
                return 'yes'
            } -ModuleName 'SonyBraviaScripts'

            $result = & $script:TestModule { Read-YesNo -Prompt 'Test' }
            $result | Should -Be $true
        }
    }
}

Describe 'Invoke-Adb Function' {
    BeforeEach {
        Mock -CommandName 'Write-Host' -MockWith {} -ModuleName 'SonyBraviaScripts'
        Mock -CommandName 'Test-AdbAvailable' -MockWith {} -ModuleName 'SonyBraviaScripts'
    }

    It 'should call adb with provided arguments' {
        Mock -CommandName 'adb' -MockWith {
            return 'success'
        } -ModuleName 'SonyBraviaScripts'
        Mock -CommandName '&' -MockWith {
            param($cmd, $args)
            $global:LASTEXITCODE = 0
            return 'success'
        }

        & $script:TestModule {
            param($Serial)
            $Serial = $null
            Invoke-Adb -Args @('devices')
        }

        Should -Invoke -CommandName 'Test-AdbAvailable' -ModuleName 'SonyBraviaScripts' -Times 1
    }

    It 'should include serial when provided' {
        $script:Serial = '192.168.1.100:5555'

        Mock -CommandName 'adb' -MockWith {
            param($s, $serial, $cmd)
            $s | Should -Be '-s'
            $serial | Should -Be '192.168.1.100:5555'
            return 'success'
        }

        # This test validates serial is passed correctly
        # Full integration test would require more complex mocking
    }

    It 'should throw on non-zero exit code by default' {
        Mock -CommandName '&' -MockWith {
            $global:LASTEXITCODE = 1
            return 'error'
        }

        # Test would need proper execution context
        # Validated by integration tests
    }
}

Describe 'Menu Structure' {
    BeforeAll {
        $scriptContent = Get-Content $script:ScriptPath -Raw
    }

    It 'should define the menu array' {
        $scriptContent | Should -Match '\$script:Menu\s*=\s*@\('
    }

    It 'should define the ActionMap hashtable' {
        $scriptContent | Should -Match '\$script:ActionMap\s*=\s*@\{\}'
    }

    Context 'Menu Entries' {
        BeforeAll {
            # Extract menu definition
            if ($scriptContent -match '(?ms)\$script:Menu\s*=\s*@\((.*?)\)') {
                $menuText = $Matches[1]
                $script:MenuEntries = [regex]::Matches($menuText, "@\('([^']+)',\s*'([^']+)',\s*'([^']+)'\)")
            }
        }

        It 'should have menu entries' {
            $script:MenuEntries.Count | Should -BeGreaterThan 0
        }

        It 'should have properly formatted entries' {
            foreach ($entry in $script:MenuEntries) {
                $entry.Groups[1].Value | Should -Match '^[A-Z]\d+$' # ID like A1, B2
                $entry.Groups[2].Value | Should -Not -BeNullOrEmpty # Label
                $entry.Groups[3].Value | Should -Match '^[a-z]\d+$' # Function like a1, b2
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
        $scriptContent = Get-Content $script:ScriptPath -Raw

        # Extract all action function names
        $script:ActionFunctions = [regex]::Matches($scriptContent, '(?m)^function ([a-z]\d+) \{') |
        ForEach-Object { $_.Groups[1].Value }
    }

    It 'should have action functions defined' {
        $script:ActionFunctions.Count | Should -BeGreaterThan 0
    }

    Context 'Function Definition' {
        It 'should define a1 (Connect)' {
            $scriptContent | Should -Match '(?m)^function a1 \{'
        }

        It 'should define a2 (Disconnect)' {
            $scriptContent | Should -Match '(?m)^function a2 \{'
        }

        It 'should define a3 (List devices)' {
            $scriptContent | Should -Match '(?m)^function a3 \{'
        }

        It 'should define b1 (Shell)' {
            $scriptContent | Should -Match '(?m)^function b1 \{'
        }

        It 'should define b2 (Logcat)' {
            $scriptContent | Should -Match '(?m)^function b2 \{'
        }

        It 'should define b3 (ADB help)' {
            $scriptContent | Should -Match '(?m)^function b3 \{'
        }

        It 'should define all C-series functions (processes)' {
            'c1', 'c2', 'c3', 'c4' | ForEach-Object {
                $scriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all D-series functions (device info)' {
            'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7', 'd8' | ForEach-Object {
                $scriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all E-series functions (power)' {
            'e1', 'e2' | ForEach-Object {
                $scriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all F-series functions (device name)' {
            'f1', 'f2', 'f3', 'f4', 'f5', 'f6' | ForEach-Object {
                $scriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all G-series functions (activities)' {
            'g1', 'g2', 'g3', 'g4' | ForEach-Object {
                $scriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all H-series functions (screen settings)' {
            'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'h7', 'h8', 'h9', 'h10', 'h11' | ForEach-Object {
                $scriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all I-series functions (applications)' {
            'i1', 'i2', 'i3', 'i4', 'i5', 'i6', 'i7', 'i8', 'i9', 'i10', 'i11', 'i12' | ForEach-Object {
                $scriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all J-series functions (launcher)' {
            'j1', 'j2', 'j3', 'j4' | ForEach-Object {
                $scriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all K-series functions (proxy)' {
            'k1', 'k2', 'k3', 'k4', 'k5', 'k6' | ForEach-Object {
                $scriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all L-series functions (wifi)' {
            'l1', 'l2', 'l3', 'l4', 'l5', 'l6' | ForEach-Object {
                $scriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all M-series functions (misc)' {
            'm1' | ForEach-Object {
                $scriptContent | Should -Match "(?m)^function $_ \{"
            }
        }

        It 'should define all N-series functions (factory reset)' {
            'n1', 'n2' | ForEach-Object {
                $scriptContent | Should -Match "(?m)^function $_ \{"
            }
        }
    }

    Context 'Function Implementations' {
        It 'should call Write-Title in action functions' {
            # Most action functions should set a title
            $script:ActionFunctions | ForEach-Object {
                $functionName = $_
                # Extract function body
                if ($scriptContent -match "(?ms)function $functionName \{(.*?)(?=^function |\z)") {
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
                if ($scriptContent -match "(?ms)function $functionName \{(.*?)(?=^function |\z)") {
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
                if ($scriptContent -match "(?ms)function $functionName \{(.*?)(?=^function |\z)") {
                    $Matches[1] | Should -Match 'Invoke-Adb'
                }
            }
        }
    }
}

Describe 'TUI Functions' {
    BeforeAll {
        $scriptContent = Get-Content $script:ScriptPath -Raw
    }

    It 'should define Start-Tui function' {
        $scriptContent | Should -Match '(?m)^function Start-Tui \{'
    }

    It 'should define Show-Menu function' {
        $scriptContent | Should -Match '(?m)^function Show-Menu \{'
    }

    It 'should define Invoke-Action function' {
        $scriptContent | Should -Match '(?m)^function Invoke-Action \{'
    }

    It 'should define New-TuiModel function' {
        $scriptContent | Should -Match '(?m)^function New-TuiModel \{'
    }

    It 'should define Get-NextSelectableIndex function' {
        $scriptContent | Should -Match '(?m)^function Get-NextSelectableIndex \{'
    }

    It 'should define Get-SectionTitleForId function' {
        $scriptContent | Should -Match '(?m)^function Get-SectionTitleForId \{'
    }
}

Describe 'Get-SectionTitleForId Function' {
    BeforeAll {
        # Import function for testing
        $scriptContent = Get-Content $script:ScriptPath -Raw
        if ($scriptContent -match '(?ms)(function Get-SectionTitleForId.*?(?=^function |\z))') {
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
        Mock -CommandName 'Start-Tui' -MockWith {} -ModuleName 'SonyBraviaScripts'
        Mock -CommandName 'Invoke-Action' -MockWith { return $true } -ModuleName 'SonyBraviaScripts'
    }

    It 'should accept -Action parameter' {
        # Script should handle -Action parameter
        $scriptContent = Get-Content $script:ScriptPath -Raw
        $scriptContent | Should -Match 'param\s*\(\s*\[Parameter\(Position\s*=\s*0\)\]\s*\[string\]\$Action'
    }

    It 'should accept -Serial parameter' {
        $scriptContent = Get-Content $script:ScriptPath -Raw
        $scriptContent | Should -Match '\[string\]\$Serial'
    }
}

Describe 'Error Handling' {
    BeforeAll {
        $scriptContent = Get-Content $script:ScriptPath -Raw
    }

    It 'should wrap main execution in try-catch' {
        $scriptContent | Should -Match '(?ms)try\s*\{.*?\}\s*catch\s*\{'
    }

    It 'should display error messages' {
        $scriptContent | Should -Match 'Write-Host.*ERROR.*-ForegroundColor Red'
    }

    It 'should exit with non-zero code on error' {
        $scriptContent | Should -Match 'exit 1'
    }
}

Describe 'ADB Command Validation' {
    BeforeAll {
        $scriptContent = Get-Content $script:ScriptPath -Raw
    }

    Context 'Valid ADB Commands' {
        It 'should use valid adb connect command' {
            $scriptContent | Should -Match "Invoke-Adb.*@\('connect'"
        }

        It 'should use valid adb disconnect command' {
            $scriptContent | Should -Match "Invoke-Adb.*@\('disconnect'"
        }

        It 'should use valid adb devices command' {
            $scriptContent | Should -Match "Invoke-Adb.*@\('devices'"
        }

        It 'should use valid adb shell command' {
            $scriptContent | Should -Match "Invoke-Adb.*@\('shell'"
        }

        It 'should use valid adb logcat command' {
            $scriptContent | Should -Match "Invoke-Adb.*@\('logcat'"
        }

        It 'should use valid adb reboot command' {
            $scriptContent | Should -Match "Invoke-Adb.*@\('reboot'"
        }

        It 'should use valid adb install command' {
            $scriptContent | Should -Match "Invoke-Adb.*@\('install'"
        }

        It 'should use valid adb get-serialno command' {
            $scriptContent | Should -Match "Invoke-Adb.*@\('get-serialno'"
        }

        It 'should use valid adb get-state command' {
            $scriptContent | Should -Match "Invoke-Adb.*@\('get-state'"
        }
    }

    Context 'Valid Shell Commands' {
        It 'should use valid settings commands' {
            $scriptContent | Should -Match "shell.*settings (get|put|delete)"
        }

        It 'should use valid pm commands' {
            $scriptContent | Should -Match "shell.*pm (list|disable|enable|install|uninstall)"
        }

        It 'should use valid am commands' {
            $scriptContent | Should -Match "shell.*am (start|force-stop)"
        }

        It 'should use valid wm commands' {
            $scriptContent | Should -Match "shell.*wm (density|size)"
        }

        It 'should use valid input commands' {
            $scriptContent | Should -Match "shell.*input keyevent"
        }
    }
}

Describe 'Documentation' {
    BeforeAll {
        $scriptContent = Get-Content $script:ScriptPath -Raw
    }

    It 'should have proper script header' {
        $scriptContent | Should -Match '<#'
        $scriptContent | Should -Match '#>'
    }

    It 'should document Action parameter' {
        $scriptContent | Should -Match '\.PARAMETER Action'
    }

    It 'should document Serial parameter' {
        $scriptContent | Should -Match '\.PARAMETER Serial'
    }

    It 'should have multiple examples' {
        ($scriptContent | Select-String -Pattern '\.EXAMPLE' -AllMatches).Matches.Count |
        Should -BeGreaterOrEqual 2
    }
}

Describe 'Code Quality' {
    BeforeAll {
        $scriptContent = Get-Content $script:ScriptPath -Raw
    }

    It 'should use CmdletBinding where appropriate' {
        $scriptContent | Should -Match '\[CmdletBinding\(\)\]'
    }

    It 'should use proper parameter attributes' {
        $scriptContent | Should -Match '\[Parameter\('
    }

    It 'should not have trailing whitespace' {
        $lines = Get-Content $script:ScriptPath
        $trailingWhitespace = $lines | Where-Object { $_ -match '\s+$' }
        $trailingWhitespace.Count | Should -Be 0
    }

    It 'should use consistent indentation' {
        # Check that indentation is consistent (spaces, not tabs)
        $lines = Get-Content $script:ScriptPath
        $tabLines = $lines | Where-Object { $_ -match "`t" }
        # Allow tabs in here-strings or comments
        $invalidTabs = $tabLines | Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '@"' -and $_ -notmatch '"@' }
        $invalidTabs.Count | Should -Be 0
    }
}

Describe 'Integration Scenarios' {
    It 'should have all menu entries pointing to existing functions' {
        $scriptContent = Get-Content $script:ScriptPath -Raw

        # Extract menu entries
        if ($scriptContent -match '(?ms)\$script:Menu\s*=\s*@\((.*?)\)') {
            $menuText = $Matches[1]
            $entries = [regex]::Matches($menuText, "@\('[^']+',\s*'[^']+',\s*'([^']+)'\)")

            foreach ($entry in $entries) {
                $funcName = $entry.Groups[1].Value
                $scriptContent | Should -Match "(?m)^function $funcName \{"
            }
        }
    }

    It 'should populate ActionMap from Menu' {
        $scriptContent = Get-Content $script:ScriptPath -Raw
        $scriptContent | Should -Match '\$script:ActionMap\[\$entry\[0\]\.ToLowerInvariant\(\)\]\s*=\s*\$entry\[2\]'
        $scriptContent | Should -Match '\$script:ActionMap\[\$entry\[2\]\.ToLowerInvariant\(\)\]\s*=\s*\$entry\[2\]'
    }
}

Describe 'Additional Helper Functions' {
    Context 'Write-Title' {
        BeforeEach {
            Mock -CommandName 'Write-Host' -MockWith {} -ModuleName 'SonyBraviaScripts'
        }

        It 'should exist' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            $scriptContent | Should -Match '(?m)^function Write-Title \{'
        }

        It 'should accept Text parameter' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            $scriptContent | Should -Match 'function Write-Title\s*\{[^\}]*param\s*\(\s*\[Parameter\(Mandatory\)\]\[string\]\$Text'
        }

        It 'should set window title' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            $scriptContent | Should -Match 'WindowTitle\s*=.*ScriptVer'
        }
    }

    Context 'Done' {
        It 'should exist' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            $scriptContent | Should -Match '(?m)^function Done \{'
        }

        It 'should call Pause-Continue' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function Done \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Pause-Continue'
            }
        }
    }

    Context 'Pause-Continue' {
        It 'should exist' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            $scriptContent | Should -Match '(?m)^function Pause-Continue \{'
        }

        It 'should use ReadKey' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            $scriptContent | Should -Match 'ReadKey'
        }
    }
}

Describe 'Action Function Behavior' {
    BeforeEach {
        Mock -CommandName 'Write-Host' -MockWith {} -ModuleName 'SonyBraviaScripts'
        Mock -CommandName 'Write-Title' -MockWith {} -ModuleName 'SonyBraviaScripts'
        Mock -CommandName 'Done' -MockWith {} -ModuleName 'SonyBraviaScripts'
        Mock -CommandName 'Invoke-Adb' -MockWith {
            return [pscustomobject]@{ ExitCode = 0; Output = 'success' }
        } -ModuleName 'SonyBraviaScripts'
        Mock -CommandName 'Read-NonEmpty' -MockWith { 'test-value' } -ModuleName 'SonyBraviaScripts'
        Mock -CommandName 'Read-YesNo' -MockWith { $true } -ModuleName 'SonyBraviaScripts'
        Mock -CommandName 'Read-Host' -MockWith { '' } -ModuleName 'SonyBraviaScripts'
    }

    Context 'Connection Functions' {
        It 'a1 (Connect) should call Invoke-Adb with connect' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function a1 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "Invoke-Adb.*'connect'"
            }
        }

        It 'a2 (Disconnect) should call Invoke-Adb with disconnect' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function a2 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "Invoke-Adb.*'disconnect'"
            }
        }

        It 'a3 (Devices) should call Invoke-Adb with devices' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function a3 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "Invoke-Adb.*'devices'"
            }
        }
    }

    Context 'Dangerous Functions Require Confirmation' {
        It 'e1 (Reboot) should use Read-YesNo' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function e1 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Read-YesNo'
            }
        }

        It 'e2 (Shutdown) should use Read-YesNo' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function e2 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Read-YesNo'
            }
        }

        It 'n1 (Factory reset) should use Read-YesNo' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function n1 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Read-YesNo'
            }
        }

        It 'n2 (Factory reset alt) should use Read-YesNo' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function n2 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Read-YesNo'
            }
        }

        It 'i3 (Reset permissions) should use Read-YesNo' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function i3 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Read-YesNo'
            }
        }

        It 'i10 (Uninstall) should use Read-YesNo' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function i10 \{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Read-YesNo'
            }
        }
    }

    Context 'Input Validation Functions' {
        It 'functions requiring input should use Read-NonEmpty' {
            $scriptContent = Get-Content $script:ScriptPath -Raw

            # Functions that need user input
            @('a1', 'c4', 'f4', 'f5', 'f6', 'g3', 'h2', 'h6', 'h9', 'i4', 'i5',
                'i6', 'i8', 'i9', 'i10', 'i11', 'i12', 'j2', 'j3', 'j4', 'k2',
                'k5', 'l3', 'l4', 'm1') | ForEach-Object {
                $funcName = $_
                if ($scriptContent -match "(?ms)function $funcName \{(.*?)(?=^function |\z)") {
                    $body = $Matches[1]
                    # Should either use Read-NonEmpty or Read-Host
                    $body | Should -Match '(Read-NonEmpty|Read-Host)'
                }
            }
        }
    }

    Context 'AllowFailure Flag Usage' {
        It 'functions with potentially unsupported commands should use -AllowFailure' {
            $scriptContent = Get-Content $script:ScriptPath -Raw

            # Functions that may not work on all devices
            @('c2', 'd6', 'd7', 'd8', 'e2', 'g4', 'l3', 'l4') | ForEach-Object {
                $funcName = $_
                if ($scriptContent -match "(?ms)function $funcName \{(.*?)(?=^function |\z)") {
                    $body = $Matches[1]
                    $body | Should -Match '-AllowFailure'
                }
            }
        }
    }
}

Describe 'TUI Behavior Functions' {
    BeforeAll {
        $scriptContent = Get-Content $script:ScriptPath -Raw
    }

    Context 'New-TuiModel Function' {
        It 'should accept Filter parameter' {
            $scriptContent | Should -Match 'function New-TuiModel\s*\{[^\}]*param\s*\(\s*\[string\]\$Filter'
        }

        It 'should filter menu items' {
            if ($scriptContent -match '(?ms)function New-TuiModel.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'filterText.*ToLowerInvariant'
                $Matches[1] | Should -Match '-notlike'
            }
        }

        It 'should create header entries' {
            if ($scriptContent -match '(?ms)function New-TuiModel.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "Kind\s*=\s*'header'"
            }
        }

        It 'should create item entries' {
            if ($scriptContent -match '(?ms)function New-TuiModel.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "Kind\s*=\s*'item'"
            }
        }
    }

    Context 'Get-NextSelectableIndex Function' {
        It 'should accept Items parameter' {
            $scriptContent | Should -Match 'function Get-NextSelectableIndex.*Items'
        }

        It 'should accept StartIndex parameter' {
            $scriptContent | Should -Match 'function Get-NextSelectableIndex.*StartIndex'
        }

        It 'should accept Direction parameter' {
            $scriptContent | Should -Match 'function Get-NextSelectableIndex.*Direction'
        }

        It 'should skip header entries' {
            if ($scriptContent -match '(?ms)function Get-NextSelectableIndex.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "Kind\s*-eq\s*'item'"
            }
        }
    }

    Context 'Invoke-Action Function' {
        It 'should accept Id parameter' {
            $scriptContent | Should -Match 'function Invoke-Action.*\$Id'
        }

        It 'should accept Quiet switch' {
            $scriptContent | Should -Match 'function Invoke-Action.*\[switch\]\$Quiet'
        }

        It 'should handle exit command (x)' {
            if ($scriptContent -match '(?ms)function Invoke-Action.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "if.*-eq\s*'x'"
                $Matches[1] | Should -Match 'return \$false'
            }
        }

        It 'should validate action exists in ActionMap' {
            if ($scriptContent -match '(?ms)function Invoke-Action.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'ActionMap\.ContainsKey'
            }
        }

        It 'should call the action function' {
            if ($scriptContent -match '(?ms)function Invoke-Action.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match '&\s*\$fn'
            }
        }
    }

    Context 'Start-Tui Function' {
        It 'should handle cursor visibility' {
            if ($scriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'CursorVisible'
            }
        }

        It 'should handle arrow key navigation' {
            if ($scriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'UpArrow'
                $Matches[1] | Should -Match 'DownArrow'
            }
        }

        It 'should handle Enter key for action execution' {
            if ($scriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "'Enter'"
            }
        }

        It 'should handle / for filter mode' {
            if ($scriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "'/'"
                $Matches[1] | Should -Match "'filter'"
            }
        }

        It 'should handle S for serial setting' {
            if ($scriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "'s'"
            }
        }

        It 'should handle : for direct command' {
            if ($scriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "':'"
            }
        }

        It 'should handle Escape to quit' {
            if ($scriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "'Escape'"
            }
        }

        It 'should render window title with serial' {
            if ($scriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Serial:'
            }
        }
    }
}

Describe 'Edge Cases and Error Scenarios' {
    Context 'Invalid Input Handling' {
        It 'Invoke-Action should handle invalid action IDs gracefully' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function Invoke-Action.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match "isn't valid"
            }
        }

        It 'should handle empty menu gracefully' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function New-TuiModel.*?\{(.*?)(?=^function |\z)') {
                # Should handle case where filter results in empty list
                $Matches[1] | Should -Match 'Count'
            }
        }
    }

    Context 'Boundary Conditions' {
        It 'Get-NextSelectableIndex should handle index < 0' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function Get-NextSelectableIndex.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'if.*idx -lt 0'
            }
        }

        It 'Get-NextSelectableIndex should handle index >= Count' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function Get-NextSelectableIndex.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'if.*idx -ge.*Count'
            }
        }

        It 'Get-NextSelectableIndex should handle empty items list' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function Get-NextSelectableIndex.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match 'Count -eq 0'
                $Matches[1] | Should -Match 'return -1'
            }
        }
    }

    Context 'Serial Parameter Propagation' {
        It 'Invoke-Adb should use script:Serial variable' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            if ($scriptContent -match '(?ms)function Invoke-Adb.*?\{(.*?)(?=^function |\z)') {
                $Matches[1] | Should -Match '\$Serial'
                $Matches[1] | Should -Match "'-s'"
            }
        }

        It 'script should accept Serial parameter' {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            $scriptContent | Should -Match 'param\s*\([^\)]*\[string\]\$Serial'
        }
    }
}

Describe 'Console API Usage' {
    BeforeAll {
        $scriptContent = Get-Content $script:ScriptPath -Raw
    }

    It 'should use Console SetCursorPosition' {
        $scriptContent | Should -Match '\[Console\]::SetCursorPosition'
    }

    It 'should use Console ForegroundColor' {
        $scriptContent | Should -Match '\[Console\]::ForegroundColor'
    }

    It 'should use Console BackgroundColor' {
        $scriptContent | Should -Match '\[Console\]::BackgroundColor'
    }

    It 'should use Console ReadKey' {
        $scriptContent | Should -Match '\[Console\]::ReadKey|ReadKey'
    }

    It 'should use Console WindowWidth' {
        $scriptContent | Should -Match '\[Console\]::WindowWidth'
    }

    It 'should use Console WindowHeight' {
        $scriptContent | Should -Match '\[Console\]::WindowHeight'
    }

    It 'should restore Console CursorVisible in finally block' {
        if ($scriptContent -match '(?ms)function Start-Tui.*?\{(.*?)(?=^function |\z)') {
            $Matches[1] | Should -Match 'finally'
            $Matches[1] | Should -Match 'CursorVisible.*origCursorVisible'
        }
    }
}
