# HIPAA-Compliant AWS Landing Zone

This repository contains a **real-world cloud security architecture project** that demonstrates how to build a **HIPAA-aligned, multi-account AWS Landing Zone** using a **hybrid approach** (Terraform + AWS Console). The architecture emphasizes **security**, **cost efficiency**, **scalability**, and **compliance automation**—core attributes required in any production-grade cloud environment.

---

## 🎯 Objective

The objective of this project is to design and implement an AWS multi-account structure that complies with **HIPAA safeguards** by default, offering:

- Centralized logging
- Least privilege access control
- Data encryption at rest and in transit
- Immutable log retention
- Real-time threat detection
- Automated compliance checks

---

## 💡 Problem Solved

Enterprises managing Protected Health Information (PHI) face strict compliance requirements. This project solves the problem of:

- Designing a secure AWS foundation ready for PHI workloads
- Enforcing compliance through automated checks
- Enabling scalability across Dev, Prod, Shared, and Security accounts
- Maintaining cost awareness without compromising security

---

## 🧱 Project Architecture Overview

**Key architectural decisions:**
- Used AWS Organizations to split responsibilities across 5 accounts: Org Management, Dev, Prod, Shared, Security
- Chose IAM Identity Center for centralized user access with least privilege roles
- Designed shared VPC architecture for Dev/Prod workloads
- Used Terraform for infrastructure consistency and auditability
- Object Lock for CloudTrail ensures logs can't be deleted
- Custom AWS Config rules + GuardDuty + Security Hub used for compliance and detection
- Cost-effective designs: VPC sharing, centralized services (CloudTrail, Config, etc.)

**Services Used:**
- AWS Organizations
- IAM Identity Center (SSO)
- AWS Config
- CloudTrail
- VPC, NAT Gateways, Subnets
- S3 (with encryption, object lock)
- KMS
- GuardDuty, Security Hub, Macie
- Terraform (for multi-account IaC)

---

## 🚀 Build Instructions

The build was divided into **6 Phases**, documented in [`docs/Build_Guide.md`](https://github.com/k4sth4/hipaa-landing-zone/blob/main/docs/Build_Guide.md):
1. Initial Setup & IAM
2. Logging & Config Centralization
3. Networking & Shared Services
4. Identity & Access Control
5. Compliance & Encryption Add-ons
6. Advanced Add-ons (GuardDuty, SecurityHub, Macie, AI-PHI scan)

---

## ✅ HIPAA Compliance Tests

We validated the architecture against HIPAA safeguards via 20+ manual and automated tests (see [`test-results/Tests.md`](https://github.com/k4sth4/hipaa-landing-zone/blob/main/test-results/Tests.md)), including:
- S3 public access detection (Access Analyzer)
- Unencrypted EBS volumes (custom AWS Config rule)
- PHI string detection via Macie
- GuardDuty alerts
- IAM role boundary tests
- CloudTrail object lock enforcement

---

## 🛠 Troubleshooting

All known issues encountered and resolved during the build are documented in [`docs/Troubleshooting.md`](https://github.com/k4sth4/hipaa-landing-zone/blob/main/docs/Troubleshooting.md), including:
- Terraform errors
- SSM connection problems
- CloudTrail log deletion despite Object Lock

---

## 🔐 Security Highlights

- Enforced MFA everywhere
- Least privilege IAM roles for all environments
- No hardcoded secrets, credentials, or access keys
- GuardDuty & Security Hub integration for detection
- Encryption enforced with KMS for S3, EBS, Snapshots

---

## 🧠 Design Principles

| Focus Area | Key Implementation |
|------------|--------------------|
| **Security** | Centralized security tooling, least privilege, encryption |
| **Cost Optimization** | Shared VPC, centralized logs, NAT reuse |
| **Scalability** | Modular Terraform, VPC sharing, cross-account IAM |
| **Compliance** | Macie, Object Lock, custom AWS Config rules |
| **Visibility** | Centralized CloudTrail, Config, GuardDuty |

---

## 📌 Final Note

> **Billing Notice**: All AWS resources were decommissioned post-project completion to avoid ongoing charges. This repository is for demonstration and educational purposes only.

---

## 📄 License

Licensed under the [MIT License](https://github.com/k4sth4/hipaa-landing-zone/blob/main/LICENSE)


