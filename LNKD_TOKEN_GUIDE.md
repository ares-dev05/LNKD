# LNKD Token - Complete Mechanics Guide

## 🎯 Overview

LNKD is a revolutionary token that automatically generates USDT rewards for holders while building the INTL ecosystem through automatic token purchases. This guide explains how all the mechanics work.

---

## 💰 Tax System (2% Total)

### **Buy Tax (2%):**
- **1% → Treasury** (converted to WBNB)
- **1% → Auto-buy INTL** (converted to INTL tokens)

### **Sell Tax (2%):**
- **1% → Treasury** (converted to WBNB)  
- **1% → USDT Rewards** (stored in contract for distribution)

---

## 🎁 USDT Rewards System

### **How Rewards Are Generated:**
1. **Every sell transaction** contributes 1% to USDT reward pool
2. **LNKD → WBNB → USDT** conversion happens automatically
3. **USDT accumulates** in the contract over time
4. **Available for distribution** to all token holders

### **Reward Distribution Process:**
```
Step 1: startNewRewardCycle() 
- Snapshot current USDT balance
- Calculate total eligible holder balance

Step 2: distributeRewardsInChunks() 
- Send USDT to holders proportionally
- Process in batches to avoid gas limits

Step 3: completeRewardCycle() 
- Mark cycle as complete
- Reset for next distribution
```

### **How Holders Get Rewards:**
- **Proportional to token balance** (more tokens = more rewards)
- **Automatic calculation** based on holder's % of total supply
- **USDT sent directly** to holder's wallet
- **No manual claiming** required

### **Example Reward Distribution:**
If contract has 1000 USDT and 3 holders:
- **Holder A:** 1000 LNKD (50% of total) → Gets 500 USDT
- **Holder B:** 600 LNKD (30% of total) → Gets 300 USDT  
- **Holder C:** 400 LNKD (20% of total) → Gets 200 USDT

---

## 🔄 Auto-Buy INTL System

### **How It Works:**
1. **1% of buy tax** automatically swaps LNKD → WBNB → INTL
2. **INTL tokens sent** directly to treasury wallet
3. **Happens instantly** on every buy transaction
4. **Builds INTL ecosystem** automatically

### **Benefits:**
- **Automatic ecosystem growth**
- **Treasury funding** for development
- **Cross-token utility** between LNKD and INTL

---

## 📊 Transaction Flow Examples

### **Buy Transaction (1000 LNKD):**
1. **1000 LNKD** transferred to buyer
2. **20 LNKD** (2% tax) sent to contract
3. **10 LNKD** → WBNB → INTL (sent to treasury)
4. **10 LNKD** → WBNB (sent to treasury)

### **Sell Transaction (1000 LNKD):**
1. **980 LNKD** transferred to seller (2% tax applied)
2. **20 LNKD** (2% tax) sent to contract
3. **10 LNKD** → WBNB → USDT (stored for rewards)
4. **10 LNKD** → WBNB (sent to treasury)

---

## 🛡️ Security Features

### **Anti-Front-Running Protection:**
- **30-second cooldown** between trades per wallet
- **Prevents rapid buy/sell** manipulation
- **Excluded addresses** (owner, treasury) can trade freely
- **Protects against** MEV attacks

### **Holder Tracking:**
- **Automatic tracking** of all token holders
- **Real-time updates** when balances change
- **Efficient reward distribution** to active holders only
- **Gas-optimized** batch processing

### **Emergency Functions:**
- **Emergency withdraw** for stuck tokens
- **Owner-only functions** for security
- **BNB emergency withdraw** capability
- **Token emergency withdraw** capability

---

## 🎯 Technical Specifications

### **Token Details:**
- **Name:** LNKD Token
- **Symbol:** LNKD
- **Decimals:** 18
- **Total Supply:** 1,000,000,000 LNKD
- **Network:** BNB Chain (BSC)

### **Tax Rates:**
- **Buy Tax:** 2% (200 basis points)
- **Sell Tax:** 2% (200 basis points)
- **Treasury Tax:** 1% (100 basis points)
- **Auto-Buy Tax:** 1% (100 basis points)

### **Constants:**
- **Front-Running Cooldown:** 30 seconds
- **Tax Percentage:** 200 basis points (2%)
- **Treasury Tax:** 100 basis points (1%)
- **Auto-Buy Tax:** 100 basis points (1%)

---

## 🚀 Post-Launch Management

