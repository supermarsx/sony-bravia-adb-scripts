# PSScriptAnalyzer settings for Sony Bravia Scripts

@{
    # Use the PowerShell Gallery rules
    IncludeDefaultRules = $true

    # Severity levels to include
    Severity = @('Error', 'Warning', 'Information')

    # Rules to explicitly include (most important ones)
    IncludeRules = @(
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingWriteHost',
        'PSUseApprovedVerbs',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSAvoidUsingPositionalParameters',
        'PSAvoidGlobalVars',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidUsingInvokeExpression',
        'PSUseCmdletCorrectly',
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSAlignAssignmentStatement',
        'PSUseCorrectCasing'
    )

    # Rules to exclude (justified exceptions)
    ExcludeRules = @(
        # Write-Host is intentional for UI output
        'PSAvoidUsingWriteHost',
        
        # We need Invoke-Expression for dynamic function calls in tests
        'PSAvoidUsingInvokeExpression'
    )

    Rules = @{
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }

        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeForRedundantWhitespace = $false
            CheckSeparator = $true
            CheckParameter = $false
        }

        PSAlignAssignmentStatement = @{
            Enable = $true
            CheckHashtable = $true
        }

        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace = @{
            Enable = $true
            NewLineAfter = $false
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore = $false
        }

        PSUseCorrectCasing = @{
            Enable = $true
        }

        PSAvoidUsingDoubleQuotesForConstantString = @{
            Enable = $false
        }
    }
}
