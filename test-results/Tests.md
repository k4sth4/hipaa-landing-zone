# HIPAA Compliance Test Results

This document outlines all functional and security validations performed across our HIPAA-Compliant AWS Landing Zone. Each test aligns with real-world compliance, audit readiness, and best practices.

---

## T1: Root Login Blocked via SCP

- **Purpose:** Ensure the root user is denied via Service Control Policy (SCP).
- **Test:** Logged into Org-Dev account → Attempted actions as Root → Access Denied.

Confirm SCP Is Attached

<br><img width="755" height="273" alt="image" src="https://github.com/user-attachments/assets/11885084-3c26-4f33-9c42-45643a3fcd50" /><br>

<br><img width="766" height="400" alt="image" src="https://github.com/user-attachments/assets/56a23080-c6e4-403e-b8e9-41c75725b9eb" /><br>

<br><img width="778" height="66" alt="image" src="https://github.com/user-attachments/assets/758715b2-3085-4006-950d-f6c3371b83f0" /><br>

We won’t be able to perform any actions as you can see access denied errors.

<br><img width="556" height="519" alt="image" src="https://github.com/user-attachments/assets/dbf8105b-f618-4349-bbf1-ca2e63f2c600" /><br>

Tried to open the CloudShell or launch CLI. We will get error. This mean our Root DenyAccess policy is working.

<br><img width="778" height="188" alt="image" src="https://github.com/user-attachments/assets/56dbe040-797b-40e3-92a4-37aeb40a3e77" /><br>

- **Result:** ✅ SCP `DenyRootAccess` blocks root actions across workloads.
- **HIPAA Justification:** Enforces least privilege; Root access bypasses all guardrails.

---

## T2: SCP Region Restriction

- **Purpose:** Deny any AWS actions outside `us-east-1`.
- **Test:** Attached `AllowOnlyUsEast1` SCP → Attempted API calls in `ap-south-1`.

From management account, confirm **AllowOnlyUsEast1** SCP is attached.

<br><img width="758" height="307" alt="image" src="https://github.com/user-attachments/assets/8ffbfeca-05ec-41fb-957c-cb5b28cf2e10" /><br>

<br><img width="633" height="413" alt="image" src="https://github.com/user-attachments/assets/50986f7b-595f-4d6b-a119-3ecb16e6f275" /><br>

We are not able to access AWS services from **ap-south-1** or any region except **us-east-1**. 

<br><img width="703" height="485" alt="image" src="https://github.com/user-attachments/assets/572e522b-71a0-43ef-99fc-cce94077d18f" /><br>

- **Result:** ✅ API calls blocked outside `us-east-1`.
- **Compliance Value:** Prevents data egress to non-compliant regions, reduces attack surface.

---

## T3: CloudTrail Centralized Logging

- **Purpose:** Verify all API activity is logged to a Security account S3 bucket.
- **Test:** Created S3 bucket from Dev → Log appeared in centralized bucket.

Make an API call from a member account (e.g. Dev). To trigger the event log I created a bucket in **dev** account.

<br><img width="713" height="265" alt="image" src="https://github.com/user-attachments/assets/a0b2d909-21c6-4fbe-8d1b-8eee6870c00c" /><br>

Go to the Security Account and S3 bucket which has cloudtrail logs centrally managed. 
Download the log which was generated after we create bucket in Dev account.

<br><img width="744" height="330" alt="image" src="https://github.com/user-attachments/assets/e74c92ac-1eac-4042-99bb-8d98dcd1b078" /><br>

On analyzing logs we did find the API call of our new S3 bucket for Dev account.

<br><img width="563" height="511" alt="image" src="https://github.com/user-attachments/assets/f1453ea8-3064-4ea2-b8db-1bbea05ade73" /><br>

- **Result:** ✅ Logs captured in `org-cloudtrail-logs-security`.
- **HIPAA Relevance:** Immutable audit trails are essential for incident response.

---

## T4: GuardDuty Aggregation

- **Purpose:** Confirm GuardDuty from Dev/Prod aggregates into Security account.
- **Test:** Created sample findings in member accounts → Verified in central Security Hub.

