# Build Guide: HIPAA-Compliant AWS Landing Zone

This document outlines the step-by-step process used to build a secure, multi-account AWS Landing Zone aligned with HIPAA safeguards using a hybrid approach (Terraform + Console).

---

## Phase 1 – AWS Organization Setup

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
