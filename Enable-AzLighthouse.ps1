
param(
    # Path to ARM Template
    [Parameter(
        Mandatory = $true,
        ValueFromPipeline = $true
    )]
    [string]
    $ReadOnlyTemplatePath,
    [Parameter(
        Mandatory = $true,
        ValueFromPipeline = $true
    )]
    [string]
    $ReadOnlyParameterPath,
    [Parameter(
        Mandatory = $false,
        ValueFromPipeline = $true
    )]
    [string]
    $ContributorTemplatePath,
    [Parameter(
        Mandatory = $false,
        ValueFromPipeline = $true
    )]
    [string]
    $ContributorParameterPath,
    [Parameter(
        Mandatory = $true,
        ValueFromPipeline = $true
    )]
    [string]
    $Location
)


function Confirm-PSVersion {
    <#
    .SYNOPSIS
        This script will check to see if the running version of PowerShell is 5.1 or newer.   
    .DESCRIPTION
        This script does not install or make any changes.  It only checks to see if the version of PowerShell is 5.1 or newer 
    .INPUTS
        None
    .OUTPUTS
        It will output a boolean value.    If the version of PowerShell is 5.1 or newer, the value will be 'True'.  
        If it is not, then the value will be 'False'.  
    
    .NOTES
        Version:        1.0
        Author:         Joe Fecht.
        Creation Date:  December 2019
        Purpose/Change: Initial deployment
    
    .EXAMPLE
        Confirm-PSVersion

        If the running version of PowerShell is 5.1 or newer the result will be below.  

        True
    #>
    [CmdLetBinding()]
    param (
    )
    PROCESS {
        Write-Verbose "Testing to see if PowerShell v5.1 or later is installed"
        try { 
            Write-Verbose "Testing to see if PowerShell v5.1 or later is installed"
            If ($PSVersionTable.PSVersion.Major -ge "6") {
                Write-Verbose "PSVersion is 6 or newer"
                $compatible = $true
            }
            ElseIf ($PSVersionTable.PSVersion.Major -eq "5") {
                If ($PSVersionTable.PSVersion.Minor -ge "1") {
                    Write-Verbose "PS Verion is 5.1 or newer"
                    $compatible = $true
                }
                Else {
                    Write-Verbose "PS Version is v5 but not 5.1 or newer"
                    $compatible = $false
                }
            }
            Else {
                Write-Verbose "PS Version is 4 or later"
                $compatible = $false
            }
        }
        catch {
            Write-Verbose "In Catch block.  Error occurred determining PS Version"
            Write-Host "Error determining PowerShell version" -ForegroundColor Red
            Write-Host "Error Msg: $_" -ForegroundColor Red
            break
        }
        return $compatible
    }   
}

function Confirm-ModulesInstalled {
    <#
    .SYNOPSIS
        This script will check to see if the modules supplied via the $modules parameter are installed on the system.  It will provide an out of all modules and if they are installed.  
    .DESCRIPTION
        This script does not install or make any changes.  It only checks to see if the modules are installed. 
    .PARAMETER Modules
            Please provide one or more modules that you wish to check if installed.  If there are multiples please seperate by a comma
    .INPUTS
        Requires the $module parameter to be populated with one or more items
    .OUTPUTS
        Outputs a list two columns.  ModuleName and Installed.  ModuleName will display the name of the module and Installed will display True or False depending if that module is installed on the system
    
    .NOTES
        Version:        1.0
        Author:         Joe Fecht.
        Creation Date:  December 2019
        Purpose/Change: Initial deployment
    
    .EXAMPLE
        Confirm-ModulesInstalled -modules az.resources,az.accounts

        Checks for the modules Az.Resources and Az.Accounts
        Ouput shows the Az.Resources module is not installed but Az.Accounts is installed on the system. 

        ModuleName   Installed
        ----------   ---------
        az.accounts       True
        az.resources     False
    #>
    [CmdLetBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string[]]
        $modules
    )
    PROCESS {
        Write-Verbose "Testing if Modules are installed"
        $results = @()
        foreach ($module in $modules) {
            try {
                Write-Verbose "Testing for module $module"
                Import-Module -Name $module -ErrorAction SilentlyContinue
                if (Get-Module -Name $module) {
                    Write-Verbose "Module $module is installed"
                    $moduleTests = [PSCustomObject]@{
                        ModuleName = $module
                        Installed  = $true
                    }
                }
                Else {
                    Write-Verbose "Module $module is NOT installed"
                    $moduleTests = [PSCustomObject]@{ 
                        ModuleName = $module
                        Installed  = $false
                    }
                }
                $results += $moduleTests
        
            }
            catch {
                Write-Verbose "Error checking for $module"
                Write-Host "Error checking for module - $module" -ForegroundColor Red
                Write-Host "Error Msg: $_" -ForegroundColor Red
            }
        }            
        return $results
    }
}