*Run in Security Account (Delegated Admin):*
```bash
# Step 1: Get Detector ID
aws guardduty list-detectors --region us-east-1

# Step 2: Simulate findings
aws guardduty create-sample-findings --region us-east-1 --detector-id 12cbf07370bd6a26850b38bf88c08b62 --finding-types UnauthorizedAccess:EC2/SSHBruteForce
aws guardduty create-sample-findings --region us-east-1 --detector-id 12cbf07370bd6a26850b38bf88c08b62 --finding-types Recon:EC2/PortProbeUnprotectedPort
aws guardduty create-sample-findings --region us-east-1 --detector-id 12cbf07370bd6a26850b38bf88c08b62 --finding-types Trojan:EC2/BlackholeTraffic
```
Finding Types:

| Type                       | Description                          |
| -------------------------- | ------------------------------------ |
| `SSHBruteForce`            | Attempted SSH brute-force attack     |
| `PortProbeUnprotectedPort` | Port scanning activity               |
| `BlackholeTraffic`         | EC2 sending traffic to known bad IPs |

<br><img width="783" height="458" alt="image" src="https://github.com/user-attachments/assets/4955b683-00df-4d60-9e98-1473980ddb69" /><br>

<br><img width="786" height="291" alt="image" src="https://github.com/user-attachments/assets/1e7241c5-2212-49b2-88f3-ee2f0bcdbad0" /><br>

- Ran SSHBruteForce simulation from Dev account

<br><img width="851" height="128" alt="image" src="https://github.com/user-attachments/assets/1d718835-044b-477c-9994-13e7e37df86f" /><br>

<br><img width="854" height="319" alt="image" src="https://github.com/user-attachments/assets/0c1ab6c7-a07d-47ce-93ed-dc74a9ebeb1e" /><br>

- Ran BlackholeTraffic simulation from Prod account

<br><img width="864" height="160" alt="image" src="https://github.com/user-attachments/assets/095b39ea-b8dd-48ea-8eed-7195c9ebd948" /><br>

<br><img width="879" height="303" alt="image" src="https://github.com/user-attachments/assets/b7dd45d3-81e0-475b-8e39-8d762e7e59ec" /><br>

- Verified centralized aggregation in Security Hub in Security account

<br><img width="930" height="451" alt="image" src="https://github.com/user-attachments/assets/2b3faafd-27a9-47aa-9ee4-153c22dac4a0" /><br>

- **Result:** ✅ Findings are aggregated correctly.
- **Compliance Gain:** Central threat visibility for detection & forensic readiness.

---

## T5: Security Hub Enabled

- **Purpose:** Ensure findings from all accounts/services are aggregated.
- **Test:** Verified enabled Security Hub across accounts and integration with services.

We can see aggregate findings for Dev, Prod account in security account.

<br><img width="759" height="318" alt="image" src="https://github.com/user-attachments/assets/3d25203a-bd04-4084-baa4-94d22ce75bf4" /><br>

We can see we are getting findings from different AWS services.

<br><img width="778" height="354" alt="image" src="https://github.com/user-attachments/assets/dd8faea1-245d-4152-b281-0b2662b0dbb0" /><br>

<br><img width="722" height="365" alt="image" src="https://github.com/user-attachments/assets/2cf4d77b-2d73-48cc-8345-656c539db057" /><br>

- **Result:** ✅ Findings visible from Dev, Prod, and GuardDuty.
- **Benefit:** Single-pane-of-glass for HIPAA and CIS compliance.

---

## T6: VPC Sharing

- **Purpose:** Ensure Dev/Prod use subnets shared from Shared Services account.
- **Test:** Verified subnets from `10.0.x.x/24` range are visible in Dev/Prod.

Check Shared Subnets in Dev/Prod.

<br><img width="758" height="163" alt="image" src="https://github.com/user-attachments/assets/9e2b0f41-7eb0-41c1-968e-aed1ab70a43e" /><br>

<br><img width="778" height="200" alt="image" src="https://github.com/user-attachments/assets/a14ddae9-f2f4-48e8-a64b-da1f9fa183f4" /><br>

<br><img width="745" height="264" alt="image" src="https://github.com/user-attachments/assets/6047a073-7cef-4161-b074-7126d8ebbf47" /><br>

