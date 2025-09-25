# Innovation Accelerator Contract

[![Clarinet](https://img.shields.io/badge/Clarinet-v3-blue)](https://github.com/hirosystems/clarinet)
[![Stacks](https://img.shields.io/badge/Stacks-2.5-orange)](https://www.stacks.co/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## 🚀 Overview

The Innovation Accelerator Contract is a decentralized platform built on the Stacks blockchain that enables entrepreneurs and innovators to launch projects, secure funding, and receive mentorship through a milestone-based system. The platform facilitates transparent project management, community funding, and mentor rewards.

## ✨ Key Features

### For Project Creators
- **Project Creation**: Launch innovation projects with detailed descriptions and funding goals
- **Milestone Management**: Break projects into achievable milestones with specific funding amounts
- **Mentor Assignment**: Connect with experienced mentors for guidance and support
- **Funding Receipt**: Receive funds automatically upon milestone completion

### For Backers/Investors
- **Project Funding**: Support innovative projects with STX tokens
- **Transparent Progress**: Track project milestones and completion status
- **Review System**: Rate and review completed projects
- **Investment Protection**: Funds released only upon milestone completion

### For Mentors
- **Project Mentorship**: Guide projects through development phases
- **Reward System**: Earn fees for successful project completion
- **Profile Building**: Build reputation and track mentoring success
- **Impact Measurement**: Monitor success rate and total earnings

## 🏗️ Architecture

### Contract Structure

The smart contract implements a comprehensive project lifecycle:

```
Project Creation → Milestone Addition → Funding → Mentor Assignment
        ↓
Milestone Completion → Fund Release → Project Completion → Reviews
```

### Data Maps

- **projects**: Core project information, funding status, and metadata
- **milestones**: Individual project milestones with funding amounts and deadlines
- **project-funding**: Funding contributions by individual backers
- **mentor-profiles**: Mentor statistics, earnings, and success rates
- **project-reviews**: Post-completion project ratings and reviews

## 📋 Project Statuses

- **Active (1)**: Project accepting funding and milestones
- **Completed (2)**: All milestones completed successfully
- **Cancelled (3)**: Project cancelled by admin
- **Funded (4)**: Funding goal reached, ready for milestone execution

## 🎯 Milestone Statuses

- **Pending (1)**: Milestone awaiting completion
- **Completed (2)**: Milestone successfully completed
- **Failed (3)**: Milestone deadline passed without completion

## 🚀 Quick Start

### Prerequisites
- [Clarinet CLI](https://github.com/hirosystems/clarinet) v3.0+
- [Node.js](https://nodejs.org/) v16+
- Stacks wallet for testing

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/Innovation-Accelerator-Contract.git
cd Innovation-Accelerator-Contract

# Verify contract syntax
clarinet check

# Run tests
clarinet test

# Start local development environment
clarinet integrate
```

## 💻 Usage Examples

### 1. Create a Project

```clarity
(contract-call? .innovation-accelerator create-project
  "AI-Powered Healthcare Assistant"
  "Developing an AI assistant to help patients manage their health conditions"
  "healthtech"
  u50000   ;; 50,000 microSTX funding goal
  u5000    ;; Deadline in 5000 blocks
  u5000)   ;; 5,000 microSTX mentor fee
```

### 2. Add Project Milestone

```clarity
(contract-call? .innovation-accelerator add-milestone
  u1                    ;; project-id
  "MVP Development"
  "Complete minimum viable product with core features"
  u20000                ;; 20,000 microSTX for this milestone
  u2000)                ;; Milestone deadline in blocks
```

### 3. Fund a Project

```clarity
(contract-call? .innovation-accelerator fund-project
  u1        ;; project-id
  u10000)   ;; 10,000 microSTX contribution
```

### 4. Assign Mentor

```clarity
(contract-call? .innovation-accelerator assign-mentor
  u1                    ;; project-id
  'SP123...MENTOR)      ;; mentor principal address
```

### 5. Complete Milestone

```clarity
(contract-call? .innovation-accelerator complete-milestone
  u1        ;; project-id
  u1)       ;; milestone-id
```

## 📚 API Reference

### Public Functions

#### Project Management
- `create-project(title, description, category, funding-goal, deadline-blocks, mentor-fee)` - Create new project
- `add-milestone(project-id, title, description, funding-amount, milestone-deadline)` - Add project milestone
- `cancel-project(project-id)` - Cancel project (admin only)

#### Funding System
- `fund-project(project-id, amount)` - Contribute funds to project
- `complete-milestone(project-id, milestone-id)` - Mark milestone as completed

#### Mentorship
- `assign-mentor(project-id, mentor)` - Assign mentor to project
- `claim-mentor-rewards(project-id)` - Claim mentor fees after completion

#### Review System
- `submit-review(project-id, rating, comment)` - Submit project review (backers only)

#### Administrative
- `set-platform-fee(fee-percentage)` - Update platform fee (max 20%)
- `set-min-funding-goal(min-goal)` - Set minimum funding requirement

### Read-Only Functions

- `get-project(project-id)` - Retrieve project details
- `get-milestone(project-id, milestone-id)` - Get milestone information
- `get-project-funding(project-id, backer)` - Get funding by specific backer
- `get-mentor-profile(mentor)` - Retrieve mentor statistics
- `get-project-review(project-id, reviewer)` - Get project review
- `get-platform-stats()` - Platform-wide statistics

### Error Codes

- `u400` - Invalid input parameters
- `u401` - Unauthorized access
- `u402` - Insufficient funds
- `u403` - Project closed or invalid status
- `u404` - Project not found
- `u405` - Milestone not found
- `u406` - Already funded/assigned
- `u407` - Milestone already completed
- `u408` - Invalid status for operation
- `u409` - Deadline passed
- `u410` - Not a mentor

## 💰 Economic Model

### Platform Fees
- **Default Fee**: 5% of milestone funding
- **Maximum Fee**: 20% (configurable by admin)
- **Minimum Project**: 1,000 microSTX funding goal

### Mentor Rewards
- **Fee Structure**: Up to 10% of total project funding
- **Payment Trigger**: Released upon project completion
- **Tracking**: Automatic earnings and success rate calculation

### Fund Release
- **Milestone-Based**: Funds released only upon milestone completion
- **Platform Security**: Funds held in contract until milestones are met
- **Creator Protection**: Automated release prevents fund withholding

## 🔒 Security Features

### Access Controls
- **Project Creator**: Only creators can add milestones and complete them
- **Mentor Assignment**: Only project creators can assign mentors
- **Review System**: Only project backers can submit reviews
- **Admin Functions**: Contract owner controls platform parameters

### Fund Safety
- **Escrow System**: Funds held in contract until milestones complete
- **Milestone Validation**: Strict status checking prevents double-spending
- **Deadline Enforcement**: Time-based project and milestone deadlines
- **Emergency Controls**: Admin can cancel problematic projects

## 🧪 Testing

### Run Test Suite
```bash
# Execute all tests
clarinet test

# Generate coverage report
clarinet test --coverage

# Run specific test scenarios
clarinet test tests/innovation-accelerator_test.ts
```

### Test Scenarios
- Project creation with various parameters
- Milestone addition and completion
- Funding flows and validation
- Mentor assignment and rewards
- Review submission and validation
- Error handling and edge cases

## 🛠️ Development

### Local Development
```bash
# Start Clarinet console for testing
clarinet console

# Deploy to local testnet
clarinet integrate

# Check contract syntax
clarinet check
```

### Contract Deployment
```bash
# Deploy to testnet
stx deploy_contract innovation-accelerator innovation-accelerator.clar --testnet

# Deploy to mainnet (when ready)
stx deploy_contract innovation-accelerator innovation-accelerator.clar --mainnet
```

## 🌟 Use Cases

### Startup Accelerator
- Funding rounds for early-stage startups
- Mentor matching and guidance
- Milestone-based progress tracking
- Investor community building

### Research Projects
- Academic research funding
- Collaborative research initiatives
- Peer review and validation
- Publication milestone tracking

### Open Source Development
- Community-funded development
- Feature-based milestone releases
- Contributor reward systems
- Quality assurance through reviews

### Social Impact Projects
- Community development initiatives
- Environmental sustainability projects
- Social enterprise funding
- Impact measurement and reporting

## 🤝 Contributing

We welcome contributions from developers, entrepreneurs, and innovators!

### Development Guidelines
- Follow Clarity best practices
- Include comprehensive tests
- Document new features
- Consider security implications

### Types of Contributions
- 🐛 Bug fixes and improvements
- ✨ New features and enhancements
- 📚 Documentation updates
- 🧪 Test coverage expansion
- 🔒 Security audits and reviews

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Stacks Foundation**: For the robust blockchain infrastructure
- **Clarinet Team**: For the excellent development tools
- **Innovation Community**: For inspiration and feedback
- **Open Source Contributors**: For collaborative development

---

**Built with ❤️ for the innovation ecosystem**

*Empowering entrepreneurs to bring their ideas to life through decentralized funding and mentorship.*
