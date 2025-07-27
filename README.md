# Entra Secret Monitor

This project is a way to use Azure's Logic App service to monitor and notify of expiring secrets in your Entra environment. This project looks at sending the output as an email but could easily be used with containers or an S3 bucket to have a static website displaying current secrets and their expiration time.
---

## Technologies Used  
- Azure : Logic Apps, ARM Templates, Entra
- Terraform: Infrastructure as Code Tool  
- HTML/CSS : For email styling
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
---
## Logic App Diagram
---

## How-To Guide

### Step 1: Building the Logic App 
What I did for this project was the build the logic app direct in the Azure Portal and then exported the code view and create a template deployment in terraform. So will build the app and then I'll walk through the terraform steps after. I found this method alot easier for testing out the app quickly. Login to the Azure Portal --> Logic Apps --> Add --> Consumption. The hosting plan really determines what type of logic app your building, for this I felt consumption just made the most sense.

### Step 2: Recurrence Step
Create a new step and look for recurrence. This step is how often you want this logic app to run, could be every day, week, month. Pick whatever suits your needs best.

### Step 3: Get Graph API Token
We're going to be using Graph API to grab all of our secrets. You'll need to create a new app registration in Entra that will have Application.Read.All permissions for the Graph API. Once youc create that, create a client secret for that app registration and fill the URL and Body with below
URL : https://login.microsoftonline.com/b2f3b82b-689c-48c4-8ad4-8916256b8cc9/oauth2/v2.0/token
Body: client_id=YOUR_CLIENT_ID & Scope=https://graph.microsoft.com/.default& client_secret=YOUR_CLIENT_SECRET & grant_type=client_credentials

### Step 4: Parse Token
Next we need to create a parse json step so we can grab our actually token string. Look for Step 4 schema in the repos "Schema" file.

### Step 5: Call App Secrets
Lets create a new HTTP step and call it something like "Call App Secrets". This step is going to use a GET request to grab all of the Apps without our Entra environment. URL is below, header should be taking the body from our last step as our authorization token.
URL : https://graph.microsoft.com/v1.0/applications?$select=displayName,passwordCredentials

### Step 6: Parse our HTTP Call
We now need to parse our last step with a Parse JSON step. Content should be the body of our GET request. Look for Step 6 schema in the repos "Schema" file.

### Step 7: Initialize Array
As some of your app registrations may have multiple secrets in them we need a way to loop through and store all of those. To start we'll create an "initialize variables" step and call it something like allSecrets. Type should be an array.

### Step 8: For Each Loop 1 : Loop Apps
We're going to have 2 different loops. One that loops through all the apps and then one inside that loop that loops through all the secrets in each app. For our first loop (apps) we'll take the output from Step 6 as this will contain 

---