The shared VPC likely has a supernet like 10.0.0.0/16, and it’s subnetted per AZ (common design):
•	10.0.101.0/24 → AZ1
•	10.0.102.0/24 → AZ2
This confirms that:
•	Subnets are logically split by AZ for high availability
•	You’re seeing private CIDRs from the Shared account, meaning VPC sharing is working as intended

VPC sharing allows Dev and Prod to use centrally managed networking (subnets, route tables, firewalls) without duplicating infrastructure.

- **Result:** ✅ Subnet visibility confirms Resource Access Manager (RAM) is working.
- **Advantage:** Centralized networking for consistency, cost-efficiency, and auditing.

---

## T7: NAT Gateway Access

- **Purpose:** Verify instances in private subnets can access internet via NAT Gateway.
- **Test:** Launched EC2 → Connected via EC2 Connect → Ran `curl https://google.com`.

Launch EC2 into Shared Private Subnet (from Dev or Prod)
•  Subnet: Choose one of the shared private subnets (e.g., 10.0.101.0/24)
•  Auto-assign public IP: Disable
•  Security Group: Allow outbound traffic on port 443 & 80 (default outbound SG usually allows all)

<br><img width="674" height="416" alt="image" src="https://github.com/user-attachments/assets/6679606f-6100-4a80-b560-bb5770c2e69d" /><br>

<br><img width="690" height="124" alt="image" src="https://github.com/user-attachments/assets/654856e3-d356-4cea-8a67-973f1f318238" /><br>

<br><img width="703" height="108" alt="image" src="https://github.com/user-attachments/assets/1d498afc-7d44-455c-80bf-346857dfdce0" /><br>

We use EC2 connect using private IP.
First, we need to create Endpoint for EC2Connect

<br><img width="765" height="169" alt="image" src="https://github.com/user-attachments/assets/5417ca52-fb6b-4538-96f3-2fb76a0ebaa6" /><br>

Now we connect to EC2 instance using **Private IP** and trying to **curl** google.
```markdown
curl -I https://google.com
```

<br><img width="687" height="433" alt="image" src="https://github.com/user-attachments/assets/2db87bf5-50c2-4937-af33-7ec01cbcec8e" /><br>

- **Result:** ✅ Internet access successful.
- **Compliance Fit:** Supports patching while maintaining isolation (Zero Trust).

---

## T8: IAM Identity Center (SSO)

- **Purpose:** Test `devuser` and `produser` can assume correct roles.
- **Test:** Logged in as both → Verified access to `DevAppRole`, `ProdOpsRole`, etc.

<br><img width="837" height="355" alt="image" src="https://github.com/user-attachments/assets/d850cfe6-65cd-4c90-8445-e5240d0a5e95" /><br>

<br><img width="818" height="320" alt="image" src="https://github.com/user-attachments/assets/f6821f1b-ae1d-4bce-885c-b5f0eed4047b" /><br>

- **Result:** ✅ Scoped access is working.
- **Why It Matters:** Centralized identity control enforces least privilege.

---

## T9: IAM Access Analyzer

- **Purpose:** Detect public exposure of resources (S3).
- **Test:** Made S3 bucket public → Waited for analyzer result.

Create a bucket public in **Dev** account.

<br><img width="724" height="544" alt="image" src="https://github.com/user-attachments/assets/e6000eda-67d0-4fac-a3a6-8714ed90a144" /><br>

- Click on your Analyzer
- Within ~5 minutes, you should see a new finding for public S3 bucket.

<br><img width="749" height="191" alt="image" src="https://github.com/user-attachments/assets/9923844b-df4e-47fb-b881-8f54a9edd4eb" /><br>

- **Result:** ✅ Finding appeared in Access Analyzer.
- **Security Note:** Helps detect accidental misconfigurations of PHI storage.

---

## T10: Lambda Custom AWS Config Rule

- **Purpose:** Enforce EBS encryption via custom AWS Config rule.
- **Test:** Launched EC2 with unencrypted EBS → Finding appeared as Noncompliant.

In **security** account launch an EC2 instance with **unencrypted EBS volume** attached to it, now trigger the rule.

<br><img width="873" height="131" alt="image" src="https://github.com/user-attachments/assets/ce454a6a-c16a-4fd0-beb0-dc1c31a7b30c" /><br>

