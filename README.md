# LNKD Token Contract

A simple, safe, and efficient token contract for the InterLink ecosystem on BSC (Binance Smart Chain). LNKD is designed as a support token that feeds volume, supports INTL (the main token), and rewards engagement.

## 🎯 Overview

LNKD Token is a utility token with the following key features:

- **2% Total Tax** (1% Treasury + 1% Auto-buy INTL on buys, 1% Treasury + 1% Stablecoin on sells)
- **Manual Reward Distribution** - Owner-controlled stablecoin rewards to holders
- **Efficient Holder Tracking** - Optimized for gas efficiency
- **Trading Controls** - Owner can enable/disable trading
- **Emergency Functions** - Safety mechanisms for contract management

## 📋 Contract Features

### Tax System
- **Buy Tax (2%)**: 1% → Treasury (WBNB), 1% → Auto-buy INTL
- **Sell Tax (2%)**: 1% → Treasury (WBNB), 1% → Stablecoin (stored in contract)
- **Exclusions**: Owner, treasury, and contract are excluded from taxes

### Reward Distribution
- Manual trigger function (owner only)
- Automatic distribution to all eligible holders based on LNKD holdings
- No claiming required - rewards sent directly to wallets
- Excludes LP, dead wallets, contracts, owner, and treasury
- **Batch distribution** - Can distribute rewards in chunks to avoid gas limits

### Security Features
- Pausable functionality
- Reentrancy protection
- Owner-only admin functions
- Emergency withdrawal functions
- Trading controls

## 🚀 Quick Start

### Prerequisites
- **Node.js**: Version 18.0.0 or higher (LTS recommended)
- **npm**: Version 8.0.0 or higher
- BSC wallet with BNB for deployment

