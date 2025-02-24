# TalentNexus

A decentralized marketplace for professional services built on Stacks blockchain, enabling secure and transparent collaboration between clients and skilled professionals.

## Overview

TalentNexus is a smart contract-based platform that facilitates professional service agreements with built-in payment protection, milestone-based delivery, and dispute resolution mechanisms. The platform ensures trust and security through a collateral system and transparent project management.

## Features

### For Clients
- Create projects with detailed specifications
- Set up milestone-based payments
- Review and approve deliverables
- Access dispute resolution system
- View talent ratings and history

### For Professionals
- Secure payment guarantees
- Milestone-based compensation
- Build reputation through ratings
- Protect earnings with dispute resolution
- Showcase expertise in specific categories

### Platform Features
- Escrow payment system
- Milestone tracking
- Reputation management
- Category-based organization
- Collateral-backed services
- Automated payment distribution
- Evidence-based dispute resolution

## Smart Contract Functions

### Project Management
```clarity
(create-project talent total-budget description category duration)
(add-milestone project-id description payment)
(complete-milestone project-id milestone-id)
```

### Deposit System
```clarity
(make-deposit amount)
(withdraw-deposit)
```

### Dispute Resolution
```clarity
(submit-dispute-evidence project-id evidence-hash)
```

### Read Operations
```clarity
(view-project project-id)
(view-milestone project-id milestone-id)
(view-talent-rating professional)
(view-talent-stats professional)
(view-category category-id)
(view-dispute-evidence project-id party)
```

## Technical Parameters

- Minimum Deposit: 1,000,000 microSTX
- Maximum Milestones per Project: 10
- Maximum Project Duration: 14,400 blocks (~100 days)
- Platform Fee: 2.5%
- Deposit Lock Period: 1,440 blocks (~10 days)

## Error Codes

| Code | Description |
|------|-------------|
| u1   | Not authorized |
| u2   | Invalid project |
| u3   | Insufficient funds |
| u4   | Project inactive |
| u5   | Stage mismatch |
| u6   | Deposit locked |
| u7   | Invalid payment |
| u8   | Maximum milestones reached |
| u9   | Invalid talent |
| u10  | Invalid description |
| u11  | Invalid category |
| u12  | Invalid duration |
| u13  | Invalid name |
| u14  | Invalid project ID |
| u15  | Invalid milestone ID |
| u16  | Invalid evidence |

## Getting Started

### For Clients

1. **Creating a Project**
   ```clarity
   (contract-call? .talent-nexus create-project
     talent-address
     u1000000000  ;; total budget in microSTX
     "Project Description"
     "Development"
     u1440)  ;; duration in blocks
   ```

2. **Adding Milestones**
   ```clarity
   (contract-call? .talent-nexus add-milestone
     u1  ;; project-id
     "Milestone 1 Description"
     u500000000)  ;; payment in microSTX
   ```

3. **Completing Milestones**
   ```clarity
   (contract-call? .talent-nexus complete-milestone
     u1  ;; project-id
     u0)  ;; milestone-id
   ```

### For Professionals

1. **Making a Deposit**
   ```clarity
   (contract-call? .talent-nexus make-deposit
     u1000000)  ;; deposit amount in microSTX
   ```

2. **Submitting Dispute Evidence**
   ```clarity
   (contract-call? .talent-nexus submit-dispute-evidence
     u1  ;; project-id
     0x...)  ;; evidence hash
   ```

## Security Considerations

1. **Deposit Requirements**
   - Professionals must maintain a minimum deposit
   - Deposits are time-locked to prevent immediate withdrawal

2. **Payment Protection**
   - Funds are held in escrow until milestone completion
   - Platform fee is automatically calculated and collected
   - Milestone payments are released only after client approval

3. **Dispute Resolution**
   - Evidence can be submitted by both parties
   - Arbitration system for conflict resolution
   - Time-locked dispute period

## Best Practices

1. **For Clients**
   - Break projects into clear milestones
   - Set realistic timelines
   - Provide detailed project descriptions
   - Review professional's rating and history
   - Keep evidence of all communications

2. **For Professionals**
   - Maintain sufficient deposit
   - Document work progress
   - Communicate timeline changes
   - Keep evidence of deliverables
   - Build and maintain positive ratings

## Development

### Prerequisites
- Clarity CLI
- Stacks blockchain environment
- STX testnet/mainnet tokens

### Testing
Test cases are provided for all major functions including:
- Project creation and management
- Milestone handling
- Payment processing
- Dispute resolution
- Category management

