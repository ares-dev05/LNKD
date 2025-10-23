# LNKD Token Distribution - Simple Step-by-Step Guide

## What You Need Before Starting
- Your MetaMask wallet connected to Binance Smart Chain
- Some BNB tokens in your wallet (for transaction fees)
- LNKD Token contract address: `0x6692Fa6ea41C5D300fED14B4c0087Cb45E982E48`
- Automation contract address: `0x358822ac989c532790497B3487aa862be5de657C`

## Where to Go and What to Do

### Step 1: Withdraw LNKD Tokens from LNKD Contract
1. **Go to:** https://bscscan.com/address/0x6692Fa6ea41C5D300fED14B4c0087Cb45E982E48#writeContract
2. **Connect your wallet** by clicking "Connect to Web3" and selecting MetaMask
3. **Find the function "emergencyWithdrawToken"** in the list
4. **Click "Write"** next to the emergencyWithdrawToken function
5. **Fill in the two boxes:**
   - **token:** `0x6692Fa6ea41C5D300fED14B4c0087Cb45E982E48`
   - **to:** `0x358822ac989c532790497B3487aa862be5de657C`
6. **Click "Write"** button to execute
7. **Confirm in MetaMask** when it pops up
8. **Wait for the transaction to complete**

### Step 2: Go to Automation Contract
1. **Go to:** https://bscscan.com/address/0x358822ac989c532790497B3487aa862be5de657C#writeContract
2. **Make sure your wallet is still connected**
3. **You should see the automation contract page** with different functions

### Step 3: Start Distribution
1. **On the automation contract page**, find the function called **"startNewRewardDistribution"**
2. **Click "Write"** next to it
3. **Click "Write"** button to execute
4. **Confirm in MetaMask**
5. **Wait for completion**

### Step 4: Check How Many Holders You Have
1. **Go back to:** https://bscscan.com/address/0x6692Fa6ea41C5D300fED14B4c0087Cb45E982E48#readContract
2. **Find the function "getHoldersCount"**
3. **Click "Read"** next to it
4. **Write down the number** that appears (this tells you how many people hold your tokens)

### Step 5: Distribute Rewards in Small Groups
This is the most important step. You'll do this many times.

**For each group:**
1. **Go back to the automation contract:** https://bscscan.com/address/0x358822ac989c532790497B3487aa862be5de657C#writeContract
2. **Find the function "distributeRewardsBatch"**
3. **Click "Write"** next to it
4. **You'll see two boxes to fill:**
   - **startIndex:** Put the starting number (like 0, 30, 60, etc.)
   - **endIndex:** Put the ending number (like 30, 60, 90, etc.)
5. **Click "Write"** button
6. **Confirm in MetaMask**
7. **Wait for completion**
8. **Repeat with the next group**

**Example of what to put in the boxes:**
- First time: startIndex = 0, endIndex = 30
- Second time: startIndex = 30, endIndex = 60  
- Third time: startIndex = 60, endIndex = 90
- Keep going until you've covered all holders

### Step 6: Complete the Distribution
1. **On the automation contract page**, find the function "completeRewardDistribution"
2. **Click "Write"** next to it
3. **Click "Write"** button
4. **Confirm in MetaMask**
5. **Wait for completion**

## What You'll See on BSCScan

### The Contract Page Looks Like This:
- **At the top:** Contract address and basic info
- **Tabs:** Overview, Transactions, Contract, etc.
- **Contract tab:** Shows all the functions you can use
- **Functions list:** Each function has "Read" or "Write" buttons

### When You Click "Write":
- **A popup appears** asking you to connect your wallet
- **MetaMask opens** asking you to confirm
- **You see a gas fee** (cost in BNB)
- **You click "Confirm"** to proceed
- **You wait** for the transaction to complete

## Important Things to Remember

### Before You Start:
- **Have at least 0.1 BNB** in your wallet for gas fees
- **Write down your contract addresses** on a piece of paper
- **Make sure you're on Binance Smart Chain** in MetaMask
- **Test with a small amount first** if possible

### During the Process:
- **Wait for each transaction to finish** before starting the next one
- **Write down which groups you've done** (like "Done: 0-30, 30-60, 60-90")
- **If something fails, try again** with a smaller group
- **Don't rush** - take your time

### If Something Goes Wrong:
- **"Out of gas" error:** Use smaller groups (try 10-20 holders instead of 30)
- **"Transaction failed":** Wait 5 minutes and try again
- **"Front-running protection":** Wait 1 minute between transactions
- **Can't find the function:** Make sure you're on the right contract page

## How Much This Will Cost

### Gas Fees (Transaction Costs):
- **Each transaction costs BNB** (like paying for postage)
- **Small groups cost less** than big groups
- **Total cost:** Usually 0.01 to 0.1 BNB (about $3-30 USD)
- **Keep extra BNB** in your wallet just in case

### Transaction Speed:
- **Each transaction completes immediately** or fails
- **No waiting time** - transactions are instant on blockchain
- **If it works:** You see "Success" immediately
- **If it fails:** You get an error message right away

## Step-by-Step Example

Let's say you have 300 holders:

1. **Withdraw tokens:** 1 transaction
2. **Start distribution:** 1 transaction  
3. **Distribute in groups:**
   - Group 1: startIndex = 0, endIndex = 30 (holders 0-29)
   - Group 2: startIndex = 30, endIndex = 60 (holders 30-59)
   - Group 3: startIndex = 60, endIndex = 90 (holders 60-89)
   - Continue until you reach 300...
   - Group 10: startIndex = 270, endIndex = 300 (holders 270-299)
4. **Complete distribution:** 1 transaction

**Total:** About 12 transactions (each completes immediately)

## What to Do If You Get Stuck

### Problem: Can't find the functions
**Solution:** Make sure you're on the automation contract page (0x358822ac989c532790497B3487aa862be5de657C), not the LNKD Token contract

### Problem: MetaMask won't connect
**Solution:** Refresh the page and try again, make sure you're on BSC network

### Problem: Transaction keeps failing
**Solution:** Try smaller groups (10-20 holders instead of 30)

### Problem: Gas fees are too high
**Solution:** Wait a few hours and try again when gas prices are lower

### Problem: You're not sure if it worked
**Solution:** Check the transaction on BSCScan - if it shows "Success", it worked

## Final Checklist

**Before starting:**
- [ ] I have my contract addresses written down
- [ ] I have at least 0.1 BNB in my wallet
- [ ] I'm connected to Binance Smart Chain
- [ ] I understand this will take many transactions

**During the process:**
- [ ] I'm writing down which groups I've completed
- [ ] I'm waiting for each transaction to finish
- [ ] I'm not rushing or panicking
- [ ] I'm keeping track of my progress

**After finishing:**
- [ ] I completed all the groups
- [ ] I ran the "completeRewardDistribution" function
- [ ] I saved all the transaction IDs
- [ ] I'm ready for the next distribution

## Remember

- **This is normal** - It takes time and many transactions
- **Don't panic** - Most problems can be fixed
- **Take breaks** - You don't have to do it all at once
- **Ask for help** - If you get really stuck, ask someone technical
- **Keep records** - Write down everything you do

**Good luck! You can do this!**
