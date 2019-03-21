Add-Type -AssemblyName System.Web
[System.Web.Security.Membership]::GeneratePassword(16,4)