### System Requirements
```bash
# Check your Node.js version
node --version  # Should be >= 18.0.0

# Check your npm version
npm --version   # Should be >= 8.0.0
```

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd LNKD
```

2. **Install dependencies**
```bash
npm install
```

**Note**: This project uses compatible dependency versions to avoid `legacy-peer-deps` issues. If you encounter any peer dependency warnings, they should be minimal and non-blocking.

3. **Set up environment variables**
```bash
cp env.example .env
```

Edit `.env` file with your configuration:
```env
PRIVATE_KEY=your_private_key_here
BSCSCAN_API_KEY=your_bscscan_api_key_here
INTL_TOKEN_ADDRESS=0x0000000000000000000000000000000000000000
```

4. **Update deployment configuration**
Edit `scripts/deploy.js` and update:
- `treasuryWallet`: Your treasury wallet address
- `intlToken`: INTL token contract address

### Compilation

```bash
npm run compile
```

### Testing

```bash
npm test
```

### Deployment

#### BSC Testnet
```bash
npm run deploy:testnet
```

#### BSC Mainnet
```bash
npm run deploy
```

### Contract Verification

#### BSC Testnet
```bash
npm run verify:testnet
```

#### BSC Mainnet
```bash
npm run verify
```

## 📝 Contract Functions

### Admin Functions (Owner Only)

#### Trading Control
```solidity
function enableTrading() external onlyOwner
```
Enables trading for all users.

#### Treasury Management
```solidity
function setTreasuryWallet(address _treasuryWallet) external onlyOwner
```
Updates the treasury wallet address.

#### Exclusions
```solidity
function setTaxExclusion(address account, bool excluded) external onlyOwner
function setRewardExclusion(address account, bool excluded) external onlyOwner
```
Sets tax and reward exclusions for specific addresses.

#### Liquidity Pairs
```solidity
function setLiquidityPair(address pair, bool isPair) external onlyOwner
```
Marks addresses as liquidity pairs for tax calculation.

#### Emergency Functions
```solidity
function pause() external onlyOwner
function unpause() external onlyOwner
function emergencyWithdrawToken(address token, address to) external onlyOwner
function emergencyWithdrawBNB(address to) external onlyOwner
```

### Reward Distribution

#### Manual Distribution
```solidity
function distributeRewards() external onlyOwner nonReentrant
```
Distributes all stablecoin balance to eligible holders proportionally.

#### Batch Distribution
```solidity
function distributeRewardsBatch(uint256 startIndex, uint256 endIndex) external onlyOwner nonReentrant
```
Distributes rewards to a specific range of holders (for gas optimization).

### View Functions

```solidity
function getStablecoinBalance() external view returns (uint256)
function getWBNBBalance() external view returns (uint256)
function getINTLBalance() external view returns (uint256)
function getHoldersCount() external view returns (uint256)
function getHolderAtIndex(uint256 index) external view returns (address)
function getEligibleHoldersCount() external view returns (uint256)
```

## 🔧 Post-Deployment Setup

1. **Verify Contract on BSCScan**
   - Use the verification script or manually verify

2. **Create Liquidity Pair**
   - Add liquidity on PancakeSwap
   - Note the LP pair address

3. **Configure Liquidity Pairs**
   ```javascript
   await lnkdToken.setLiquidityPair("LP_ADDRESS", true);
   ```

4. **Enable Trading**
   ```javascript
   await lnkdToken.enableTrading();
   ```

5. **Test Functionality**
   - Test buy/sell transactions
   - Test reward distribution
   - Verify tax collection

## 📊 Contract Specifications

| Parameter | Value |
|-----------|-------|
| **Token Name** | LNKD Token |
| **Token Symbol** | LNKD |
| **Decimals** | 18 |
| **Total Supply** | 1,000,000,000 LNKD |
| **Tax Rate** | 2% (200 basis points) |
| **Treasury Tax** | 1% (100 basis points) |
| **Auto-buy Tax** | 1% (100 basis points) |

## 🔒 Security Considerations

- **Owner Privileges**: Owner has significant control over the contract
- **Trading Controls**: Trading can be disabled by owner
- **Emergency Functions**: Owner can pause contract and withdraw funds
- **Tax Exclusions**: Owner and treasury are excluded from taxes
- **Reward Exclusions**: LP, contracts, and dead wallets excluded from rewards

## 🧪 Testing

The contract includes comprehensive tests covering:
- Deployment and initialization
- Trading controls
- Tax system
- Holder tracking
- Admin functions
- Emergency functions
- Reward distribution
- Batch distribution

Run tests with:
```bash
npm test
```

## 📁 Project Structure

```
LNKD/
├── contracts/
│   ├── LNKDToken.sol          # Main token contract
│   └── mocks/                 # Mock contracts for testing
│       ├── MockERC20.sol
│       ├── MockPancakeRouter.sol
│       └── MockPancakeFactory.sol
├── scripts/
│   ├── deploy.js              # Deployment script
│   ├── setup.js               # Post-deployment setup
│   └── verify.js              # Contract verification
├── test/
│   └── LNKDToken.test.js      # Test suite
├── hardhat.config.js          # Hardhat configuration
├── package.json               # Dependencies
├── env.example               # Environment variables template
└── README.md                 # This file
```

## 🌐 Network Addresses

### BSC Mainnet
- **WBNB**: `0xbb4CdB9CBd36B01bD1cBaEF60aF1789F6e9E0B9B`
- **USDC**: `0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d`
- **USDT**: `0x55d398326f99059fF775485246999027B3197955`
- **PancakeSwap Router**: `0x10ED43C718714eb63d5aA57B78B54704E256024E`
- **PancakeSwap Factory**: `0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73`

### BSC Testnet
- **WBNB**: `0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd`
- **USDC**: `0x64544969ed7EBf5f083679233325356EbE738930`
- **USDT**: `0x337610d27c682E347C9cD60BD4b3b107C9d34dDd`
- **PancakeSwap Router**: `0xD99D1c33F9fC3444f8101754aBC46c52416550D1`
- **PancakeSwap Factory**: `0x6725F303b657a9451d8BA641348b6761A6CC7a17`

## ⚠️ Important Notes

1. **Node.js Version**: Use Node.js 18.0.0 or higher to avoid compatibility issues
2. **Update Configuration**: Always update treasury wallet and INTL token addresses before deployment
3. **Test Thoroughly**: Test on testnet before mainnet deployment
4. **Gas Optimization**: Use batch distribution for large holder lists
5. **Security**: Keep private keys secure and use hardware wallets for mainnet
6. **Liquidity**: Ensure sufficient liquidity before enabling trading

## 🤝 Support

For questions or support, please refer to the InterLink ecosystem documentation or contact the development team.

## 📄 License

This project is licensed under the MIT License.

---

**Disclaimer**: This contract is provided as-is. Users should conduct their own research and testing before deployment. The developers are not responsible for any financial losses.