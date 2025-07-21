# Digital Public Health Clinic Medical Supply Inventory

A comprehensive blockchain-based medical supply inventory management system built on Stacks using Clarity smart contracts.

## System Overview

This system manages medical supply inventory for public health clinics through five interconnected smart contracts:

1. **Supply Ordering Contract** - Manages medical supply purchases and vendor relationships
2. **Expiration Tracking Contract** - Monitors medication and supply expiration dates
3. **Usage Monitoring Contract** - Tracks supply consumption patterns for ordering optimization
4. **Storage Management Contract** - Maintains proper storage conditions for medical supplies
5. **Emergency Restocking Contract** - Handles urgent supply needs and emergency orders

## Features

### Supply Ordering
- Vendor registration and management
- Purchase order creation and tracking
- Supply catalog management
- Order status updates

### Expiration Tracking
- Automatic expiration date monitoring
- Alert system for near-expiry items
- Batch tracking for medications
- Disposal record keeping

### Usage Monitoring
- Real-time consumption tracking
- Usage pattern analysis
- Automated reorder point calculations
- Historical usage data

### Storage Management
- Temperature and humidity monitoring
- Storage location assignments
- Compliance tracking
- Environmental alert system

### Emergency Restocking
- Urgent order processing
- Emergency supplier contacts
- Priority allocation system
- Crisis inventory management

## Contract Architecture

Each contract operates independently with its own data structures and functions:

- \`supply-ordering.clar\` - Core ordering functionality
- \`expiration-tracking.clar\` - Expiration management
- \`usage-monitoring.clar\` - Consumption tracking
- \`storage-management.clar\` - Storage conditions
- \`emergency-restocking.clar\` - Emergency procedures

## Data Types

### Supply Item
- Item ID (uint)
- Name (string-ascii)
- Category (string-ascii)
- Unit of measure (string-ascii)
- Current quantity (uint)
- Minimum threshold (uint)

### Vendor
- Vendor ID (uint)
- Name (string-ascii)
- Contact information (string-ascii)
- Reliability rating (uint)
- Active status (bool)

### Storage Location
- Location ID (uint)
- Name (string-ascii)
- Temperature range (uint, uint)
- Humidity range (uint, uint)
- Capacity (uint)

## Getting Started

### Prerequisites
- Clarinet CLI
- Node.js and npm
- Stacks wallet for testing

### Installation

1. Clone the repository
2. Install dependencies:
   \`\`\`bash
   npm install
   \`\`\`

3. Run tests:
   \`\`\`bash
   npm test
   \`\`\`

4. Deploy contracts:
   \`\`\`bash
   clarinet deploy
   \`\`\`

## Testing

The system includes comprehensive tests using Vitest:

- Unit tests for each contract function
- Integration tests for workflow scenarios
- Error handling validation
- Edge case coverage

Run tests with:
\`\`\`bash
npm test
\`\`\`

## Usage Examples

### Adding a New Supply Item
\`\`\`clarity
(contract-call? .supply-ordering add-supply-item
"Surgical Masks"
"PPE"
"box"
u100
u20)
\`\`\`

### Registering a Vendor
\`\`\`clarity
(contract-call? .supply-ordering register-vendor
"MedSupply Corp"
"contact@medsupply.com"
u5)
\`\`\`

### Recording Usage
\`\`\`clarity
(contract-call? .usage-monitoring record-usage
u1
u10
"routine-checkup")
\`\`\`

## Security Considerations

- Only authorized clinic staff can modify inventory
- All transactions are logged on-chain
- Multi-signature requirements for large orders
- Audit trail for all supply movements

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License.
