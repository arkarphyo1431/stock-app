# PowerShell Deployment Commands for Azure VM
# Customer Management App - Domain Hosting

# Colors for output
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Success { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# Configuration - UPDATE THESE VALUES
$DOMAIN = "your-domain.com"  # Replace with your actual domain
$VM_IP = "YOUR_VM_PUBLIC_IP"  # Replace with your Azure VM public IP
$VM_USERNAME = "azureuser"    # Replace with your VM username
$SSH_KEY_PATH = "$env:USERPROFILE\.ssh\id_rsa"  # Path to your SSH private key

Write-Info "Customer Management App Deployment Script"
Write-Info "Domain: $DOMAIN"
Write-Info "VM IP: $VM_IP"

# Function to check if required tools are installed
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check if SSH is available
    if (!(Get-Command ssh -ErrorAction SilentlyContinue)) {
        Write-Error "SSH is not available. Please install OpenSSH or use WSL."
        return $false
    }
    
    # Check if SCP is available
    if (!(Get-Command scp -ErrorAction SilentlyContinue)) {
        Write-Error "SCP is not available. Please install OpenSSH or use WSL."
        return $false
    }
    
    # Check if SSH key exists
    if (!(Test-Path $SSH_KEY_PATH)) {
        Write-Warning "SSH key not found at $SSH_KEY_PATH"
        Write-Info "You may need to use password authentication or update the SSH_KEY_PATH variable"
    }
    
    Write-Success "Prerequisites check completed"
    return $true
}

# Function to update configuration files with actual domain
function Update-ConfigFiles {
    Write-Info "Updating configuration files with domain: $DOMAIN"
    
    # Update .env.production
    if (Test-Path ".env.production") {
        $envContent = Get-Content ".env.production" -Raw
        $envContent = $envContent -replace "your-domain\.com", $DOMAIN
        Set-Content ".env.production" $envContent
        Write-Success "Updated .env.production"
    } else {
        Write-Warning ".env.production not found"
    }
    
    # Update nginx-subdirectory.conf
    if (Test-Path "nginx-subdirectory.conf") {
        $nginxContent = Get-Content "nginx-subdirectory.conf" -Raw
        $nginxContent = $nginxContent -replace "your-domain\.com", $DOMAIN
        Set-Content "nginx-subdirectory.conf" $nginxContent
        Write-Success "Updated nginx-subdirectory.conf"
    } else {
        Write-Warning "nginx-subdirectory.conf not found"
    }
    
    Write-Success "Configuration files updated"
}

# Function to create deployment package
function New-DeploymentPackage {
    Write-Info "Creating deployment package..."
    
    # Remove existing package if it exists
    if (Test-Path "deployment-package.tar.gz") {
        Remove-Item "deployment-package.tar.gz" -Force
    }
    
    # Create exclusion list
    $excludeItems = @(
        "node_modules",
        ".next",
        ".git",
        "deployment-package.tar.gz",
        "*.log"
    )
    
    # Create tar command (requires tar to be available on Windows 10/11)
    $excludeArgs = $excludeItems | ForEach-Object { "--exclude=$_" }
    $tarCommand = "tar -czf deployment-package.tar.gz $($excludeArgs -join ' ') ."
    
    try {
        Invoke-Expression $tarCommand
        Write-Success "Deployment package created: deployment-package.tar.gz"
        
        # Show package size
        $packageSize = (Get-Item "deployment-package.tar.gz").Length / 1MB
        Write-Info "Package size: $([math]::Round($packageSize, 2)) MB"
    }
    catch {
        Write-Error "Failed to create deployment package: $_"
        Write-Info "Alternative: Use 7-Zip or WinRAR to create the archive manually"
        return $false
    }
    
    return $true
}

# Function to transfer files to Azure VM
function Copy-FilesToVM {
    Write-Info "Transferring files to Azure VM..."
    
    if (!(Test-Path "deployment-package.tar.gz")) {
        Write-Error "Deployment package not found. Run New-DeploymentPackage first."
        return $false
    }
    
    try {
        # Transfer the package
        if (Test-Path $SSH_KEY_PATH) {
            scp -i $SSH_KEY_PATH "deployment-package.tar.gz" "${VM_USERNAME}@${VM_IP}:/tmp/"
        } else {
            scp "deployment-package.tar.gz" "${VM_USERNAME}@${VM_IP}:/tmp/"
        }
        
        Write-Success "Files transferred to Azure VM"
        return $true
    }
    catch {
        Write-Error "Failed to transfer files: $_"
        Write-Info "Make sure:"
        Write-Info "1. VM IP address is correct: $VM_IP"
        Write-Info "2. SSH access is configured"
        Write-Info "3. VM is running and accessible"
        return $false
    }
}

# Function to extract files on VM
function Invoke-ExtractOnVM {
    Write-Info "Extracting files on Azure VM..."
    
    $commands = @(
        "sudo mkdir -p /fin-custome",
        "cd /fin-custome",
        "sudo tar -xzf /tmp/deployment-package.tar.gz",
        "sudo chown -R $VM_USERNAME:$VM_USERNAME /fin-custome",
        "ls -la"
    )
    
    $commandString = $commands -join "; "
    
    try {
        if (Test-Path $SSH_KEY_PATH) {
            ssh -i $SSH_KEY_PATH "${VM_USERNAME}@${VM_IP}" $commandString
        } else {
            ssh "${VM_USERNAME}@${VM_IP}" $commandString
        }
        
        Write-Success "Files extracted on Azure VM"
        return $true
    }
    catch {
        Write-Error "Failed to extract files on VM: $_"
        return $false
    }
}

