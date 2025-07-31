# Build Guide: HIPAA-Compliant AWS Landing Zone

This document outlines the step-by-step process used to build a secure, multi-account AWS Landing Zone aligned with HIPAA safeguards using a hybrid approach (Terraform + Console).

---

## Phase 1 – AWS Organization Setup

Establish a secure AWS Organization with workload isolation, Terraform-ready IAM roles, and cross-account access for centralized provisioning.

---

### 1. AWS Organization Creation

- Created new AWS Organization from the Management Account (ID: `885812045783`)
- Organizational Units (OUs) created:
  - `Security`
  - `SharedServices`
  - `Dev`
  - `Prod`

<br><img width="673" height="283" alt="image" src="https://github.com/user-attachments/assets/50caf2f0-82fc-47dc-a9bb-dafd8ea9a06f" /><br>

### 2. Member Account Creation

| Account Name | AWS Account ID | Assigned OU     |
|--------------|----------------|-----------------|
| Security     | 292725948066   | Security        |
| Shared       | 749717458225   | SharedServices  |
| Dev          | 088044431771   | Workloads       |
| Prod         | 674845782471   | Workloads       |

<br><img width="666" height="424" alt="image" src="https://github.com/user-attachments/assets/aa16d233-6ab8-48d1-aa49-0151be7f44aa" /><br>

Root credentials configured and stored securely (not managed by Terraform).

### 3. IAM Role Bootstrapping for Terraform Access

Manually created the following IAM Role in each member account:

**Role name:** `OrgAccountAccessRole`

<br><img width="619" height="76" alt="image" src="https://github.com/user-attachments/assets/b4b083d5-5cda-4612-90a7-043b46764342" /><br>

<br><img width="618" height="317" alt="image" src="https://github.com/user-attachments/assets/44a9d0b1-0559-4263-87c2-ed4c8d4acdda" /><br>

### 4. AWS CLI Profiles Configured for Terraform

