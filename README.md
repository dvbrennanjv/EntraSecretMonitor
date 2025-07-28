# Entra Secret Monitor

This project is a way to use Azure's Logic App service to monitor and notify of expiring secrets in your Entra environment. This project looks at sending the output to a Azure Storage account and displaying it as a static website, however you could have it send a notification email with the HTML output as well.
---

## Technologies Used  
- Azure : Logic Apps, ARM Templates, Storage Accounts, Entra
- Terraform: Infrastructure as Code Tool  
- HTML/CSS : For styling our output
- GitHub : Version Control

---

## Useful Links
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)  
  Official resource for defining Azure infrastructure using Terraform.

- [Azure Logic Apps Documentation](https://learn.microsoft.com/en-us/azure/logic-apps/)  
  Build automated scalable workflows, business processes, and enterprise orchestrations to integrate your apps and data across cloud services and on-premises systems.

- [HTML/CSS Crash Course](https://www.youtube.com/watch?v=G3e-cpL7ofc&t=7756s)  
  Good place to start if you're new to the world of HTML and CSS.

---
## Security & Best Practices

1. **Use a system assigned managed identity**
    Granting your Logic App access to resources (like a Storage Account) using a system-assigned managed identity is more secure and manageable than embedding credentials or using app registrations. This reduces the risk of secrets being exposed and ensures tighter integration with Azure RBAC.

2. **Keep Terraform State Hidden**
    Always store your Terraform state in a secure remote backend (such as Azure Storage with state locking enabled). This ensures collaboration and protects against data loss or corruption. If you're developing locally, make sure the .terraform directory and terraform.tfstate files are added to .gitignore to avoid leaking sensitive information via version control.

3. **Tagging Infrastructure**  
   Tagging is a best practice in infrastructure management, especially in production environments. I’ve intentionally left out tags, as tagging strategies should be tailored to your organization’s workflow and standards. I'd reccomend to define a consistent tagging policy that outlines required tags (e.g., Environment, Owner, CostCenter) and ensures meaningful metadata is applied to all resources for visibility, cost tracking, and governance.3. **Tagging **

4. **Sanitize Repositories and use variables**
    You should never hardcode sensitive values (e.g., client secrets, subscription IDs) directly in your Terraform files. Instead, store them in a terraform.tfvars file, use environment variables, or leverage secret managers (like Azure Key Vault) to inject them securely. This improves maintainability and reduces risk in version control.

---
## Logic App Diagram
---

## How-To Guide

### Step 1: Build the Logic App in Azure Portal  
For this project, I built the Logic App directly in the Azure Portal as it made it easier to test with. Follow this guide and at the bottom I will explain how to get this imported and working with terraform
To begin:  
Go to **Azure Portal → Logic Apps → Add → Consumption**.  
We're using the **Consumption plan** here for its event-driven cost efficiency.

### Step 2: Recurrence Trigger  
Add a **Recurrence** trigger.  
This determines how often your Logic App runs (e.g., daily, weekly).

### Step 3: Get Graph API Token  
- Create a new **App Registration** in Entra.  
- Assign it **Application.Read.All** (Application type) under Microsoft Graph.  
- Create a **Client Secret**.  

Add an **HTTP** action:
- **Method**: POST  
- **URL**:  
  ```
  https://login.microsoftonline.com/YOUR_TENANT_ID/oauth2/v2.0/token
  ```
- **Body**:  
  ```
  client_id=YOUR_CLIENT_ID&scope=https://graph.microsoft.com/.default&client_secret=YOUR_CLIENT_SECRET&grant_type=client_credentials
  ```

### Step 4: Parse Token  
Add a **Parse JSON** step to extract the token.  
Schema is in `schema/step-4-token.json`.

### Step 5: Call Graph API for App Secrets  
Add another **HTTP** GET step:  
- **URL**:  
  ```
  https://graph.microsoft.com/v1.0/applications?$select=displayName,passwordCredentials
  ```
- **Headers**:  
  - `Authorization: Bearer <access_token>` (from Step 4)

### Step 6: Parse Graph Response  
Add another **Parse JSON** step using Step 5’s body.  
Schema is in `schema/step-6-apps.json`.

### Step 7: Initialize Array  
Add **Initialize Variable**:  
- Name: `allSecrets`  
- Type: `Array`  
- Value: *(Leave blank)*

### Step 8: For Each Loops  
- Outer loop: iterate over all apps (from Step 6)  
- Inner loop: iterate over `passwordCredentials`  
- Inside inner loop: create an object with App Name, Secret Name, Expiration  
- Append to `allSecrets` array

### Step 9: Filter Expiring Secrets  
Add **Filter array** step:  
- **From**: `allSecrets`  
- **Expression**:
  ```js
  and(
    not(empty(item()?['endDateTime'])),
    lessOrEquals(item()?['endDateTime'], addDays(utcNow(), 30))
  )
  ```

### Step 10: Create HTML Table  
Add **Create HTML Table** using filter result.  
Include App Name, Secret Name, Expiration, Days Remaining.

### Step 11: Compose Output  
Use **Compose** to format the HTML with CSS and heading.

### Step 12: Deploy to Storage Account  
- Enable **Static Website Hosting** on a Storage Account  
- Use **Create blob (V2)** step:  
  - **Folder path**: `$web`  
  - **Filename**: `index.html`  
  - **Content**: output from Compose  
  - **Content Type**: `text/html`

### Step 13: Assign Managed Identity  
- Enable **System-assigned Managed Identity** on your Logic App  
- Go to Storage Account → Access Control (IAM) → Assign:  
  - **Role**: `Storage Blob Data Contributor`  
  - **Principal**: your Logic App

After setup, you can visit your Storage Account static website to view the current secrets expiring soon.

### Terraform Setup (COMING SOON)


---