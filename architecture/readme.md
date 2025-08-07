# 🗺️ Architecture Diagram

The diagram below illustrates a multi-account HIPAA-compliant AWS Landing Zone designed for secure, scalable, and cost-efficient operations across development and production environments.

## Legend Box :

🔴 Security Account
🟣 Shared Services Account
🟦 Management Account
🟩 Dev & Prod Accounts

## Key highlights:

- AWS Organizations manages multiple accounts with delegated administration.
- **Management Account:** centralizes IAM Identity Center and role assignments.
- **Shared Account:** hosts a shared VPC with public and private subnets, a NAT gateway, and network ACLs, which are shared to Dev and Prod accounts via AWS Resource Access Manager.
- **Security Account:** aggregates logs (AWS CloudTrail, Config) and security findings (Security Hub, GuardDuty, Inspector) from all other accounts, with secure storage in an S3 bucket with Object Lock enabled for immutability.
- **Dev and Prod Accounts:** consume shared VPC resources, deploy workloads (Amazon EC2, EBS) and are monitored by security services.

## Data flow and controls include:

- Shared VPC is provisioned centrally and shared with Dev and Prod for consistent networking.
- Centralized NAT gateway in the Shared account allows secure internet egress.
- Security findings are aggregated into the Security account for centralized visibility and rapid response.
- CloudTrail and AWS Config logs are delivered to an immutable S3 bucket in the Security account.
- Custom AWS Config rules (using Lambda) enforce EBS encryption checks.
- IAM roles and AWS IAM Identity Center are used for federated access to all accounts.
- KMS keys in the Security account control encryption for EBS volumes.

This architecture demonstrates enterprise-grade security controls, effective use of AWS native services, and supports compliance with HIPAA safeguards.