#----------------------------------------------------------------------------------------
# Modules to get subs from the Tenant
#----------------------------------------------------------------------------------------
Function Get-AzSubsFromTenant {
    [CmdletBinding()]
    param (
    )
    PROCESS {
        Write-Verbose "Testing to see if connected to Azure"
        $Context = Get-AzContext
        try {
            if ($Context) {
                Write-Verbose "Connected to Azure"
            }
            Else {
                Write-Verbose "Need to connect to Azure"
                Write-Host "Connecting to Azure.  Please check for a browser window asking for you to login" -ForegroundColor Yellow
                $null = Login-AzAccount -ErrorAction Stop
            }
        }
        catch {
            Write-Verbose "Error validating connection to Azure."
            Write-Host "Error validating connection to Azure" -ForegroundColor Red
            Write-Host "Error Msg: $_" -ForegroundColor Red
            break
        }

        Write-Verbose "Getting list of Azure Subscriptions"
        $azSubs = Get-AzSubscription
        $tenantProps = @()
        $i = 0

        foreach ($azSub in $azSubs) {
            Write-Verbose "Getting information about $Azsub"
            $subName = $azSub.Name
            $subId = $azSub.SubscriptionID
            $subTenantId = $azSub.TenantID
            $subProps = [pscustomobject]@{
                index       = $i
                subName     = $subName
                subID       = $subId
                subTenantId = $subTenantId
            }
            $tenantProps += $subProps
            $i++
        }
        return $tenantProps
    }
}

function Read-AzSubsToRunAgainst() {
    $input_subs = @()
    $user_input = Read-Host "Select Subscriptions (example: 0,2)"
    $input_subs = $user_input.Split(',') | ForEach-Object { [int]$_ }
    return $input_subs
}

#----------------------------------------------------------------------------------------
# Modules to validate user input
#----------------------------------------------------------------------------------------
function Confirm-Numeric ($Value) {
    return $Value -match "^[\d\.]+$"
}

function Confirm-ValidSelectedIds($ids, $subs) {
    if ($ids.Length -gt ($subs | Measure-Object).Count) {
        write-host "ids = $ids"
        write-host "subs = $subs.length"
        Write-Host -fore red "Too many subscription indexes selected." -Verbose
        return 1
    }
    for ($i = 0; $i -le $ids.Length - 1; $i++) {
        $index = [int]$ids[$i]
        $is_numeric = Confirm-Numeric $index
        if (!$is_numeric) {
            Write-Host -fore red "Invalid subscription selection, enter only numbers." -Verbose
            return 1
        }
        if ($index -gt ($subs | Measure-Object).Count - 1) {
            Write-Host -fore red "Invalid subscription selection, only select valid indexes." -Verbose
            return 1
        }
    }
    return 0
}


Write-Verbose "Ensure PowerShell 5.1 or later is installed"
If (Confirm-PSVersion) {
    Write-Verbose "PowerShell 5.1 or later is installed"
}
Else {
    Write-Verbose "A later version of PowerShell is installed"
    Write-Host "The version of PowerShell is older then what is supported.  Please updated to a version 5.1 or newer of PowerShell" -ForegroundColor Yellow
    Write-Host "Please visit the site below for details on the current version of PowerShell (As of December 2019)" -ForegroundColor Yellow
    Write-Host "https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-6" -ForegroundColor Green
    Write-Host "Script is exiting" -ForegroundColor Yellow
    Exit
}

#Validate necessary modules are installed
Write-Verbose "Ensuring the proper PowerShell Modules are installed"
$installedModules = Confirm-ModulesInstalled -modules az.accounts, az.resources
$modulesNeeded = $False

foreach ($installedModule in $installedModules) {
    $moduleName = $installedModule.ModuleName
    If ($installedModule.installed) {
        Write-Verbose "$moduleName is installed"
    }
    Else {
        Write-Verbose "$moduleName is not installed"
        Write-Host "The PowerShell Module: $moduleName is not installed.  Please run the command below to install the module" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "     Install-Module -Name $moduleName -Repository PSGallery" -ForegroundColor Green
        Write-Host ""
        $modulesNeeded = $true
    }
}

If ($modulesNeeded) {
    Write-Host "Please install the modules listed above and then run the script again" -ForegroundColor Yellow
    Exit
}

#Gathering available subs and prompting user which subs deploy to run. 
$azSubs = Get-AzSubsFromTenant 
Write-Output $azSubs | Format-Table -AutoSize

$selectedSubIds = Read-AzSubsToRunAgainst

$selectedSubsValid = Confirm-ValidSelectedIds $selectedSubIds $azSubs
if ($selectedSubsValid -ne 0) {
    exit
}
Else {
    #Sub selection valid
}

ForEach ($selectedSubId in $selectedSubIds) {
    $sub = $azSubs | Where-Object { $_.Index -eq $selectedSubId }
    $selectedAzSubs += $sub
}

# Deploying Lighthouse to selected subscriptions
foreach ($azSub in $selectedAzSubs) {

    $outNull = Set-AzContext -SubscriptionId $azSub.subId -TenantID $azsub.subTenantId | select -expand name
    $azSubName = $azSub.subName
    Write-Host "Configuring lighthouse for sub: $azSubName" -ForegroundColor green

    If (Get-AzResource -ResourceType Microsoft.Databricks/workspaces) {
        Write-Host "** Unable to enable Lighthouse for $azSubName because DataBricks is present" -foregroundColor Yellow
        Write-Host "** Please see https://docs.microsoft.com/en-us/azure/lighthouse/how-to/onboard-customer for additional details" -foregroundColor Yellow
        Write-Host "** No changes have been made for $azSubName" -foregroundColor Yellow
    }
    Else {
        New-AzDeployment -Name "Lighthouse-ReadOnly" `
            -TemplateFile $ReadOnlyTemplatePath `
            -TemplateParameterFile $ReadOnlyParameterPath `
            -Location $Location `
            -WarningAction 0

        if ($ContributorTemplatePath) {
            
            Write-Verbose "Contributor template specified, adding contributor role to offer"
            New-AzDeployment -Name "Lighthouse-Contributor" `
                -TemplateFile $ContributorTemplatePath `
                -TemplateParameterFile $ContributorParameterPath `
                -Location $Location `
                -WarningAction 0
        }
    }
}
