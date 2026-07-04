using namespace System.Net

param($Request, $TriggerMetadata)

# Write-Information (and Write-Host/Warning/Error) records are forwarded by the PowerShell worker
# to the host: they stream live in the portal and land in Application Insights as traces
# correlated with the invocation when the connection string is wired.
Write-Information ("{0} {1} invoked" -f $Request.Method, $Request.Url)

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = @{ message = 'Hello from PowerShell on a Windows function app' } | ConvertTo-Json
    })
