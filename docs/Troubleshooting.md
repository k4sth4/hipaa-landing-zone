# ⚠️ Troubleshooting Guide

This document records real-world issues encountered and resolved during the build and configuration of the HIPAA-Compliant AWS Landing Zone project. These practical notes can help future users understand edge cases, avoid common pitfalls, and resolve deployment failures quickly.

---

## General AWS CLI & Terraform Setup

### Problem: AWS CLI Profile Not Assuming Role Properly
- **Root Cause:** Misconfigured `[profile dev]` block in `~/.aws/config`.
- **Fix:** Ensure `source_profile` is set to `mgmt` and `role_arn` points to `OrgAccountAccessRole` in the target member account.

---

## Phase 1: Multi-Account Setup

### Problem: Default `OrganizationAccountAccessRole` Cannot Be Modified
- **Root Cause:** The default role lacks support for external ID and role customization.
- **Fix:** Created a **custom role** `OrgAccountAccessRole` in each member account with full `AdministratorAccess`, assumable by the Management account.

---

## Phase 2: Security Foundations

### Problem: CloudTrail Failing to Deliver Logs from Member Accounts
- **Root Cause:** S3 bucket lacked the proper permissions.
- **Fix:** Added the required **bucket policy** to allow access from AWS CloudTrail across all Org accounts.

### Problem: SCP Prevented CloudTrail/Config/GuardDuty Setup
- **Root Cause:** Enforced SCP (`DenyAllIfNoMFA`) blocked automation.
- **Fix:** **Temporarily detached** the SCP from target account during setup. Re-attached after configuration completed.

### Problem: AWS Config Bucket Policy Not Working
- **Root Cause:** Used a central S3 bucket, but Config service didn’t have sufficient permissions.
- **Fix:** Let AWS Config auto-create separate S3 buckets in each account.

### Problem: AWS Config Not Showing HIPAA Conformance Packs Logs
- **Fix:** Changed approach to allow automatic S3 bucket creation and reran Conformance Packs.

---

## Phase 3: Networking

### Problem: VPC Sharing via RAM Failed
- **Root Cause:** Organization sharing not enabled.
- **Fix:** Enabled sharing via AWS Organizations and confirmed via CLI:
  ```bash
  aws ram enable-sharing-with-aws-organization
  ```

### Problem: Terraform Error – Route Table Sharing Not Allowed
- **Root Cause:** Attempted to share non-shareable resource via RAM.
- **Fix:** Removed unsupported resources (`route_table_arns`) from `vpc-sharing.tf` and `variables.tf`.

---

## Phase 4: IAM Access

### Problem: Terraform Errors in Access Analyzer Deployment
- **Issues:**
  - `analyzer_name` was required but not passed.
  - Incorrect argument `name` used instead of `analyzer_name`.
  - `depends_on = [aws_iam_role.this]` failed due to missing role.
- **Fixes:**
  - Passed `analyzer_name` variable correctly.
  - Fixed attribute name in the resource block.
  - Removed invalid `depends_on` line.

### Problem: Could Not Deploy Org-Level Access Analyzer
- **Root Cause:** Security account not set as **delegated admin** for Access Analyzer.
- **Fix:**
  - From Management account:
    ```bash
    aws organizations enable-aws-service-access --service-principal access-analyzer.amazonaws.com
    aws organizations register-delegated-administrator --account-id <SECURITY_ACCOUNT_ID> --service-principal access-analyzer.amazonaws.com
    ```
  - Created Service-Linked Role:
    ```bash
    aws iam create-service-linked-role --aws-service-name access-analyzer.amazonaws.com
    ```

---

## Phase 5: Custom Config Rule & Lambda

### Problem: AWS Config Failing to Invoke Lambda Function
- **Root Cause:** Missing Lambda **resource-based policy** for AWS Config.
- **Fix:** Manually added:
  ```bash
  aws lambda add-permission     --function-name ebs-encryption-checker     --principal config.amazonaws.com     --action lambda:InvokeFunction     --statement-id AllowExecutionFromConfig     --source-account <ACCOUNT_ID>
  ```

### Problem: Lambda Function Zip Not Deploying
- **Fix:** Zipped only the `.py` file (not the folder) and updated handler path correctly in the console.

---

## Phase 6: Advanced Add-ons

### Problem: Security Hub → SNS Alert Not Delivered
- **Root Cause:** Missing CloudWatch/permission integration for SNS notifications.
- **Fix:** Partial implementation — left this as incomplete in the project with a comment to revisit later.

### Problem: Athena Failing to Parse CloudTrail Logs
- **Issues:**
  - Schema inconsistency.
  - Too broad S3 prefix (`AWSLogs/`) used.
- **Fixes:**
  - Cleaned up existing crawlers and tables.
  - Created a new **Glue Crawler** with specific S3 path (e.g., `/AWSLogs/292725948066/CloudTrail/us-east-1/2025/`).
  - Regenerated table with better schema matching.

---

## ✅ Lessons Learned

| Category                | Key Lesson                                                                 |
|------------------------|----------------------------------------------------------------------------|
| SCP                    | Always test SCPs in non-prod before enforcing in multiple accounts         |
| Lambda                 | Permissions must be added both to the role and as a resource policy        |
| Config Rules           | Custom rules must be manually tested with `start-config-rules-evaluation` |
| Delegated Admin        | Always create required **Service-Linked Roles** before delegating services |
| Terraform Modules      | Isolate modules per service/account and handle edge-case errors gracefully |
| CLI-Based Debugging    | Use `aws sts decode-authorization-message` to decode permission errors     |
