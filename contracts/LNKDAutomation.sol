// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LNKDToken.sol";

contract LNKDAutomation is Ownable, ReentrancyGuard {
    
    LNKDToken public lnkdToken;
    uint256 public lastDistributionTime;
    uint256 public distributionInterval = 24 hours;
    uint256 public minRewardThreshold = 100 * 10**18; // 100 USDT
    
    event DistributionExecuted(uint256 timestamp, uint256 stablecoinBalance);
    event OwnershipReturned(address indexed previousOwner, address indexed newOwner);
    event DistributionIntervalUpdated(uint256 oldInterval, uint256 newInterval);
    event MinRewardThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
    
    constructor(address _lnkdToken) {
        require(_lnkdToken != address(0), "Invalid LNKD token address");
        lnkdToken = LNKDToken(_lnkdToken);
        lastDistributionTime = block.timestamp;
    }
    
    // Main function to be called by web3 cron job
    function executeDistribution() external nonReentrant {
        // Check if enough time has passed
        require((block.timestamp - lastDistributionTime) >= distributionInterval, "Distribution interval not met");
        
        // Check if there are sufficient rewards
        uint256 stablecoinBalance = lnkdToken.getStablecoinBalance();
        require(stablecoinBalance >= minRewardThreshold, "Insufficient rewards");
        
        // Check if current cycle is ready
        uint256 currentCycle = lnkdToken.getCurrentRewardCycle();
        require(currentCycle == 0 || lnkdToken.isRewardCycleCompleted(currentCycle), "Reward cycle in progress");
        
        // Check if there are eligible holders
        uint256 eligibleHolders = lnkdToken.getEligibleHoldersCount();
        require(eligibleHolders > 0, "No eligible holders");
        
        // Start new reward cycle
        lnkdToken.startNewRewardCycle();
        
        // Distribute rewards in batches
        uint256 totalHolders = lnkdToken.getHoldersCount();
        uint256 chunkSize = 50;
        
        for (uint256 startIndex = 0; startIndex < totalHolders; startIndex += chunkSize) {
            uint256 endIndex = startIndex + chunkSize > totalHolders ? totalHolders : startIndex + chunkSize;
            lnkdToken.distributeRewardsBatch(startIndex, endIndex);
        }
        
        // Complete the reward cycle
        lnkdToken.completeRewardCycle();
        lastDistributionTime = block.timestamp;
        
        emit DistributionExecuted(block.timestamp, stablecoinBalance);
    }
    

    
    // Check if distribution can be executed (for web3 to check before calling)
    function canExecuteDistribution() external view returns (bool) {
        bool timeElapsed = (block.timestamp - lastDistributionTime) >= distributionInterval;
        uint256 stablecoinBalance = lnkdToken.getStablecoinBalance();
        bool hasRewards = stablecoinBalance >= minRewardThreshold;
        uint256 currentCycle = lnkdToken.getCurrentRewardCycle();
        bool cycleReady = currentCycle == 0 || lnkdToken.isRewardCycleCompleted(currentCycle);
        uint256 eligibleHolders = lnkdToken.getEligibleHoldersCount();
        bool hasHolders = eligibleHolders > 0;
        
        return timeElapsed && hasRewards && cycleReady && hasHolders;
    }
    
    // Return LNKD ownership to client
    function returnLNKDOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        lnkdToken.transferOwnership(newOwner);
        emit OwnershipReturned(owner(), newOwner);
    }
    
        // Configuration functions
    function setDistributionInterval(uint256 newInterval) external onlyOwner {
        require(newInterval >= 1 hours, "Interval too short");
        require(newInterval <= 7 days, "Interval too long");
        uint256 oldInterval = distributionInterval;
        distributionInterval = newInterval;
        emit DistributionIntervalUpdated(oldInterval, newInterval);
    }

    function setMinRewardThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "Threshold must be greater than 0");
        require(newThreshold <= 10000 * 10**18, "Threshold too high (max 10,000 USDT)");
        uint256 oldThreshold = minRewardThreshold;
        minRewardThreshold = newThreshold;
        emit MinRewardThresholdUpdated(oldThreshold, newThreshold);
    }
    
    // Emergency functions
    function emergencyWithdrawToken(address token, address to) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        IERC20(token).transfer(to, balance);
    }
    
    function emergencyWithdrawBNB(address to) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        uint256 balance = address(this).balance;
        require(balance > 0, "No BNB to withdraw");
        payable(to).transfer(balance);
    }
    
    receive() external payable {}
}