#### Step 1: Install AWS CLI
Install the AWS CLI on your machine:
- Windows: [Download the AWS CLI v2 MSI Installer](https://awscli.amazonaws.com/AWSCLIV2.msi)

#### Step 2: Create Access Key for CLI User
- Sign into the Management account.
- Create a CLI IAM user (with Programmatic Access) and attach a suitable policy (e.g. AdministratorAccess if testing).
- Generate the Access Key ID and Secret Access Key.

<br><img width="649" height="425" alt="image" src="https://github.com/user-attachments/assets/730d679d-40f3-4b32-969f-b016ca0f0b13" /><br>

<br><img width="641" height="420" alt="image" src="https://github.com/user-attachments/assets/a714ebfe-910f-45af-b6fb-1991a6cfc18b" /><br>

#### Step 3: Configure AWS CLI Profiles
- Edit the ~/.aws/credentials and ~/.aws/config files as follows:

```markdown
`~/.aws/credentials`
[mgmt]
aws_access_key_id = AKIA...
aws_secret_access_key = ...

`~/.aws/config`
[profile mgmt]
region = us-east-1
output = json

[profile dev]
role_arn = arn:aws:iam::088044431771:role/OrgAccountAccessRole
source_profile = mgmt
external_id = kash-xyz.....
region = us-east-1

[profile prod]
role_arn = arn:aws:iam::674845782471:role/OrgAccountAccessRole
source_profile = mgmt
external_id = kash-xyz.....
region = us-east-1

[profile security]
role_arn = arn:aws:iam::292725948066:role/OrgAccountAccessRole
source_profile = mgmt
external_id = kash-xyz.....
region = us-east-1

[profile shared]
role_arn = arn:aws:iam::749717458225:role/OrgAccountAccessRole
source_profile = mgmt
external_id = kash-xyz.....
region = us-east-1
```

<br><img width="639" height="570" alt="image" src="https://github.com/user-attachments/assets/69c66c57-09d0-4736-b433-9cc2eef224f8" /><br>

Test it:

```markdown
aws sts get-caller-identity --profile dev
aws sts get-caller-identity --profile prod
aws sts get-caller-identity --profile security
```

<br><img width="631" height="370" alt="image" src="https://github.com/user-attachments/assets/c40a07da-d517-4742-b39c-a377b94ff608" /><br>

##### Why this matters:
Configuring CLI profiles with assume-role access enables secure, centralized control over all AWS member accounts. Terraform will use these profiles to assume into target accounts and deploy infrastructure without hardcoding sensitive credentials.

#### Step 4: Bootstrap Terraform
Terraform is used to provision all AWS infrastructure. AWS CLI profiles configured earlier are passed into Terraform using `aws_profile` variable.
Key Terraform files created in this step:

- `provider.tf`: Defines AWS provider using named profile
- `variables.tf`: Declares `aws_profile` variable
- `main.tf`: Starts with a test resource (e.g., S3 bucket)
- `terraform.tfvars`: Contains actual profile name used (`management`)

📁 See actual code in: [`terraform/`](https://github.com/k4sth4/hipaa-landing-zone/tree/main/terraform) [`iam-bootstrap/`](https://github.com/k4sth4/hipaa-landing-zone/tree/main/terraform/modules/iam-bootstrap) 

- Navigate to your Terraform project root:
- Create the modules/iam-bootstrap/ directory and define your IAM roles inside main.tf.

#### Terraform Project Structure
```markdown
terraform/
├── main.tf
├── provider.tf
├── modules/
│   ├── iam-bootstrap/
|       ├── main.tf
|       ├── variables.tf
|       ├── output.tf
├── environments/
│   ├── dev/
│   ├── prod/
│   ├── security/
│   └── shared/
```

Run:
```markdown
terraform init
terraform plan
terraform apply
```

<br><img width="539" height="438" alt="image" src="https://github.com/user-attachments/assets/960dfe53-d8ce-4793-aee8-b3de6c54a112" /><br>

## Phase 2 – Security & Compliance Foundation

This phase focuses on implementing security guardrails, compliance monitoring, and centralized visibility across your multi-account HIPAA-compliant AWS Landing Zone.

---

### 1. Service Control Policies (SCPs)
SCPs were defined and attached to Organizational Units (OUs) from the Management account to enforce guardrails, even for Admin users in child accounts.
[Policies](https://github.com/k4sth4/hipaa-landing-zone/tree/main/terraform/policies)
- DenyRootUserAccess — Prevents use of the root user in all member accounts.
- DenyUnsupportedRegions — Restricts services to us-east-1 only.
- EnforceMFA — Ensures IAM users must use MFA.

Attached to: Security, Dev, Prod, Shared OUs. 

<br><img width="975" height="455" alt="image" src="https://github.com/user-attachments/assets/9d896c2b-99cf-4004-b437-2ddf95096c14" /><br>

### 2. Centralized CloudTrail Logging
From the Management account, we delegated CloudTrail admin to the Security account.

```markdown
aws organizations enable-aws-service-access --service-principal cloudtrail.amazonaws.com --profile mgmt
aws organizations register-delegated-administrator --account-id 292725948066 --service-principal cloudtrail.amazonaws.com --profile mgmt
aws iam create-service-linked-role --aws-service-name cloudtrail.amazonaws.com --profile mgmt
```
<br><img width="614" height="36" alt="image" src="https://github.com/user-attachments/assets/1d5f1bf1-44ed-4434-9480-9644b461e3af" /><br> 
<br><img width="574" height="293" alt="image" src="https://github.com/user-attachments/assets/7bfba69e-8516-42a8-8b07-9122d5711f6b" /><br>

In the Security account:
- Created a secure S3 bucket with Object Lock (WORM) + Versioning.

<br><img width="623" height="154" alt="image" src="https://github.com/user-attachments/assets/f2f5bcc8-c4b4-4c21-b110-3691d9b8e21c" /><br>

<br><img width="633" height="233" alt="image" src="https://github.com/user-attachments/assets/ddd61e3e-054b-415a-a526-322b42b547cf" /><br>

- Attach S3 [Bucket Policy](https://github.com/k4sth4/hipaa-landing-zone/blob/main/terraform/policies/org-cloudtrail-logs-security%20bucket%20policy.json) to Allow CloudTrail Access from All Accounts in Org.

- Applied 7-day retention (configurable for HIPAA).

<br><img width="621" height="369" alt="image" src="https://github.com/user-attachments/assets/05a789a1-80a8-41e4-a69a-270f742e8caa" /><br>

- Created org-level trail storing logs from all accounts.
  
<br><img width="722" height="373" alt="image" src="https://github.com/user-attachments/assets/b3e7b341-4b6b-465f-a587-a0381913aa86" /><br>

### 3. AWS Config + HIPAA Conformance Packs
Enabled AWS Config in all accounts.
- From the console, deployed HIPAA Security Operational Best Practices conformance pack in each account.

<br><img width="625" height="284" alt="image" src="https://github.com/user-attachments/assets/1457158f-f9b6-4475-a022-c2e31c640597" /><br>

<br><img width="626" height="245" alt="image" src="https://github.com/user-attachments/assets/49df9a9b-dc3f-4aad-b7d0-6a7fd655d86d" /><br>

- Centralized all config logs into:
#### aws-config-security-292725948066 (bucket name)
> NOTE: we created this bucket during the set up of AWS config.
We need to aggregate AWS Config logs from all accounts into the bucket we just created for AWS config. Bukcet policy we used for AWS config bucket: [Buckey Policy](https://github.com/k4sth4/hipaa-landing-zone/blob/main/terraform/policies/aws-config%20bucket%20policy.json)

### 4. GuardDuty Setup
Enabled GuardDuty in Management, Security, Shared, Dev, and Prod accounts.
From the Management account:

```markdown
aws organizations enable-aws-service-access --service-principal guardduty.amazonaws.com
aws guardduty enable-organization-admin-account --admin-account-id 292725948066
```

From the Security account:
```markdown
aws guardduty create-detector --enable
```

<br><img width="656" height="360" alt="image" src="https://github.com/user-attachments/assets/17611d47-bbce-47a6-b517-1677e5795ef5" /><br>

<br><img width="646" height="602" alt="image" src="https://github.com/user-attachments/assets/67f0e1d5-e2dc-42f5-b223-7da837e9d565" /><br>

<br><img width="659" height="356" alt="image" src="https://github.com/user-attachments/assets/428a7010-53be-4ee8-bff0-df875807a9b2" /><br>

All findings from member accounts are now aggregated into the Security account.

### 5. Security Hub + Inspector
#### Security Hub
- Enabled in Dev & Prod.
- Delegated 292725948066 (Security account) as Security Hub admin.
- Invitations sent and accepted from Security account to Dev & Prod.
- Aggregated findings in Security account.

<br><img width="563" height="406" alt="image" src="https://github.com/user-attachments/assets/0a439b9b-0ca3-43f8-aa82-0bcb17776aea" /><br>

<br><img width="601" height="293" alt="image" src="https://github.com/user-attachments/assets/59046748-f308-4887-b866-6215b9fcdb6e" /><br>

Validation:
```markdown
aws securityhub list-organization-admin-accounts --region us-east-1
```

<br><img width="607" height="401" alt="image" src="https://github.com/user-attachments/assets/7a60e464-f595-4323-b40f-ea18c77e4dbe" /><br>

#### Amazon Inspector
- Enabled in Dev & Prod.
- Delegated admin assigned:
```markdown
aws inspector2 enable-delegated-admin-account --delegated-admin-account-id 292725948066
```

<br><img width="648" height="221" alt="image" src="https://github.com/user-attachments/assets/fb84f990-980c-44b3-acfe-e628db368676" /><br>

<br><img width="629" height="213" alt="image" src="https://github.com/user-attachments/assets/c5f6fa79-f127-499a-b209-86de5a9fb101" /><br>

> Note: Inspector findings do not appear in a centralized view in the console, but can be queried via CLI from the Security account.

## Phase 3: Networking & Shared Services

This phase sets up a centralized VPC in the **Shared Services account** and shares it with **Dev** and **Prod** accounts using AWS Resource Access Manager (RAM). This ensures centralized control, cost-efficiency, and consistency across environments.

---

### Step 1: Deploy Centralized VPC (Shared Account)

We created a centralized VPC using Terraform in the `org-shared` account:

- **VPC ID**: `vpc-0e367aa98ffa1c450`
- **CIDR**: `10.0.0.0/16`

> 🛑 Note: Temporarily detached `DenyAllIfNoMFA` SCP to allow provisioning.

Create Public/Private Subnets, NAT Gateway, Route Tables

Public Subnets
    AZ	   |  CIDR Block	  | Subnet ID	Auto-Assign Public IP
-----------|----------------|-----------------------------------
us-east-1a |	10.0.1.0/24	  |  subnet-0fce8f4881e8ea76c	
us-east-1b |	10.0.2.0/24	  |  subnet-0a7f391c6bbab0057	

Private Subnets
   AZ	     |  CIDR Block	  | Subnet ID	NAT Access
-----------|----------------|------------------------
us-east-1a | 10.0.101.0/24	| subnet-0a114eaf6b3ed7dc8	
us-east-1b |	10.0.102.0/24	| subnet-0e28ff99ce75fbd7a	

Terraform structure and code: module [vpc](https://github.com/k4sth4/hipaa-landing-zone/tree/main/terraform/modules/vpc) and [shared account](https://github.com/k4sth4/hipaa-landing-zone/tree/main/terraform/environments/shared): 

<br><img width="222" height="264" alt="image" src="https://github.com/user-attachments/assets/eabc3065-546d-413c-a3de-04a0837d046f" /><br>

<br><img width="366" height="384" alt="image" src="https://github.com/user-attachments/assets/41884196-a080-4142-93b3-f7fcb5b8a160" /><br>

<br><img width="585" height="310" alt="image" src="https://github.com/user-attachments/assets/27e5116d-157a-44ad-8c88-5628dcd235a8" /><br>

```markdown
terraform init
```

<br><img width="580" height="420" alt="image" src="https://github.com/user-attachments/assets/36d624db-824f-41c6-b71e-eda79ad7d3ad" /><br>

```markdown
terraform plan
```

<br><img width="639" height="690" alt="image" src="https://github.com/user-attachments/assets/929af51d-a9de-4962-84bb-0566667ee396" /><br>

```markdown
terraform apply
```

<br><img width="644" height="572" alt="image" src="https://github.com/user-attachments/assets/cddecce3-71fe-4fc6-b867-add518c92dbd" /><br>

- NAT Gateway created with an Elastic IP
- Route tables created and associated per subnet type

### Step 2: Share Subnets using RAM (Dev/Prod)
- Enabled "Sharing with AWS Organization" in the RAM settings

<br><img width="585" height="151" alt="image" src="https://github.com/user-attachments/assets/fd77179c-67ab-4497-81cd-6250d8a6d47f" /><br>

- Shared private subnets with Dev and Prod accounts

Terraform structure and code: module [vpc-sharing](https://github.com/k4sth4/hipaa-landing-zone/tree/main/terraform/modules/vpc-sharing)

- Use `terraform apply` to apply chnages.

<br><img width="699" height="349" alt="image" src="https://github.com/user-attachments/assets/34d1d15c-cff2-44c5-9569-fde09d7cdbff" /><br>

#### Summary:
In Phase 3, we designed and deployed a centralized networking architecture to ensure consistent, secure, and cost-efficient infrastructure across all accounts:
- Created a central VPC in the Shared Services account to avoid duplicating networking components in each workload account.
- Provisioned public and private subnets across two Availability Zones for high availability.
- Deployed a NAT Gateway to enable secure internet access for private subnets.
- Used AWS Resource Access Manager (RAM) to share private subnets with Dev and Prod accounts—enabling them to launch resources into centrally managed networking components.
- Ensured isolation between public and private traffic and removed unnecessary SCP restrictions during provisioning.
