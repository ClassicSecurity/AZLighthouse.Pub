# Az-Lighthouse  

## Requirements  
- PowerShell 5.1 or newer  
- Azure PowerShell Modules  
    - az.accounts  
    - az.resources  
- An account that has Owner role in the client's subscription  

## Deploying Lighthouse to client accounts  

1. On a workstation that meets the above requirements copy the contents of the repo 
2. From within that folder run the command below (Update the LOCATION value to one of the regions you have resources deployed to):  

```powershell
./Enable-AzLighthouse.ps1 -ReadOnlyTemplatePath ./az-lighthouse-read-only.json -ReadOnlyParameterPath ./az-lighthouse-parameters-read-only.json -ContributorTemplatePath ./az-lighthouse-contributor.json -ContributorParameterPath ./az-lighthouse-parameters-contributor.json -Location $LOCATION
```  

3. Select the subscriptions IDs that you wish to enable Lighthouse for and hit enter.  
4. You can confirm the subscription is deployed by confirm the ProvisioningState is "Succeeded".

#### Deploy Lighthouse without the Contributor offering
If a client does not want the Contributor offering created (only wants Read-Only) then replace the code in step 3 with the following.  

```powershell
./Enable-AzLighthouse.ps1 -ReadOnlyTemplatePath ./az-lighthouse-read-only.json -ReadOnlyParameterPath ./az-lighthouse-parameters-read-only.json -Location $LOCATION
```  

### Resources  
For notes on Onboarding see the link below  
https://docs.microsoft.com/en-us/azure/lighthouse/how-to/onboard-customer

For sample deployments see the link below  
https://docs.microsoft.com/en-us/azure/lighthouse/samples/