### **Owner Responsibilities:**
1. **Set LP addresses** after PancakeSwap listing
2. **Monitor reward distributions** 
3. **Manage treasury funds**
4. **Handle emergency situations**
5. **Update exclusions** as needed

### **Key Functions for Owners:**
```solidity
// Set liquidity pair
setLiquidityPair(address pair, bool isPair)

// Start reward distribution
startNewRewardCycle()

// Distribute rewards in chunks
distributeRewardsInChunks(uint256 chunkSize, uint256 startIndex)

// Complete reward cycle
completeRewardCycle()

// Emergency functions
emergencyWithdrawToken(address token, address to)
emergencyWithdrawBNB(address to)
```

---

## 💡 Benefits for Investors

### **Passive Income:**
- **Earn USDT** just by holding LNKD
- **Automatic distribution** - no manual claiming
- **Proportional rewards** based on holdings
- **Compound earnings** over time

### **Ecosystem Growth:**
- **Auto-buy INTL** builds the ecosystem
- **Treasury funding** for development
- **Liquidity generation** through trading
- **Cross-token utility** benefits

### **Security & Transparency:**
- **Anti-front-running** protection
- **Emergency controls** available
- **Transparent tax system**
- **No hidden fees** or surprises

---

## 🔧 Automation Options

### **Current System (Manual):**
- **Manual reward distribution** by owner
- **Batch processing** to handle gas limits
- **Flexible timing** and control

### **Web3 Automation (Recommended):**
- **Cron job automation** on web server
- **Automatic distribution** on schedule
- **Same token address** (no migration needed)
- **Cost-effective** solution

### **Chainlink Automation (Future):**
- **Decentralized automation** network
- **Built into smart contract**
- **Requires new contract** deployment
- **Higher cost** but more decentralized

---

## 📈 Trading Mechanics

### **Buy Process:**
1. **User sends BNB** to PancakeSwap
2. **PancakeSwap swaps** BNB → LNKD
3. **2% tax applied** automatically
4. **1% → Treasury** (WBNB)
5. **1% → Auto-buy INTL** (INTL tokens)
6. **Remaining tokens** sent to buyer

### **Sell Process:**
1. **User sends LNKD** to PancakeSwap
2. **2% tax applied** automatically
3. **1% → Treasury** (WBNB)
4. **1% → USDT Rewards** (stored in contract)
5. **PancakeSwap swaps** LNKD → BNB
6. **BNB sent** to seller

### **Regular Transfer:**
- **No tax applied** on regular transfers
- **Only taxed** on buy/sell transactions
- **Excluded addresses** never pay tax

---

## 🎯 Excluded Addresses

### **Tax Exclusions:**
- **Owner wallet** (deployer)
- **Treasury wallet**
- **Contract address**
- **Custom exclusions** (set by owner)

### **Reward Exclusions:**
- **Dead wallet** (0x0000...)
- **Contract address**
- **Owner wallet**
- **Treasury wallet**
- **Custom exclusions** (set by owner)

---

## 📊 Monitoring & Analytics

### **Key Metrics to Track:**
- **Total reward distributed**
- **Number of holders**
- **USDT balance** in contract
- **INTL tokens** in treasury
- **Trading volume**
- **Tax collection** amounts

### **View Functions:**
```solidity
// Get contract balances
getStablecoinBalance()
getWBNBBalance()
getINTLBalance()

// Get holder information
getHoldersCount()
getHolderAtIndex(uint256 index)
getEligibleHoldersCount()

// Get reward cycle status
getCurrentRewardCycle()
getRewardCyclePool()
getTotalEligibleBalance()
isRewardCycleCompleted(uint256 cycleNumber)
```

---

## 🚨 Important Notes

### **For Investors:**
- **Hold tokens** to earn USDT rewards
- **No manual claiming** required
- **Rewards distributed** proportionally
- **Anti-front-running** protects your trades

### **For Owners:**
- **Monitor distributions** regularly
- **Set LP addresses** after launch
- **Manage treasury** funds wisely
- **Test emergency functions** before launch

### **For Developers:**
- **Gas optimization** for batch processing
- **Error handling** for failed swaps
- **Monitoring** for unusual activity
- **Backup plans** for emergencies

---

## 🎉 Conclusion

LNKD creates a self-sustaining ecosystem where:
- **Trading activity** generates USDT rewards
- **Automatic INTL purchases** build the ecosystem
- **Holders earn passive income** just by holding
- **Security features** protect against manipulation
- **Transparent mechanics** build trust

**This system rewards long-term holders while automatically growing the broader INTL ecosystem!** 🚀 