# LNKD Token - Foundry Testing Guide

This guide covers how to test the LNKD token contract using Foundry with BSC mainnet forking for realistic testing scenarios.

## Prerequisites

### 1. Install Foundry

**Windows:**
```bash
# Download from: https://github.com/foundry-rs/foundry/releases/latest
# Run foundry-installer.exe as administrator
```

**Alternative (Git Bash/WSL):**
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Verify Installation
```bash
forge --version
cast --version
anvil --version
```

## Project Structure

```
LNKD/
├── contracts/
│   └── LNKDToken.sol          # Main token contract
├── test/
│   └── LNKDToken.t.sol        # Foundry tests with BSC forking
├── script/
│   └── Deploy.s.sol           # Foundry deployment script
├── foundry.toml               # Foundry configuration
├── remappings.txt             # Dependency remappings
└── .env                       # Environment variables
```

## Configuration

### 1. Environment Variables (.env)
```bash
# Required for deployment
PRIVATE_KEY=your_private_key_here
TREASURY_WALLET=0x1234567890123456789012345678901234567890
INTL_TOKEN=0x1234567890123456789012345678901234567891

# Optional for verification
BSCSCAN_API_KEY=your_bscscan_api_key_here
```

### 2. Foundry Configuration (foundry.toml)
- **BSC Mainnet RPC**: `https://bsc-dataseed1.binance.org/`
- **BSC Testnet RPC**: `https://data-seed-prebsc-1-s1.binance.org:8545/`
- **Fork Block**: `35000000` (recent BSC block)
- **Solc Version**: `0.8.20`
- **Optimizer**: Enabled with 200 runs

## BSC Mainnet Addresses

The tests use real BSC mainnet addresses:

```solidity
// PancakeSwap V2
BSC_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E
BSC_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73

// Tokens
WBNB = 0xbb4CdB9CBd36B01bD1cBaEF60aF814a3f6F0Ee75
USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d
USDT = 0x55d398326f99059fF775485246999027B3197955
```

## Testing with BSC Fork

### 1. Run All Tests
```bash
forge test
```

### 2. Run Tests with Verbose Output
```bash
forge test -vv
```

### 3. Run Specific Test
```bash
forge test --match-test test_Deployment
```

### 4. Run Tests with Gas Reporting
```bash
forge test --gas-report
```

### 5. Run Fuzz Tests
```bash
forge test --match-test testFuzz_TaxCalculation
```

### 6. Run Tests with Coverage
```bash
forge coverage
```

## Test Categories

### 1. Basic Functionality
- ✅ Contract deployment
- ✅ Token metadata (name, symbol, decimals)
- ✅ Total supply and initial distribution

### 2. Trading Controls
- ✅ Trading disabled by default
- ✅ Owner can transfer when trading disabled
- ✅ Trading can be enabled
- ✅ Regular transfers work after enabling

### 3. Tax System
- ✅ 2% tax on buy transactions
- ✅ 2% tax on sell transactions
- ✅ No tax on regular transfers
- ✅ Tax exclusions work correctly

### 4. Holder Tracking
- ✅ New holders added automatically
- ✅ Holders removed when balance becomes 0
- ✅ Excluded addresses not tracked
- ✅ Holder count and indexing

### 5. Reward System
- ✅ Reward exclusions work
- ✅ Manual reward distribution
- ✅ Batch reward distribution
- ✅ Eligible holder counting

### 6. Admin Functions
- ✅ Owner-only functions protected
- ✅ Treasury wallet can be updated
- ✅ Tax and reward exclusions
- ✅ Liquidity pair management
- ✅ Pause/unpause functionality

### 7. Emergency Functions
- ✅ Emergency token withdrawal
- ✅ Emergency BNB withdrawal
- ✅ Only owner can call emergency functions

### 8. Fuzz Testing
- ✅ Tax calculations with random amounts
- ✅ Edge cases and boundary conditions

## Advanced Testing

### 1. Fork Testing with Real Contracts
The tests fork BSC mainnet at block 35000000, providing:
- Real PancakeSwap contracts
- Actual token addresses and balances
- Realistic gas costs and block times
- Network-specific behavior

### 2. Gas Optimization Testing
```bash
# Check gas usage
forge test --gas-report

# Optimize for specific functions
forge test --match-test test_TaxOnBuy --gas-report
```

### 3. Invariant Testing
```bash
# Run invariant tests (if added)
forge test --match-contract InvariantTest
```

## Deployment Testing

### 1. Local Deployment Test
```bash
# Deploy to local Anvil instance
anvil
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### 2. Fork Deployment Test
```bash
# Deploy to forked BSC mainnet
forge script script/Deploy.s.sol --fork-url https://bsc-dataseed1.binance.org/ --broadcast
```

### 3. BSC Testnet Deployment
```bash
# Deploy to BSC testnet
forge script script/Deploy.s.sol --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545/ --broadcast
```

## Debugging

### 1. Verbose Test Output
```bash
forge test -vvv
```

### 2. Debug Specific Test
```bash
forge test --match-test test_TaxOnBuy -vvv
```

### 3. Trace Transactions
```bash
forge test --match-test test_TaxOnBuy --verbosity 4
```

### 4. Check State Changes
```bash
# Use console.log in tests
console.log("Balance:", lnkdToken.balanceOf(user1));
```

## Performance Testing

### 1. Gas Usage Analysis
```bash
forge test --gas-report --match-test test_TaxOnBuy
```

### 2. Batch Processing Limits
```bash
# Test with many holders
forge test --match-test test_BatchRewardDistribution
```

### 3. Memory Usage
```bash
# Monitor during large holder operations
forge test --match-test test_HolderTracking -vv
```

## Security Testing

### 1. Access Control
- ✅ Owner-only functions
- ✅ Proper role checks
- ✅ Emergency function protection

### 2. Reentrancy Protection
- ✅ ReentrancyGuard implementation
- ✅ Safe external calls

### 3. Input Validation
- ✅ Address validation
- ✅ Amount validation
- ✅ Range checks

### 4. Overflow Protection
- ✅ Safe math operations
- ✅ Balance checks

## Continuous Integration

### 1. GitHub Actions Example
```yaml
name: Foundry Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - uses: foundry-rs/foundry-toolchain@v1
      - run: forge test
      - run: forge coverage
```

## Troubleshooting

### Common Issues

1. **Fork RPC Issues**
   ```bash
   # Try different RPC endpoints
   forge test --fork-url https://bsc-dataseed2.binance.org/
   ```

2. **Gas Limit Issues**
   ```bash
   # Increase gas limit
   forge test --gas-limit 30000000
   ```

3. **Memory Issues**
   ```bash
   # Reduce fork depth
   forge test --fork-block-number 35000000
   ```

4. **Dependency Issues**
   ```bash
   # Reinstall dependencies
   forge remappings > remappings.txt
   forge build
   ```

## Next Steps

1. **Run Tests**: `forge test`
2. **Check Coverage**: `forge coverage`
3. **Deploy to Testnet**: Use deployment script
4. **Verify Contract**: Use BSCScan verification
5. **Monitor Performance**: Track gas usage and optimizations

## Support

For issues with:
- **Foundry**: Check [Foundry Book](https://book.getfoundry.sh/)
- **BSC**: Check [BSC Documentation](https://docs.binance.org/)
- **PancakeSwap**: Check [PancakeSwap Docs](https://docs.pancakeswap.finance/) 