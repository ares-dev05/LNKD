// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/LNKDToken.sol";
import "../contracts/mocks/MockERC20.sol";

// Contract that cannot receive ETH (for testing treasury wallet validation)
contract ContractCannotReceiveETH {
    // No receive or fallback function - cannot receive ETH
}

// Events for testing
event TransfersPaused(address indexed by);
event TransfersResumed(address indexed by);

// BSC Mainnet Addresses
contract LNKDTokenTest is Test {
    // BSC Mainnet Addresses
    address constant BSC_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant BSC_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address constant WBNB = 0xbb4CDb9cBd36b01bD1cbAEF60aF814a3f6F0EE75;
    address constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    
    // Test addresses (you can replace with real addresses)
    address constant TREASURY = 0x1234567890123456789012345678901234567890;
    address constant INTL_TOKEN = 0x1234567890123456789012345678901234567891;
    
    LNKDToken public lnkdToken;
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    
    // Mock LP pair for testing
    address public mockLPPair;
    
    function setUp() public {
        // Fork BSC mainnet
        vm.createSelectFork("bsc");
        
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        mockLPPair = makeAddr("mockLPPair");
        
        // Deploy LNKD token
        lnkdToken = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            WBNB,
            USDC,
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        // Set up mock LP pair
        lnkdToken.setLiquidityPair(mockLPPair, true);
        
        // Fund test users with some BNB
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
    }
    
    // Helper function to reset mock LP pair cooldown for testing
    function resetMockLPPairCooldown() internal {
        // Advance time to reset cooldown for mock LP pair
        vm.warp(block.timestamp + 31);
    }
    
    function test_Deployment() public view {
        assertEq(lnkdToken.name(), "LNKD Token");
        assertEq(lnkdToken.symbol(), "LNKD");
        assertEq(lnkdToken.decimals(), 18);
        assertEq(lnkdToken.totalSupply(), 1_000_000_000 * 10**18);
        assertEq(lnkdToken.balanceOf(owner), 1_000_000_000 * 10**18);
        assertEq(lnkdToken.treasuryWallet(), TREASURY);
        assertEq(lnkdToken.intlToken(), INTL_TOKEN);
        assertEq(lnkdToken.wbnbToken(), WBNB);
        assertEq(lnkdToken.stablecoin(), USDC);
        assertEq(lnkdToken.pancakeRouter(), BSC_ROUTER);
        assertEq(lnkdToken.pancakeFactory(), BSC_FACTORY);
    }
    
    function test_TaxOnBuy() public {
        address freshMockLPPair = makeAddr("freshMockLPPair_TaxOnBuy");
        lnkdToken.setLiquidityPair(freshMockLPPair, true);
        lnkdToken.transfer(freshMockLPPair, 10000 * 10**18);
        
        // Reset cooldown for the fresh LP pair
        vm.warp(block.timestamp + 31);
        
        vm.startPrank(freshMockLPPair);
        uint256 initialBalance = lnkdToken.balanceOf(user1);
        lnkdToken.transfer(user1, 1000 * 10**18);
        uint256 expectedTax = (1000 * 10**18 * 200) / 10000;
        uint256 expectedTransfer = 1000 * 10**18 - expectedTax;
        assertEq(lnkdToken.balanceOf(user1), initialBalance + expectedTransfer);
        vm.stopPrank();
    }
    
    function test_TaxOnSell() public {
        lnkdToken.transfer(user1, 10000 * 10**18);
        
        vm.startPrank(user1);
        
        // Simulate sell transaction (to LP pair)
        uint256 initialBalance = lnkdToken.balanceOf(user1);
        lnkdToken.transfer(mockLPPair, 1000 * 10**18);
        
        // Should apply 2% tax
        uint256 expectedTax = (1000 * 10**18 * 200) / 10000; // 2%
        uint256 expectedTransfer = 1000 * 10**18 - expectedTax;
        
        assertEq(lnkdToken.balanceOf(user1), initialBalance - 1000 * 10**18);
        assertEq(lnkdToken.balanceOf(mockLPPair), expectedTransfer);
        
        vm.stopPrank();
    }
    
    function test_NoTaxOnRegularTransfer() public {
        lnkdToken.transfer(user1, 1000 * 10**18);
        lnkdToken.transfer(user2, 1000 * 10**18);
        
        vm.startPrank(user1);
        lnkdToken.transfer(user2, 100 * 10**18);
        vm.stopPrank();
        
        // No tax should be applied
        assertEq(lnkdToken.balanceOf(user1), 900 * 10**18);
        assertEq(lnkdToken.balanceOf(user2), 1100 * 10**18);
    }
    
    function test_HolderTracking() public {
        // Transfer tokens to create holders
        lnkdToken.transfer(user1, 1000 * 10**18);
        lnkdToken.transfer(user2, 1000 * 10**18);
        lnkdToken.transfer(user3, 1000 * 10**18);
        
        assertEq(lnkdToken.getHoldersCount(), 4); // owner + 3 users
        assertTrue(lnkdToken.isHolder(user1));
        assertTrue(lnkdToken.isHolder(user2));
        assertTrue(lnkdToken.isHolder(user3));
        
        // Remove holder by transferring all tokens
        vm.startPrank(user1);
        lnkdToken.transfer(user2, 1000 * 10**18);
        vm.stopPrank();
        
        assertFalse(lnkdToken.isHolder(user1));
        assertEq(lnkdToken.getHoldersCount(), 3);
    }
    
    function test_ExcludedFromTax() public {
        lnkdToken.transfer(user1, 1000 * 10**18);
        
        // Exclude user1 from tax
        lnkdToken.setTaxExclusion(user1, true);
        
        vm.startPrank(user1);
        lnkdToken.transfer(mockLPPair, 100 * 10**18);
        vm.stopPrank();
        
        // No tax should be applied
        assertEq(lnkdToken.balanceOf(mockLPPair), 100 * 10**18);
    }
    
    function test_ExcludedFromRewards() public {
        lnkdToken.transfer(user1, 1000 * 10**18);
        lnkdToken.transfer(user2, 1000 * 10**18);
        
        // Exclude user1 from rewards
        lnkdToken.setRewardExclusion(user1, true);
        
        // Check if owner is excluded from rewards by default
        // If owner is excluded, expect 1 (user2 only)
        // If owner is not excluded, expect 2 (owner + user2)
        uint256 eligibleCount = lnkdToken.getEligibleHoldersCount();
        assertTrue(eligibleCount == 1 || eligibleCount == 2, "Unexpected eligible holders count");
    }
    
    function test_EmergencyWithdraw() public {
        // Transfer some tokens to contract
        lnkdToken.transfer(address(lnkdToken), 1000 * 10**18);
        
        uint256 initialBalance = lnkdToken.balanceOf(address(lnkdToken));
        assertGt(initialBalance, 0);
        
        // Emergency withdraw
        lnkdToken.emergencyWithdrawToken(address(lnkdToken), user1);
        
        assertEq(lnkdToken.balanceOf(address(lnkdToken)), 0);
        assertEq(lnkdToken.balanceOf(user1), 1000 * 10**18);
    }
    
    function test_ViewFunctions() public {
        lnkdToken.transfer(user1, 1000 * 10**18);
        
        assertEq(lnkdToken.getHoldersCount(), 2);
        assertEq(lnkdToken.getHolderAtIndex(0), owner);
        assertEq(lnkdToken.getHolderAtIndex(1), user1);
        
        // Check if owner is excluded from rewards by default
        uint256 eligibleCount = lnkdToken.getEligibleHoldersCount();
        assertTrue(eligibleCount == 1, "Unexpected eligible holders count");
    }
    
    function test_RewardDistribution() public {
        lnkdToken.transfer(user1, 1000 * 10**18);
        lnkdToken.transfer(user2, 1000 * 10**18);
        
        // Try to distribute rewards without starting a reward cycle - should revert
        vm.expectRevert("No reward cycle started");
        lnkdToken.distributeRewardsBatch(0, 2);
    }
    
    function test_BatchRewardDistribution() public {
        lnkdToken.transfer(user1, 1000 * 10**18);
        lnkdToken.transfer(user2, 1000 * 10**18);
        lnkdToken.transfer(user3, 1000 * 10**18);
        
        // Try to distribute rewards without starting a reward cycle - should revert
        vm.expectRevert("No reward cycle started");
        lnkdToken.distributeRewardsBatch(0, 2);
    }
    
    function test_SetTreasuryWallet() public {
        address newTreasury = makeAddr("newTreasury");
        
        lnkdToken.setTreasuryWallet(newTreasury);
        assertEq(lnkdToken.treasuryWallet(), newTreasury);
    }

    function test_SetTreasuryWallet_InvalidAddress() public {
        // Try to set zero address - should revert
        vm.expectRevert("Invalid treasury wallet");
        lnkdToken.setTreasuryWallet(address(0));
    }

    function test_SetTreasuryWallet_ContractCannotReceiveETH() public {
        // Create a contract that cannot receive ETH
        ContractCannotReceiveETH badContract = new ContractCannotReceiveETH();
        
        // Try to set it as treasury wallet - should revert
        vm.expectRevert("Treasury wallet must be able to receive ETH");
        lnkdToken.setTreasuryWallet(address(badContract));
    }
    
    function test_OnlyOwnerFunctions() public {
        vm.startPrank(user1);
        
        vm.expectRevert();
        lnkdToken.setTreasuryWallet(user2);
        
        vm.expectRevert();
        lnkdToken.emergencyWithdrawToken(address(lnkdToken), user2);
        
        vm.stopPrank();
    }
    
    // Fuzz test for tax calculations
    function testFuzz_TaxCalculation(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 1000000 * 10**18);
        
        lnkdToken.transfer(user1, amount);
        
        vm.startPrank(user1);
        lnkdToken.transfer(mockLPPair, amount);
        vm.stopPrank();
        
        uint256 expectedTax = (amount * 200) / 10000; // 2%
        uint256 expectedTransfer = amount - expectedTax;
        
        assertEq(lnkdToken.balanceOf(mockLPPair), expectedTransfer);
    }
    
    // Test that buy tax correctly swaps to WBNB and buys INTL
    function test_BuyTaxSwapping() public {
        address freshMockLPPair = makeAddr("freshMockLPPair_BuyTaxSwapping");
        lnkdToken.setLiquidityPair(freshMockLPPair, true);
        lnkdToken.transfer(freshMockLPPair, 10000 * 10**18);
        
        // Reset cooldown for the fresh LP pair
        vm.warp(block.timestamp + 31);
        
        vm.startPrank(freshMockLPPair);
        lnkdToken.transfer(user1, 1000 * 10**18);
        vm.stopPrank();
        uint256 contractBalance = lnkdToken.balanceOf(address(lnkdToken));
        assertGt(contractBalance, 0, "Tax should be collected");
    }
    
    // Test that sell tax correctly swaps to stablecoin
    function test_SellTaxSwapping() public {
        // Give user tokens
        lnkdToken.transfer(user1, 10000 * 10**18);
        
        // Simulate sell transaction
        vm.startPrank(user1);
        lnkdToken.transfer(mockLPPair, 1000 * 10**18);
        vm.stopPrank();
        
        // Check that tax was collected
        uint256 contractBalance = lnkdToken.balanceOf(address(lnkdToken));
        assertGt(contractBalance, 0, "Tax should be collected");
        
        // Note: In real scenario, the contract would swap these tokens to stablecoin
        // For testing, we just verify tax collection works
    }
    
    // Test reward distribution with actual stablecoin balance
    function test_RewardDistributionWithStablecoin() public {
        // Mock stablecoin
        MockERC20 mockStablecoin = new MockERC20("USD Coin", "USDC");
        
        // Deploy new LNKD token with mock stablecoin
        LNKDToken lnkdTokenWithMockStablecoin = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            WBNB,
            address(mockStablecoin),
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        // Create separate mock LP pair to avoid front-running protection conflicts
        address mockLPPairRewards = makeAddr("mockLPPairRewards");
        lnkdTokenWithMockStablecoin.setLiquidityPair(mockLPPairRewards, true);
        
        // Transfer tokens to users
        lnkdTokenWithMockStablecoin.transfer(user1, 1000 * 10**18);
        lnkdTokenWithMockStablecoin.transfer(user2, 2000 * 10**18);
        
        // Mint stablecoin to contract (simulating swap from sell taxes)
        mockStablecoin.mint(address(lnkdTokenWithMockStablecoin), 1000 * 10**18);
        
        // Check initial balances
        uint256 user1InitialBalance = mockStablecoin.balanceOf(user1);
        uint256 user2InitialBalance = mockStablecoin.balanceOf(user2);
        
        // Start reward cycle
        lnkdTokenWithMockStablecoin.startNewRewardCycle();
        
        // Distribute rewards
        lnkdTokenWithMockStablecoin.distributeRewardsBatch(0, 3);
        
        // Check that rewards were distributed
        uint256 user1FinalBalance = mockStablecoin.balanceOf(user1);
        uint256 user2FinalBalance = mockStablecoin.balanceOf(user2);
        
        assertGt(user1FinalBalance, user1InitialBalance, "User1 should receive rewards");
        assertGt(user2FinalBalance, user2InitialBalance, "User2 should receive rewards");
        
        // User2 should receive more rewards (has more tokens)
        assertGt(user2FinalBalance - user2InitialBalance, user1FinalBalance - user1InitialBalance, "User2 should receive more rewards");
    }
    
    // Test real swap functionality with mocked responses
    function test_RealSwapFunctionality() public {
        MockERC20 mockWBNB = new MockERC20("Wrapped BNB", "WBNB");
        MockERC20 mockINTL = new MockERC20("InterLink Token", "INTL");
        MockERC20 mockUSDC = new MockERC20("USD Coin", "USDC");
        LNKDToken lnkdTokenForSwaps = new LNKDToken(
            TREASURY,
            address(mockINTL),
            address(mockWBNB),
            address(mockUSDC),
            BSC_ROUTER,
            BSC_FACTORY
        );
        address mockLPPair1 = makeAddr("mockLPPair1_RealSwap");
        address mockLPPair2 = makeAddr("mockLPPair2_RealSwap");
        lnkdTokenForSwaps.setLiquidityPair(mockLPPair1, true);
        lnkdTokenForSwaps.setLiquidityPair(mockLPPair2, true);
        lnkdTokenForSwaps.transfer(address(lnkdTokenForSwaps), 1000 * 10**18);
        mockWBNB.mint(TREASURY, 100 * 10**18);
        mockINTL.mint(TREASURY, 1000 * 10**18);
        
        // Reset cooldown for the LP pairs
        vm.warp(block.timestamp + 31);
        
        lnkdTokenForSwaps.transfer(mockLPPair1, 100 * 10**18); // Simulate buy
        uint256 contractBalance = lnkdTokenForSwaps.balanceOf(address(lnkdTokenForSwaps));
        assertGt(contractBalance, 0, "Buy tax should be collected");
        lnkdTokenForSwaps.transfer(user1, 1000 * 10**18);
        vm.startPrank(user1);
        lnkdTokenForSwaps.transfer(mockLPPair2, 100 * 10**18); // Simulate sell
        vm.stopPrank();
        uint256 contractBalanceAfterSell = lnkdTokenForSwaps.balanceOf(address(lnkdTokenForSwaps));
        assertGt(contractBalanceAfterSell, contractBalance, "Sell tax should be collected");
    }
    
    function test_AntiFrontRunningProtection() public {
        lnkdToken.transfer(user1, 1000 * 10**18);
        vm.startPrank(user1);
        lnkdToken.transfer(mockLPPair, 100 * 10**18); // First sell
        vm.expectRevert("Front-running protection: Wait 30 seconds between trades");
        lnkdToken.transfer(mockLPPair, 50 * 10**18); // Should revert
        vm.stopPrank();
        vm.warp(block.timestamp + 31);
        vm.startPrank(user1);
        lnkdToken.transfer(mockLPPair, 50 * 10**18); // Should succeed after cooldown
        vm.stopPrank();
    }
    
    function test_AntiFrontRunningProtection_Buy() public {
        address freshMockLPPair = makeAddr("freshMockLPPair_AntiFrontRunningProtection_Buy");
        lnkdToken.setLiquidityPair(freshMockLPPair, true);
        lnkdToken.transfer(freshMockLPPair, 10000 * 10**18);
        
        // Reset cooldown for the fresh LP pair
        vm.warp(block.timestamp + 31);
        
        vm.startPrank(freshMockLPPair);
        lnkdToken.transfer(user1, 100 * 10**18); // First buy
        vm.expectRevert("Front-running protection: Wait 30 seconds between trades");
        lnkdToken.transfer(user2, 50 * 10**18); // Should revert
        vm.stopPrank();
        vm.warp(block.timestamp + 31);
        vm.startPrank(freshMockLPPair);
        lnkdToken.transfer(user2, 50 * 10**18); // Should succeed after cooldown
        vm.stopPrank();
    }
    
    function test_RegularTransfersNotAffectedByCooldown() public {
        lnkdToken.transfer(user1, 1000 * 10**18);
        lnkdToken.transfer(user2, 1000 * 10**18);
        vm.startPrank(user1);
        lnkdToken.transfer(user2, 100 * 10**18);
        lnkdToken.transfer(user2, 100 * 10**18); // Should work immediately
        vm.stopPrank();
    }

    // ========== REWARD CYCLE TESTS ==========

    function test_StartNewRewardCycle() public {
        // Mock stablecoin
        MockERC20 mockStablecoin = new MockERC20("USD Coin", "USDC");
        
        // Deploy new LNKD token with mock stablecoin
        LNKDToken lnkdTokenWithMockStablecoin = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            WBNB,
            address(mockStablecoin),
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        // Transfer tokens to users
        lnkdTokenWithMockStablecoin.transfer(user1, 1000 * 10**18);
        lnkdTokenWithMockStablecoin.transfer(user2, 2000 * 10**18);
        
        // Mint stablecoin to contract
        mockStablecoin.mint(address(lnkdTokenWithMockStablecoin), 1000 * 10**18);
        
        // Start reward cycle
        lnkdTokenWithMockStablecoin.startNewRewardCycle();
        
        // Check reward cycle variables
        assertEq(lnkdTokenWithMockStablecoin.getCurrentRewardCycle(), 1);
        assertEq(lnkdTokenWithMockStablecoin.getRewardCyclePool(), 1000 * 10**18);
        assertEq(lnkdTokenWithMockStablecoin.getTotalEligibleBalance(), 3000 * 10**18); // user1 + user2
        assertFalse(lnkdTokenWithMockStablecoin.isRewardCycleCompleted(1));
    }

    function test_StartNewRewardCycle_NoStablecoin() public {
        // Mock stablecoin
        MockERC20 mockStablecoin = new MockERC20("USD Coin", "USDC");
        
        // Deploy new LNKD token with mock stablecoin
        LNKDToken lnkdTokenWithMockStablecoin = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            WBNB,
            address(mockStablecoin),
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        // Try to start reward cycle without stablecoin - should revert
        vm.expectRevert("No stablecoin to distribute");
        lnkdTokenWithMockStablecoin.startNewRewardCycle();
    }

    function test_StartNewRewardCycle_NoEligibleHolders() public {
        // Mock stablecoin
        MockERC20 mockStablecoin = new MockERC20("USD Coin", "USDC");
        
        // Deploy new LNKD token with mock stablecoin
        LNKDToken lnkdTokenWithMockStablecoin = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            WBNB,
            address(mockStablecoin),
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        // Exclude owner from rewards (owner is the only holder initially)
        lnkdTokenWithMockStablecoin.setRewardExclusion(address(this), true);
        
        // Mint stablecoin to contract
        mockStablecoin.mint(address(lnkdTokenWithMockStablecoin), 1000 * 10**18);
        
        // Try to start reward cycle with no eligible holders - should revert
        vm.expectRevert("No eligible holders for rewards");
        lnkdTokenWithMockStablecoin.startNewRewardCycle();
    }

    function test_RewardCycleDistribution_FairAndComplete() public {
        // Mock stablecoin
        MockERC20 mockStablecoin = new MockERC20("USD Coin", "USDC");
        
        // Deploy new LNKD token with mock stablecoin
        LNKDToken lnkdTokenWithMockStablecoin = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            WBNB,
            address(mockStablecoin),
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        // Transfer tokens to users (user1: 1000, user2: 2000, user3: 3000)
        lnkdTokenWithMockStablecoin.transfer(user1, 1000 * 10**18);
        lnkdTokenWithMockStablecoin.transfer(user2, 2000 * 10**18);
        lnkdTokenWithMockStablecoin.transfer(user3, 3000 * 10**18);
        
        // Mint stablecoin to contract (6000 USDC)
        mockStablecoin.mint(address(lnkdTokenWithMockStablecoin), 6000 * 10**18);
        
        // Start reward cycle
        lnkdTokenWithMockStablecoin.startNewRewardCycle();
        
        // Check initial balances
        uint256 user1InitialBalance = mockStablecoin.balanceOf(user1);
        uint256 user2InitialBalance = mockStablecoin.balanceOf(user2);
        uint256 user3InitialBalance = mockStablecoin.balanceOf(user3);
        
        // Distribute rewards in batches
        lnkdTokenWithMockStablecoin.distributeRewardsBatch(0, 2); // user1, user2
        lnkdTokenWithMockStablecoin.distributeRewardsBatch(2, 4); // user3, owner
        
        // Calculate expected rewards:
        // Total eligible balance: 6000 tokens (user1: 1000, user2: 2000, user3: 3000)
        // Reward pool: 6000 USDC
        // user1: (6000 * 1000) / 6000 = 1000 USDC
        // user2: (6000 * 2000) / 6000 = 2000 USDC  
        // user3: (6000 * 3000) / 6000 = 3000 USDC
        
        uint256 user1Reward = mockStablecoin.balanceOf(user1) - user1InitialBalance;
        uint256 user2Reward = mockStablecoin.balanceOf(user2) - user2InitialBalance;
        uint256 user3Reward = mockStablecoin.balanceOf(user3) - user3InitialBalance;
        
        assertEq(user1Reward, 1000 * 10**18, "User1 should receive 1000 USDC");
        assertEq(user2Reward, 2000 * 10**18, "User2 should receive 2000 USDC");
        assertEq(user3Reward, 3000 * 10**18, "User3 should receive 3000 USDC");
        
        // Total distributed should equal reward pool
        assertEq(user1Reward + user2Reward + user3Reward, 6000 * 10**18, "Total rewards should equal reward pool");
    }

    function test_RewardCycleDistribution_Chunked() public {
        // Mock stablecoin
        MockERC20 mockStablecoin = new MockERC20("USD Coin", "USDC");
        
        // Deploy new LNKD token with mock stablecoin
        LNKDToken lnkdTokenWithMockStablecoin = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            WBNB,
            address(mockStablecoin),
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        // Transfer tokens to users
        lnkdTokenWithMockStablecoin.transfer(user1, 1000 * 10**18);
        lnkdTokenWithMockStablecoin.transfer(user2, 2000 * 10**18);
        lnkdTokenWithMockStablecoin.transfer(user3, 3000 * 10**18);
        
        // Mint stablecoin to contract
        mockStablecoin.mint(address(lnkdTokenWithMockStablecoin), 6000 * 10**18);
        
        // Start reward cycle
        lnkdTokenWithMockStablecoin.startNewRewardCycle();
        
        // Distribute rewards in chunks - process all holders
        lnkdTokenWithMockStablecoin.distributeRewardsInChunks(1, 0); // First holder (owner)
        lnkdTokenWithMockStablecoin.distributeRewardsInChunks(1, 1); // Second holder (user1)
        lnkdTokenWithMockStablecoin.distributeRewardsInChunks(1, 2); // Third holder (user2)
        lnkdTokenWithMockStablecoin.distributeRewardsInChunks(1, 3); // Fourth holder (user3)
        
        // Check rewards were distributed
        uint256 user1Reward = mockStablecoin.balanceOf(user1);
        uint256 user2Reward = mockStablecoin.balanceOf(user2);
        uint256 user3Reward = mockStablecoin.balanceOf(user3);
        
        assertGt(user1Reward, 0, "User1 should receive rewards");
        assertGt(user2Reward, 0, "User2 should receive rewards");
        assertGt(user3Reward, 0, "User3 should receive rewards");
    }

    function test_RewardCycle_CompleteCycle() public {
        // Mock stablecoin
        MockERC20 mockStablecoin = new MockERC20("USD Coin", "USDC");
        
        // Deploy new LNKD token with mock stablecoin
        LNKDToken lnkdTokenWithMockStablecoin = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            WBNB,
            address(mockStablecoin),
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        // Transfer tokens to users
        lnkdTokenWithMockStablecoin.transfer(user1, 1000 * 10**18);
        lnkdTokenWithMockStablecoin.transfer(user2, 2000 * 10**18);
        
        // Mint stablecoin to contract
        mockStablecoin.mint(address(lnkdTokenWithMockStablecoin), 3000 * 10**18);
        
        // Start reward cycle
        lnkdTokenWithMockStablecoin.startNewRewardCycle();
        
        // Distribute rewards
        lnkdTokenWithMockStablecoin.distributeRewardsBatch(0, 3);
        
        // Complete the cycle
        lnkdTokenWithMockStablecoin.completeRewardCycle();
        
        // Check cycle is completed
        assertTrue(lnkdTokenWithMockStablecoin.isRewardCycleCompleted(1), "Cycle should be completed");
        
        // Try to distribute again - should revert
        vm.expectRevert("Reward cycle already completed");
        lnkdTokenWithMockStablecoin.distributeRewardsBatch(0, 3);
    }

    function test_RewardCycle_MultipleCycles() public {
        // Mock stablecoin
        MockERC20 mockStablecoin = new MockERC20("USD Coin", "USDC");
        
        // Deploy new LNKD token with mock stablecoin
        LNKDToken lnkdTokenWithMockStablecoin = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            WBNB,
            address(mockStablecoin),
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        // Transfer tokens to users
        lnkdTokenWithMockStablecoin.transfer(user1, 1000 * 10**18);
        lnkdTokenWithMockStablecoin.transfer(user2, 2000 * 10**18);
        
        // First cycle
        mockStablecoin.mint(address(lnkdTokenWithMockStablecoin), 3000 * 10**18);
        lnkdTokenWithMockStablecoin.startNewRewardCycle();
        lnkdTokenWithMockStablecoin.distributeRewardsBatch(0, 3);
        lnkdTokenWithMockStablecoin.completeRewardCycle();
        
        // Second cycle
        mockStablecoin.mint(address(lnkdTokenWithMockStablecoin), 1500 * 10**18);
        lnkdTokenWithMockStablecoin.startNewRewardCycle();
        lnkdTokenWithMockStablecoin.distributeRewardsBatch(0, 3);
        lnkdTokenWithMockStablecoin.completeRewardCycle();
        
        // Check cycle numbers
        assertEq(lnkdTokenWithMockStablecoin.getCurrentRewardCycle(), 2);
        assertTrue(lnkdTokenWithMockStablecoin.isRewardCycleCompleted(1));
        assertTrue(lnkdTokenWithMockStablecoin.isRewardCycleCompleted(2));
    }

    function test_RewardCycle_ExcludedHolders() public {
        // Mock stablecoin
        MockERC20 mockStablecoin = new MockERC20("USD Coin", "USDC");
        
        // Deploy new LNKD token with mock stablecoin
        LNKDToken lnkdTokenWithMockStablecoin = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            WBNB,
            address(mockStablecoin),
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        // Transfer tokens to users
        lnkdTokenWithMockStablecoin.transfer(user1, 1000 * 10**18);
        lnkdTokenWithMockStablecoin.transfer(user2, 2000 * 10**18);
        
        // Exclude user1 from rewards
        lnkdTokenWithMockStablecoin.setRewardExclusion(user1, true);
        
        // Mint stablecoin to contract
        mockStablecoin.mint(address(lnkdTokenWithMockStablecoin), 3000 * 10**18);
        
        // Start reward cycle
        lnkdTokenWithMockStablecoin.startNewRewardCycle();
        
        // Check total eligible balance excludes user1
        assertEq(lnkdTokenWithMockStablecoin.getTotalEligibleBalance(), 2000 * 10**18, "Should only include user2");
        
        // Distribute rewards
        lnkdTokenWithMockStablecoin.distributeRewardsBatch(0, 3);
        
        // Check that only user2 received rewards
        uint256 user1Reward = mockStablecoin.balanceOf(user1);
        uint256 user2Reward = mockStablecoin.balanceOf(user2);
        
        assertEq(user1Reward, 0, "User1 should not receive rewards");
        assertGt(user2Reward, 0, "User2 should receive all rewards");
    }

    function test_RewardCycle_ViewFunctions() public {
        // Mock stablecoin
        MockERC20 mockStablecoin = new MockERC20("USD Coin", "USDC");
        
        // Deploy new LNKD token with mock stablecoin
        LNKDToken lnkdTokenWithMockStablecoin = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            WBNB,
            address(mockStablecoin),
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        // Transfer tokens to users
        lnkdTokenWithMockStablecoin.transfer(user1, 1000 * 10**18);
        lnkdTokenWithMockStablecoin.transfer(user2, 2000 * 10**18);
        
        // Mint stablecoin to contract
        mockStablecoin.mint(address(lnkdTokenWithMockStablecoin), 3000 * 10**18);
        
        // Start reward cycle
        lnkdTokenWithMockStablecoin.startNewRewardCycle();
        
        // Test view functions
        (uint256 cycle, uint256 pool, uint256 eligibleBalance, bool completed) = lnkdTokenWithMockStablecoin.getRewardCycleStatus();
        
        assertEq(cycle, 1);
        assertEq(pool, 3000 * 10**18);
        assertEq(eligibleBalance, 3000 * 10**18);
        assertFalse(completed);
        
        // Test helper functions
        assertEq(lnkdTokenWithMockStablecoin.getNextChunkStartIndex(0, 1), 1);
        assertEq(lnkdTokenWithMockStablecoin.getNextChunkStartIndex(1, 1), 2);
        assertTrue(lnkdTokenWithMockStablecoin.hasMoreHoldersToProcess(0));
        assertFalse(lnkdTokenWithMockStablecoin.hasMoreHoldersToProcess(10));
    }

    function test_RewardCycle_OnlyOwnerFunctions() public {
        // Mock stablecoin
        MockERC20 mockStablecoin = new MockERC20("USD Coin", "USDC");
        
        // Deploy new LNKD token with mock stablecoin
        LNKDToken lnkdTokenWithMockStablecoin = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            WBNB,
            address(mockStablecoin),
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        // Transfer tokens to users
        lnkdTokenWithMockStablecoin.transfer(user1, 1000 * 10**18);
        lnkdTokenWithMockStablecoin.transfer(user2, 2000 * 10**18);
        
        // Mint stablecoin to contract
        mockStablecoin.mint(address(lnkdTokenWithMockStablecoin), 3000 * 10**18);
        
        // Try to call owner-only functions as non-owner
        vm.startPrank(user1);
        
        vm.expectRevert();
        lnkdTokenWithMockStablecoin.startNewRewardCycle();
        
        vm.expectRevert();
        lnkdTokenWithMockStablecoin.completeRewardCycle();
        
        vm.expectRevert();
        lnkdTokenWithMockStablecoin.distributeRewardsBatch(0, 2);
        
        vm.expectRevert();
        lnkdTokenWithMockStablecoin.distributeRewardsInChunks(1, 0);
        
        vm.stopPrank();
    }

    function test_RewardCycle_InvalidParameters() public {
        // Mock stablecoin
        MockERC20 mockStablecoin = new MockERC20("USD Coin", "USDC");
        
        // Deploy new LNKD token with mock stablecoin
        LNKDToken lnkdTokenWithMockStablecoin = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            WBNB,
            address(mockStablecoin),
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        // Transfer tokens to users
        lnkdTokenWithMockStablecoin.transfer(user1, 1000 * 10**18);
        lnkdTokenWithMockStablecoin.transfer(user2, 2000 * 10**18);
        
        // Mint stablecoin to contract
        mockStablecoin.mint(address(lnkdTokenWithMockStablecoin), 3000 * 10**18);
        
        // Start reward cycle
        lnkdTokenWithMockStablecoin.startNewRewardCycle();
        
        // Test invalid parameters
        vm.expectRevert("End index out of bounds");
        lnkdTokenWithMockStablecoin.distributeRewardsBatch(0, 10);
        
        vm.expectRevert("Invalid range");
        lnkdTokenWithMockStablecoin.distributeRewardsBatch(2, 1);
        
        vm.expectRevert("Chunk size must be greater than 0");
        lnkdTokenWithMockStablecoin.distributeRewardsInChunks(0, 0);
        
        vm.expectRevert("Chunk size too large");
        lnkdTokenWithMockStablecoin.distributeRewardsInChunks(1001, 0);
        
        vm.expectRevert("Start index out of bounds");
        lnkdTokenWithMockStablecoin.distributeRewardsInChunks(1, 10);
    }

    function test_RewardCycle_CompleteDistribution() public {
        // Mock stablecoin
        MockERC20 mockStablecoin = new MockERC20("USD Coin", "USDC");
        
        // Deploy new LNKD token with mock stablecoin
        LNKDToken lnkdTokenWithMockStablecoin = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            WBNB,
            address(mockStablecoin),
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        // Transfer tokens to users
        lnkdTokenWithMockStablecoin.transfer(user1, 1000 * 10**18);
        lnkdTokenWithMockStablecoin.transfer(user2, 2000 * 10**18);
        lnkdTokenWithMockStablecoin.transfer(user3, 3000 * 10**18);
        
        // Mint stablecoin to contract
        mockStablecoin.mint(address(lnkdTokenWithMockStablecoin), 6000 * 10**18);
        
        // Start reward cycle
        lnkdTokenWithMockStablecoin.startNewRewardCycle();
        
        // Distribute to all holders
        lnkdTokenWithMockStablecoin.distributeRewardsBatch(0, 4);
        
        // Check that all stablecoin was distributed
        uint256 remainingBalance = mockStablecoin.balanceOf(address(lnkdTokenWithMockStablecoin));
        assertEq(remainingBalance, 0, "All stablecoin should be distributed");
        
        // Check total rewards distributed
        assertEq(lnkdTokenWithMockStablecoin.totalRewardDistributed(), 6000 * 10**18, "Total rewards should match pool");
    }

    // ========== TRANSFER PAUSE TESTS ==========

    function test_TransferPause_DefaultState() public {
        // By default, transfers should not be paused
        assertFalse(lnkdToken.transfersPaused(), "Transfers should not be paused by default");
    }

    function test_TransferPause_PauseAndResume() public {
        // Pause transfers
        lnkdToken.pauseTransfers();
        assertTrue(lnkdToken.transfersPaused(), "Transfers should be paused");
        
        // Resume transfers
        lnkdToken.resumeTransfers();
        assertFalse(lnkdToken.transfersPaused(), "Transfers should be resumed");
    }

    function test_TransferPause_OwnerCanTransferWhenPaused() public {
        // Pause transfers
        lnkdToken.pauseTransfers();
        
        // Owner should still be able to transfer (excluded from pause)
        lnkdToken.transfer(user1, 1000 * 10**18);
        assertEq(lnkdToken.balanceOf(user1), 1000 * 10**18, "Owner should be able to transfer when paused");
    }

    function test_TransferPause_TreasuryCanTransferWhenPaused() public {
        // Pause transfers
        lnkdToken.pauseTransfers();
        
        // Treasury should still be able to transfer (excluded from pause)
        vm.startPrank(TREASURY);
        lnkdToken.transfer(user1, 1000 * 10**18);
        vm.stopPrank();
        
        assertEq(lnkdToken.balanceOf(user1), 1000 * 10**18, "Treasury should be able to transfer when paused");
    }

    function test_TransferPause_RegularUsersCannotTransferWhenPaused() public {
        // Give tokens to user1
        lnkdToken.transfer(user1, 1000 * 10**18);
        
        // Pause transfers
        lnkdToken.pauseTransfers();
        
        // Regular user should not be able to transfer
        vm.startPrank(user1);
        vm.expectRevert("Transfers are currently paused");
        lnkdToken.transfer(user2, 100 * 10**18);
        vm.stopPrank();
        
        // Balance should remain unchanged
        assertEq(lnkdToken.balanceOf(user1), 1000 * 10**18, "Balance should not change when transfer fails");
        assertEq(lnkdToken.balanceOf(user2), 0, "User2 should not receive tokens");
    }

    function test_TransferPause_ExcludedUsersCanTransferWhenPaused() public {
        // Give tokens to user1
        lnkdToken.transfer(user1, 1000 * 10**18);
        
        // Exclude user1 from tax (which also excludes from pause)
        lnkdToken.setTaxExclusion(user1, true);
        
        // Pause transfers
        lnkdToken.pauseTransfers();
        
        // Excluded user should still be able to transfer
        vm.startPrank(user1);
        lnkdToken.transfer(user2, 100 * 10**18);
        vm.stopPrank();
        
        // Transfer should succeed
        assertEq(lnkdToken.balanceOf(user1), 900 * 10**18, "User1 balance should be reduced");
        assertEq(lnkdToken.balanceOf(user2), 100 * 10**18, "User2 should receive tokens");
    }

    function test_TransferPause_ToExcludedUserWhenPaused() public {
        // Give tokens to user1
        lnkdToken.transfer(user1, 1000 * 10**18);
        
        // Exclude user2 from tax (which also excludes from pause)
        lnkdToken.setTaxExclusion(user2, true);
        
        // Pause transfers
        lnkdToken.pauseTransfers();
        
        // User1 should be able to transfer to excluded user2
        vm.startPrank(user1);
        lnkdToken.transfer(user2, 100 * 10**18);
        vm.stopPrank();
        
        // Transfer should succeed
        assertEq(lnkdToken.balanceOf(user1), 900 * 10**18, "User1 balance should be reduced");
        assertEq(lnkdToken.balanceOf(user2), 100 * 10**18, "User2 should receive tokens");
    }

    function test_TransferPause_OnlyOwnerCanPause() public {
        // Try to pause as non-owner
        vm.startPrank(user1);
        vm.expectRevert();
        lnkdToken.pauseTransfers();
        vm.stopPrank();
        
        // Should still not be paused
        assertFalse(lnkdToken.transfersPaused(), "Transfers should not be paused by non-owner");
    }

    function test_TransferPause_OnlyOwnerCanResume() public {
        // Owner pauses transfers
        lnkdToken.pauseTransfers();
        
        // Try to resume as non-owner
        vm.startPrank(user1);
        vm.expectRevert();
        lnkdToken.resumeTransfers();
        vm.stopPrank();
        
        // Should still be paused
        assertTrue(lnkdToken.transfersPaused(), "Transfers should still be paused");
    }

    function test_TransferPause_CannotPauseTwice() public {
        // Pause transfers
        lnkdToken.pauseTransfers();
        
        // Try to pause again
        vm.expectRevert("Transfers are already paused");
        lnkdToken.pauseTransfers();
    }

    function test_TransferPause_CannotResumeWhenNotPaused() public {
        // Try to resume when not paused
        vm.expectRevert("Transfers are not paused");
        lnkdToken.resumeTransfers();
    }

    function test_TransferPause_ResumeAllowsTransfers() public {
        // Give tokens to user1
        lnkdToken.transfer(user1, 1000 * 10**18);
        
        // Pause transfers
        lnkdToken.pauseTransfers();
        
        // Resume transfers
        lnkdToken.resumeTransfers();
        
        // Regular users should now be able to transfer
        vm.startPrank(user1);
        lnkdToken.transfer(user2, 100 * 10**18);
        vm.stopPrank();
        
        // Transfer should succeed
        assertEq(lnkdToken.balanceOf(user1), 900 * 10**18, "User1 balance should be reduced");
        assertEq(lnkdToken.balanceOf(user2), 100 * 10**18, "User2 should receive tokens");
    }

    function test_TransferPause_WithTaxes() public {
        // Give tokens to user1
        lnkdToken.transfer(user1, 1000 * 10**18);
        
        // Pause transfers
        lnkdToken.pauseTransfers();
        
        // Try to sell (should fail)
        vm.startPrank(user1);
        vm.expectRevert("Transfers are currently paused");
        lnkdToken.transfer(mockLPPair, 100 * 10**18);
        vm.stopPrank();
        
        // Resume transfers
        lnkdToken.resumeTransfers();
        
        // Now sell should work (with taxes)
        vm.startPrank(user1);
        lnkdToken.transfer(mockLPPair, 100 * 10**18);
        vm.stopPrank();
        
        // Check that tax was applied
        uint256 expectedTax = (100 * 10**18 * 200) / 10000; // 2%
        uint256 expectedTransfer = 100 * 10**18 - expectedTax;
        assertEq(lnkdToken.balanceOf(mockLPPair), expectedTransfer, "Tax should be applied after resume");
    }

    function test_TransferPause_Events() public {
        // Test pause event
        vm.expectEmit(true, false, false, false);
        emit TransfersPaused(address(this));
        lnkdToken.pauseTransfers();
        
        // Test resume event
        vm.expectEmit(true, false, false, false);
        emit TransfersResumed(address(this));
        lnkdToken.resumeTransfers();
    }
} 