# Function to run automated setup on VM
function Invoke-AutomatedSetup {
    Write-Info "Running automated setup on Azure VM..."
    Write-Warning "This will install SSL certificates and configure the server"
    
    $setupCommand = "cd /fin-custome && chmod +x quick-domain-setup.sh && sudo ./quick-domain-setup.sh $DOMAIN"
    
    try {
        if (Test-Path $SSH_KEY_PATH) {
            ssh -i $SSH_KEY_PATH "${VM_USERNAME}@${VM_IP}" $setupCommand
        } else {
            ssh "${VM_USERNAME}@${VM_IP}" $setupCommand
        }
        
        Write-Success "Automated setup completed"
        return $true
    }
    catch {
        Write-Error "Automated setup failed: $_"
        Write-Info "You may need to run the setup manually on the VM"
        return $false
    }
}

# Function to test deployment
function Test-Deployment {
    Write-Info "Testing deployment..."
    
    # Test HTTP redirect
    try {
        $response = Invoke-WebRequest -Uri "http://$DOMAIN" -MaximumRedirection 0 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 301) {
            Write-Success "HTTP to HTTPS redirect working"
        }
    }
    catch {
        Write-Warning "Could not test HTTP redirect"
    }
    
    # Test HTTPS access
    try {
        $response = Invoke-WebRequest -Uri "https://$DOMAIN/fin-customer/" -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Success "Application accessible via HTTPS"
        }
    }
    catch {
        Write-Warning "Could not access application via HTTPS"
        Write-Info "This might be due to DNS propagation delay"
    }
    
    Write-Info "Manual testing URLs:"
    Write-Info "• Application: https://$DOMAIN/fin-customer/"
    Write-Info "• API: https://$DOMAIN/fin-customer/api/customer"
}

# Function to show DNS configuration
function Show-DNSConfiguration {
    Write-Info "DNS Configuration Required:"
    Write-Info "Log into your domain registrar and create these DNS records:"
    Write-Info ""
    Write-Info "A Record:"
    Write-Info "  Type: A"
    Write-Info "  Name: @ (or $DOMAIN)"
    Write-Info "  Value: $VM_IP"
    Write-Info "  TTL: 300"
    Write-Info ""
    Write-Info "CNAME Record:"
    Write-Info "  Type: CNAME"
    Write-Info "  Name: www"
    Write-Info "  Value: $DOMAIN"
    Write-Info "  TTL: 300"
    Write-Info ""
    Write-Warning "DNS propagation can take up to 48 hours"
}

# Main deployment function
function Start-Deployment {
    param(
        [switch]$SkipPrerequisites,
        [switch]$SkipPackaging,
        [switch]$SkipTransfer,
        [switch]$SkipSetup
    )
    
    Write-Info "Starting deployment process..."
    
    if (!$SkipPrerequisites) {
        if (!(Test-Prerequisites)) {
            return
        }
    }
    
    if (!$SkipPackaging) {
        Update-ConfigFiles
        if (!(New-DeploymentPackage)) {
            return
        }
    }
    
    if (!$SkipTransfer) {
        if (!(Copy-FilesToVM)) {
            return
        }
        
        if (!(Invoke-ExtractOnVM)) {
            return
        }
    }
    
    Show-DNSConfiguration
    
    if (!$SkipSetup) {
        Write-Info "Ready to run automated setup on VM"
        $confirm = Read-Host "Do you want to run the automated setup now? (y/N)"
        if ($confirm -eq 'y' -or $confirm -eq 'Y') {
            Invoke-AutomatedSetup
            Test-Deployment
        } else {
            Write-Info "Skipping automated setup. You can run it manually later:"
            Write-Info "ssh ${VM_USERNAME}@${VM_IP}"
            Write-Info "cd /fin-custome"
            Write-Info "sudo ./quick-domain-setup.sh $DOMAIN"
        }
    }
    
    Write-Success "Deployment process completed!"
    Write-Info "Your app will be available at: https://$DOMAIN/fin-customer/"
}

# Helper functions for individual steps
function Update-Domain {
    param([string]$NewDomain)
    $script:DOMAIN = $NewDomain
    Update-ConfigFiles
    Write-Success "Domain updated to: $NewDomain"
}

function Set-VMCredentials {
    param(
        [string]$IP,
        [string]$Username,
        [string]$SSHKeyPath
    )
    $script:VM_IP = $IP
    $script:VM_USERNAME = $Username
    $script:SSH_KEY_PATH = $SSHKeyPath
    Write-Success "VM credentials updated"
}

# Show usage information
function Show-Usage {
    Write-Info "Customer Management App Deployment Commands"
    Write-Info "==========================================="
    Write-Info ""
    Write-Info "Before starting, update these variables at the top of the script:"
    Write-Info "• DOMAIN - Your actual domain name"
    Write-Info "• VM_IP - Your Azure VM public IP address"
    Write-Info "• VM_USERNAME - Your VM username"
    Write-Info "• SSH_KEY_PATH - Path to your SSH private key"
    Write-Info ""
    Write-Info "Available Commands:"
    Write-Info "• Start-Deployment - Run complete deployment process"
    Write-Info "• Update-ConfigFiles - Update config files with domain"
    Write-Info "• New-DeploymentPackage - Create deployment archive"
    Write-Info "• Copy-FilesToVM - Transfer files to Azure VM"
    Write-Info "• Invoke-AutomatedSetup - Run setup script on VM"
    Write-Info "• Test-Deployment - Test the deployed application"
    Write-Info "• Show-DNSConfiguration - Show required DNS settings"
    Write-Info ""
    Write-Info "Example usage:"
    Write-Info "PS> . .\deploy-commands.ps1"
    Write-Info "PS> Start-Deployment"
}

# Show usage when script is loaded
Show-Usage