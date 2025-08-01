# ⚠️ Troubleshooting Guide

This document records real-world issues encountered and resolved during the build and configuration of the HIPAA-Compliant AWS Landing Zone project. These practical notes can help future users understand edge cases, avoid common pitfalls, and resolve deployment failures quickly.

---

## General AWS CLI & Terraform Setup

### Problem: Default `OrganizationAccountAccessRole` Cannot Be Modified
- **Root Cause:** The default role lacks support for external ID and role customization.
- **Fix:** Created a **custom role** `OrgAccountAccessRole` in each member account with full `AdministratorAccess`, assumable by the Management account.

---

### Problem: CloudTrail Failing to Deliver Logs from Member Accounts
- **Root Cause:** S3 bucket lacked the proper permissions.
- **Fix:** Added the required [**bucket policy**](https://github.com/k4sth4/hipaa-landing-zone/blob/main/terraform/policies/org-cloudtrail-logs-security%20bucket%20policy.json) to allow access from AWS CloudTrail across all Org accounts.

---

### Problem: AWS Config Bucket Policy Not Working
- **Root Cause:** Used a central S3 bucket, but Config service didn’t have sufficient permissions.
- **Fix:** Let AWS Config auto-create separate S3 buckets in each account.

---

### Problem: SCP Prevented deploying centralized VPC in Shared Services account using terraform.
- **Root Cause:** Enforced SCP (`DenyAllIfNoMFA`) blocked automation.
- Full breakdown of the issue.

 <br><img width="594" height="430" alt="image" src="https://github.com/user-attachments/assets/5f799717-3f6b-4a98-bce8-c724c42a1d9d" /><br>

`Terraform plan` failed.

<br><img width="651" height="458" alt="image" src="https://github.com/user-attachments/assets/26433008-589e-42c6-ab5a-9e9c377b53a4" /><br>

Decode error message.

```markdown
aws sts decode-authorization-message --encoded-message <paste_encoded_error_here> -query DecodedMessage  --output json
```

<br><img width="664" height="71" alt="image" src="https://github.com/user-attachments/assets/36db5051-4eed-4424-96b9-346d41734883" /><br>

Decoded message:

```markdown
{
  "Sid": "DenyAllIfNoMFA",
  "Effect": "Deny",
  "Action": "*",
  "Resource": "*",
  "Condition": {
    "BoolIfExists": {
      "aws:MultiFactorAuthPresent": "false"
    }
  }
}
```
This seems be the problem, once we remove EnforceMFA SCP, we can deploy the VPC.

<br><img width="559" height="497" alt="image" src="https://github.com/user-attachments/assets/34accdd4-c924-43d7-9c22-539ea010178e" /><br>

- **Fix:** **Temporarily detached** the SCP from target account during setup. Re-attached after configuration completed.

---

### Problem: VPC Sharing via RAM Failed
- **Root Cause:** Organization sharing not enabled.
- Full breakdown of the issue.

<br><img width="643" height="270" alt="image" src="https://github.com/user-attachments/assets/3ddeca7d-f063-4ca0-a662-52f3a87f3c6a" /><br>

- These errors mean VPC sharing via AWS Resource Access Manager (RAM) is failing due to organization sharing not being enabled.

- **Fix:** Enabled sharing via AWS Organizations.

<br><img width="648" height="166" alt="image" src="https://github.com/user-attachments/assets/a0bc225f-fde1-491b-8743-897a8a1a6a0b" /><br>

---

### Problem: Terraform Error – Route Table Sharing Not Allowed
- **Root Cause:** Attempted to share non-shareable resource via RAM.

<br><img width="583" height="211" alt="image" src="https://github.com/user-attachments/assets/97817f14-5c16-4069-9832-5985cfcec7df" /><br>

- **Fix:** Removed unsupported resources (`route_table_arns`) from `vpc-sharing.tf` and `variables.tf`.

---

### Problem: Terraform Errors in Access Analyzer Deployment
- **Issues:**
  - `analyzer_name` was required but not passed.
  - Incorrect argument `name` used instead of `analyzer_name`.
  - `depends_on = [aws_iam_role.this]` failed due to missing role.

<br><img width="510" height="434" alt="image" src="https://github.com/user-attachments/assets/db274fb1-447d-483c-b033-59f3450c6702" /><br>
- Before main.tf

<br><img width="500" height="155" alt="image" src="https://github.com/user-attachments/assets/6f65e797-072b-4cd7-986b-734bd1ca1a05" /><br>

- Remove this line: `depends_on = [aws_iam_role.this]` — it's invalid here.
- After fix main.tf

<br><img width="514" height="110" alt="image" src="https://github.com/user-attachments/assets/aa299ced-44f9-46f8-bc0b-279bafd8839b" /><br>

<br><img width="618" height="83" alt="image" src="https://github.com/user-attachments/assets/d0b5a90b-a348-465c-bb20-b63cbf3beca8" /><br>

- **Fixes:**
  - Passed `analyzer_name` variable correctly.
  - Fixed attribute name in the resource block.
  - Removed invalid `depends_on` line.

---

### Problem: Could Not Deploy Org-Level Access Analyzer
- **Root Cause:** Security account not set as **delegated admin** for Access Analyzer.

<br><img width="531" height="119" alt="image" src="https://github.com/user-attachments/assets/c0e33885-5850-4170-ae66-bf425c163afc" /><br>

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
<br><img width="579" height="79" alt="image" src="https://github.com/user-attachments/assets/97d214a7-c96b-43cd-949e-a28e4f7f9015" /><br>

<br><img width="544" height="255" alt="image" src="https://github.com/user-attachments/assets/5e121c08-bd90-4582-b9a1-c104819858f2" /><br>

<br><img width="398" height="304" alt="image" src="https://github.com/user-attachments/assets/a1a9643a-bc42-466e-9765-bf88f39cbe2c" /><br>

---

## ✅ Lessons Learned

| Category                | Key Lesson                                                                 |
|------------------------|----------------------------------------------------------------------------|
| SCP                    | Always test SCPs in non-prod before enforcing in multiple accounts         |
| Delegated Admin        | Always create required **Service-Linked Roles** before delegating services |
| Terraform Modules      | Isolate modules per service/account and handle edge-case errors gracefully |
| CLI-Based Debugging    | Use `aws sts decode-authorization-message` to decode permission errors     |