After sometime you'll see your custom rule finds a Noncompliant EC2 resource.

<br><img width="728" height="434" alt="image" src="https://github.com/user-attachments/assets/e0873231-eba0-4d2d-84ac-64914ffecfea" /><br>

- **Result:** ✅ Custom rule triggered successfully.
- **Bonus:** Cross-account rule centralizes compliance in the Security account.

---

## T11: S3 Object Lock (CloudTrail Logs)

- **Purpose:** Test write-once-read-many (WORM) retention.
- **Test:** Checked retention status of CloudTrail object.

<br><img width="640" height="343" alt="image" src="https://github.com/user-attachments/assets/fccc30ec-0fd5-4690-9fbc-3b3c429d7b35" /><br>

Check for compliance.
```markdown
aws s3api get-object-retention --bucket org-cloudtrail-logs-security --key AWSLogs/o-sk6jpndkg1/088044431771/CloudTrail/us-east-1/2025/07/28/088044431771_CloudTrail_us-east-1_20250728T0020Z_KCMxwuAQmtTlaetc.json.gz
```

<br><img width="824" height="179" alt="image" src="https://github.com/user-attachments/assets/ea915a5e-69ff-482d-90f3-b397a4c0a993" /><br>

We will not be able to delete the object — just added a delete marker. S3 is still retaining the locked version due to Object Lock.

- **Result:** ✅ Logs are protected from deletion.
- **Audit Readiness:** Prevents log tampering, enforces HIPAA audit controls.

---

## T12: Amazon Macie PHI Detection

- **Purpose:** Detect sensitive PHI data in S3 buckets.
- **Test:** Uploaded sample object with SSN-style strings → Verified Macie detection.

- Created S3 bucket and uploaded a sample PHI object (e.g., john ssn 123-45-6789) [john-doe-medical-record.txt](https://github.com/k4sth4/hipaa-landing-zone/blob/main/terraform/john-doe-medical-record.txt)

<br><img width="975" height="204" alt="image" src="https://github.com/user-attachments/assets/9196ae76-4a82-45fa-846e-b0d3914c50bd" /><br>

<br><img width="975" height="339" alt="image" src="https://github.com/user-attachments/assets/97cf85c8-5e87-4f9d-a7c2-c9b3ea937798" /><br>

- Enabled Macie in Security account
- Created a one-time classification job with default settings

<br><img width="975" height="391" alt="image" src="https://github.com/user-attachments/assets/9091e773-73a9-4d66-a5ca-478ca531bf96" /><br>

- Let the scan run to detect sensitive data
- Review Findings: Macie successfully flagged sensitive personal and medical data

<br><img width="929" height="239" alt="image" src="https://github.com/user-attachments/assets/b72803a1-7b41-437d-9071-f31b03848cd2" /><br>

<br><img width="653" height="494" alt="image" src="https://github.com/user-attachments/assets/501f65d1-a86e-478a-981a-649eaa6c4a1b" /><br>

- **Result:** ✅ PHI-like object detected, finding generated.
- **HIPAA Requirement:** Data loss prevention and PHI scanning confirmed.

---

## 🔚 Summary

| Test | Description | Result |
|------|-------------|--------|
| T1   | SCP: Deny Root User        | ✅ |
| T2   | SCP: Region Restriction    | ✅ |
| T3   | CloudTrail Centralization | ✅ |
| T4   | GuardDuty Aggregation      | ✅ |
| T5   | Security Hub Findings      | ✅ |
| T6   | VPC Sharing                | ✅ |
| T7   | NAT Gateway Internet Access| ✅ |
| T8   | SSO Role Switching         | ✅ |
| T9   | Access Analyzer Alert      | ✅ |
| T10  | Config Rule – EBS Encryption | ✅ |
| T11  | Object Lock for Logs       | ✅ |
| T12  | Macie PHI Detection        | ✅ |

---

### 📌 Final Note

All tests were performed in isolated, cost-optimized environments across multiple AWS accounts (Dev, Prod, Shared, Security) with centralized logging and least privilege access. The results confirm that our HIPAA-Compliant AWS Landing Zone meets key technical safeguards and audit readiness goals.
