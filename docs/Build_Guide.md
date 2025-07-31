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

## Phase 4: Identity & Access

This phase focuses on securing access and enforcing least privilege across AWS accounts using IAM roles, Access Analyzer, and IAM Identity Center (SSO).

---

### Step 1: Create IAM Roles & Policies for Least Privilege Access

We created granular IAM roles in each account to follow the principle of least privilege:

Role Name	  | Account	| Purpose
----------- |---------|-----------------------------------------
DevAppRole  |	Dev	    | Used by developers in Dev account
ProdOpsRole |	Prod	  | Used by operators in Prod account
AuditRole	  | Security|	Assumed by auditors for read-only access

- Roles are assumed cross-account using a trust policy.
- Roles use custom inline policies referencing specific ARNs.
- All roles and policies were deployed using Terraform for consistency.

Terraform structure and code: module [iam](https://github.com/k4sth4/hipaa-landing-zone/tree/main/terraform/modules/iam)  [dev](https://github.com/k4sth4/hipaa-landing-zone/tree/main/terraform/environments/dev) [prod](https://github.com/k4sth4/hipaa-landing-zone/tree/main/terraform/environments/prod)

<br><img width="560" height="431" alt="image" src="https://github.com/user-attachments/assets/0cf60154-5bd1-478b-9af8-b48602708877" /><br>

Apply terraform for both Dev and Prod.

<br><img width="483" height="452" alt="image" src="https://github.com/user-attachments/assets/4def5794-6d30-42f5-add3-f1994bc4e293" /><br>

<br><img width="510" height="123" alt="image" src="https://github.com/user-attachments/assets/8e2e2599-685f-47eb-8d7b-1f8a1c0d12ad" /><br>

<br><img width="552" height="333" alt="image" src="https://github.com/user-attachments/assets/abc205d5-7a2c-4eb0-9fe1-1410f124dccc" /><br>

<br><img width="565" height="164" alt="image" src="https://github.com/user-attachments/assets/576e738b-646c-4d85-9862-8dd6e6a9c4e1" /><br>

### Step 2: IAM Access Analyzer (Org-level + Local)
##### Purpose: Detects unintended access, public buckets, or cross-account permissions.

#### Actions Taken:
Task  | 	Description
------|------------------------------------------------------------------------------
Local | Analyzers	Deployed in Dev, Prod, and Shared accounts
Org   | Analyzer	Deployed in Security account to monitor the entire AWS Organization

#### Pre-Configuration Fixes:
- Set up provider.tf in each environment directory (Dev/Prod/Security)
- Fixed module input issues (e.g., analyzer_name was not passed)
- Removed invalid depends_on references

#### Requirements:
- Delegated Security account as Access Analyzer admin
- Created service-linked role in Management account

```makrdown
aws iam create-service-linked-role --aws-service-name access-analyzer.amazonaws.com
```

<br><img width="579" height="271" alt="image" src="https://github.com/user-attachments/assets/07a6b1c9-fba8-4731-a9e5-90665acf0463" /><br>

<br><img width="644" height="88" alt="image" src="https://github.com/user-attachments/assets/de6c6ad5-dc7c-4a17-a580-e067a6c66a13" /><br>

Terraform structure and code: access-analyzer.tf for each [environment](https://github.com/k4sth4/hipaa-landing-zone/tree/main/terraform/environments)

Set up IAM Access Analyzer in each account including shared account.

<br><img width="484" height="268" alt="image" src="https://github.com/user-attachments/assets/103d075f-afcd-4339-8a54-2902b945e852" /><br>

After `terraform init` use `terraform apply` for each account, security, dev, prod and shared inside their respective directories.

<br><img width="568" height="471" alt="image" src="https://github.com/user-attachments/assets/338a23e2-8a94-4347-9a0d-591a739676dc" /><br>

<br><img width="603" height="461" alt="image" src="https://github.com/user-attachments/assets/eb16370f-523e-4c7e-b2df-d6358ca834b4" /><br>

- Delegated Security account as admin for Access Analyzer.
- Created the required Service-Linked Role in the Management account.
- Deployed Org-level Access Analyzer in the Security account.
- Deployed local analyzers in Dev, Prod, and Shared

### Step 3: Deploy IAM Identity Center (SSO)
#### Goal: Enable secure, centralized, role-based access without legacy IAM use

First, we need to enable SSO using console in us-east-1 region.

<br><img width="975" height="93" alt="image" src="https://github.com/user-attachments/assets/7598a392-fb48-4a5c-bbdf-f4cfcd2ad063" /><br>

Terraform structure and code: [identity-center](https://github.com/k4sth4/hipaa-landing-zone/tree/main/terraform/environments/identity-center)

Apply Terraform

<br><img width="662" height="350" alt="image" src="https://github.com/user-attachments/assets/2fa3023c-13b7-45eb-b050-87fca41a6a66" /><br>

Users are visible now.

<br><img width="785" height="190" alt="image" src="https://github.com/user-attachments/assets/9c31a7b6-c07c-4e98-af35-6aef4761a3be" /><br>

#### What We Implemented via Terraform
Component                           |	Description
------------------------------------|--------------------------------------------------------------------------------------
Enabled IAM Identity Center	        | Set up in us-east-1 region with AWS-managed identity store
Created 2 users (devuser, produser)	| These represent developers/operators logging into the AWS portal
Created 2 permission sets           |	DevAppAccess, ProdOpsAccess – each maps to an IAM role
Attached AssumeRole inline policies	| Let each user assume their respective cross-account IAM role (DevAppRole, ProdOpsRole)
Assigned users to AWS accounts      | Users were assigned to Dev and Prod accounts with access to the specific roles

## Phase 5: HIPAA Enhancements

This phase implements additional safeguards aligned with HIPAA requirements, focusing on encryption, audit logging protection, and compliance automation.

---

### Step 1: KMS Customer Managed Keys (CMKs)

Purpose: Ensure encryption at rest for all sensitive services—S3, RDS, and EBS—using auditable, controllable keys.

Actions Taken:
Created KMS CMK in the Security account for:

- S3 (CloudTrail logs)
- RDS & EBS volumes

<br><img width="749" height="202" alt="image" src="https://github.com/user-attachments/assets/15402896-bc78-4268-aee8-d01b65ba167f" /><br>

<br><img width="760" height="228" alt="image" src="https://github.com/user-attachments/assets/93cb7e21-925d-400a-925c-232eb04ea221" /><br>

<br><img width="760" height="344" alt="image" src="https://github.com/user-attachments/assets/9ef3e577-5b4f-4968-8055-81f7f4421606" /><br>

- Updated CloudTrail S3 bucket to use SSE-KMS

<br><img width="762" height="234" alt="image" src="https://github.com/user-attachments/assets/f5542002-81ab-42de-9c56-09090fa81cac" /><br>

#### Create One Multi-Use KMS CMK
- Alias: alias/hipaa-data-key
- Region: us-east-1
- Purpose: Encrypt both RDS and EBS volumes across Dev and Prod

<br><img width="824" height="280" alt="image" src="https://github.com/user-attachments/assets/91785bb3-3d9f-4f99-ae67-db9aeb40ba7c" /><br>

Applied necessary key policies to allow CloudTrail and cross-account access

> NOTE: This ensures HIPAA-compliant encryption and centralized control of key usage and access logs.

### Step 2: Custom AWS Config Rule (EBS Encryption Checker)

#### Goal: Detect unencrypted EBS volumes across Dev/Prod/Security accounts.

#### Create a Lambda function to perform checks for unencrypted EBS volumes. 

Python script: ebs_encryption_checker.py
```markdown
import boto3 
import json

def lambda_handler(event, context):
    invoking_event = json.loads(event['invokingEvent'])
    configuration_item = invoking_event['configurationItem']
    compliance_type = 'NON_COMPLIANT'

    if configuration_item['resourceType'] == 'AWS::EC2::Volume':
        if configuration_item['configuration'].get('encrypted') is True:
            compliance_type = 'COMPLIANT'

    config = boto3.client('config')
    config.put_evaluations(
        Evaluations=[
            {
                'ComplianceResourceType': configuration_item['resourceType'],
                'ComplianceResourceId': configuration_item['resourceId'],
                'ComplianceType': compliance_type,
                'OrderingTimestamp': configuration_item['configurationItemCaptureTime']
            }
        ],
        ResultToken=event['resultToken']
    )
```

- First, we create a Lambda function.

<br><img width="710" height="216" alt="image" src="https://github.com/user-attachments/assets/bb950810-1887-4e2e-8277-e0d4065c09b1" /><br>

- Have the python code stored in lambda_function.zip file.

<br><img width="975" height="57" alt="image" src="https://github.com/user-attachments/assets/df040c4f-cd11-4d4b-8b90-92263d15c82d" /><br>

<br><img width="975" height="85" alt="image" src="https://github.com/user-attachments/assets/5094c458-28f8-44a7-a660-fff4f148769e" /><br>

- Create a Lambda function.

<br><img width="684" height="443" alt="image" src="https://github.com/user-attachments/assets/c4a5cf42-b72d-4dd8-85c0-281188065d67" /><br>

<br><img width="705" height="424" alt="image" src="https://github.com/user-attachments/assets/1dbaf7a7-3384-4496-aff9-e083605efbec" /><br>

<br><img width="751" height="308" alt="image" src="https://github.com/user-attachments/assets/956bd176-b508-47d1-ac29-344fcda26b62" /><br>

You can first test the logic using test events.
- Choose "Create new test event"
- Name it something like: ebs-test-event

Paste this sample test event payload (mocking a non-encrypted EBS volume):

```markdown
{
  "invokingEvent": "{\"configurationItem\": {\"resourceType\": \"AWS::EC2::Volume\", \"resourceId\": \"vol-0abc123456789def0\", \"configuration\": {\"encrypted\": false}, \"configurationItemCaptureTime\": \"2023-07-09T00:00:00Z\"}}",
  "resultToken": "test-token"
}
```

<br><img width="860" height="464" alt="image" src="https://github.com/user-attachments/assets/fb0f022e-23be-42ca-ada7-9adae692c7fe" /><br>

Upload the code using zip file.

<br><img width="815" height="463" alt="image" src="https://github.com/user-attachments/assets/eb4e7fa6-970a-4620-889a-14cf5a268b7e" /><br>

Now change the Handler name.

<br><img width="739" height="366" alt="image" src="https://github.com/user-attachments/assets/bce15d4b-3e79-45b8-8c0f-36b0007dcab8" /><br>

Now you can hit Deploy (blue button) to apply the changes.

<br><img width="794" height="146" alt="image" src="https://github.com/user-attachments/assets/3d39b4e6-36c6-4daf-9818-38c80adda39e" /><br>

Lambda execution role (EBSConfigLambdaExecRole) already has full AWS Config permissions.

<br><img width="814" height="436" alt="image" src="https://github.com/user-attachments/assets/8ffeea95-5393-4135-a554-33a71a175188" /><br>

Now the only remaining permission is allowing AWS Config to invoke the Lambda function itself, which is not controlled by the execution role — it's a resource-based policy on the Lambda function.

We add permissions to create a resource policy.

<br><img width="743" height="183" alt="image" src="https://github.com/user-attachments/assets/3342f1c4-739d-408c-aa7b-c70f3e5ddfa9" /><br>

<br><img width="750" height="413" alt="image" src="https://github.com/user-attachments/assets/46fd525a-5802-4086-ac1c-b06a6e8104a6" /><br>

#### Create AWS Config Custom Rule

<br><img width="811" height="336" alt="image" src="https://github.com/user-attachments/assets/beee9ad5-27d9-41bb-9afb-c22b64b9d20a" /><br>

<br><img width="764" height="479" alt="image" src="https://github.com/user-attachments/assets/f6e990db-e610-4659-82c6-04d71af2dcc9" /><br>

<br><img width="790" height="440" alt="image" src="https://github.com/user-attachments/assets/8757dca8-8b5c-44aa-b058-bbb105aad7b5" /><br>

<br><img width="814" height="88" alt="image" src="https://github.com/user-attachments/assets/b2f8d24a-d92d-48c0-926a-088f34556f92" /><br>

ebs-volume-encryption-required
- Custom AWS Config Rule (via your Lambda)
- Checks each individual EBS volume to ensure it's encrypted
- Evaluates compliance on a resource-by-resource basis (not just global settings)

> To enforce EBS encryption, a custom AWS Config rule is deployed across Dev, Prod, and Security accounts. For demonstration, one environment’s implementation is shown — others follow the same pattern.”
“Since Config rules are regional and per-account, I deployed the same rule across accounts to ensure full coverage. For cost and simplicity, I’ve demoed it in one environment.”

## Phase 6: Advanced Add-ons

In this final phase, we enhanced the detection and compliance capabilities of the HIPAA-compliant AWS Landing Zone using simulated findings, PHI detection, and optional alerting integrations.

---

### Step 1: Simulate Security Findings in GuardDuty & Security Hub

**Purpose:** Validate centralized detection and triage pipeline using sample threats.

- **GuardDuty** is centralized in the Security account with Dev and Prod accounts as members.
- **Simulated findings** are safe, non-malicious, and ideal for testing alert pipelines.

**Run in Security Account (Delegated Admin):**
