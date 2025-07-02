// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPancakeRouter02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
contract LNKDToken is ERC20, Ownable, ReentrancyGuard {
    // Token Info
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens
    uint256 public constant TAX_PERCENTAGE = 200; // 2% (200 basis points)
    uint256 public constant TREASURY_TAX = 100; // 1% (100 basis points)
    uint256 public constant AUTO_BUY_TAX = 100; // 1% (100 basis points)
    
    // Addresses
    address public treasuryWallet;
    address public intlToken;
    address public wbnbToken;
    address public stablecoin; // USDC or USDT
    address public pancakeRouter;
    address public pancakeFactory;
    
    // State variables
    mapping(address => bool) public isExcludedFromTax;
    mapping(address => bool) public isExcludedFromRewards;
    mapping(address => bool) public isLiquidityPair;
    
    // Reward distribution
    uint256 public totalRewardDistributed;
    mapping(address => uint256) public totalRewardsReceived;
    mapping(address => uint256) public lastProcessedIndex;
    
    // Holder tracking for rewards
    address[] public holders;
    mapping(address => uint256) public holderIndex;
    mapping(address => bool) public isHolder;
    
    // Events
    event TreasuryWalletUpdated(address indexed oldWallet, address indexed newWallet);
    event TaxExclusionUpdated(address indexed account, bool excluded);
    event RewardExclusionUpdated(address indexed account, bool excluded);
    event LiquidityPairUpdated(address indexed pair, bool isPair);
    event RewardsDistributed(uint256 totalAmount, uint256 totalHolders);
    event AutoBuyINTL(uint256 lnkdAmount, uint256 intlReceived);
    event TreasuryTaxCollected(uint256 amount);
    event HolderAdded(address indexed holder);
    event HolderRemoved(address indexed holder);
    
    constructor(
        address _treasuryWallet,
        address _intlToken,
        address _wbnbToken,
        address _stablecoin,
        address _pancakeRouter,
        address _pancakeFactory
    ) ERC20("LNKD Token", "LNKD") {
        require(_treasuryWallet != address(0), "Invalid treasury wallet");
        require(_intlToken != address(0), "Invalid INTL token");
        require(_wbnbToken != address(0), "Invalid WBNB token");
        require(_stablecoin != address(0), "Invalid stablecoin");
        require(_pancakeRouter != address(0), "Invalid router");
        require(_pancakeFactory != address(0), "Invalid factory");
        
        treasuryWallet = _treasuryWallet;
        intlToken = _intlToken;
        wbnbToken = _wbnbToken;
        stablecoin = _stablecoin;
        pancakeRouter = _pancakeRouter;
        pancakeFactory = _pancakeFactory;
        
        // Exclude owner and treasury from taxes
        isExcludedFromTax[owner()] = true;
        isExcludedFromTax[treasuryWallet] = true;
        isExcludedFromTax[address(this)] = true;
        
        // Exclude from rewards
        isExcludedFromRewards[address(0)] = true; // Dead wallet
        isExcludedFromRewards[address(this)] = true; // Contract
        isExcludedFromRewards[owner()] = true; // Owner
        isExcludedFromRewards[treasuryWallet] = true; // Treasury
        
        // Mint total supply to owner
        _mint(owner(), TOTAL_SUPPLY);
        
        // Add owner to holders list
        _addHolder(owner());
    }
    
    // Override transfer function to implement taxes
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        // Update holder tracking
        _updateHolderTracking(from, to, amount);
        
        // Apply taxes only for buy/sell transactions and if not excluded
        if (!isExcludedFromTax[from] && !isExcludedFromTax[to]) {
            // Handle buy transaction (from liquidity pair)
            if (isLiquidityPair[from]) {
                uint256 taxAmount = (amount * TAX_PERCENTAGE) / 10000;
                uint256 transferAmount = amount - taxAmount;
                
                // Transfer tax to contract first
                super._transfer(from, address(this), taxAmount);
                _handleBuyTax(taxAmount);
                super._transfer(from, to, transferAmount);
            }
            // Handle sell transaction (to liquidity pair)
            else if (isLiquidityPair[to]) {
                uint256 taxAmount = (amount * TAX_PERCENTAGE) / 10000;
                uint256 transferAmount = amount - taxAmount;
                
                // Transfer tax to contract first
                super._transfer(from, address(this), taxAmount);
                _handleSellTax(taxAmount);
                super._transfer(from, to, transferAmount);
            }
            // Regular transfer - no tax
            else {
                super._transfer(from, to, amount);
            }
        } else {
            super._transfer(from, to, amount);
        }
    }
    
    function _updateHolderTracking(address from, address to, uint256 amount) internal {
        // Remove from holder list if balance becomes 0
        if (from != address(0) && balanceOf(from) == amount && !isExcludedFromRewards[from]) {
            _removeHolder(from);
        }
        
        // Add to holder list if balance becomes > 0
        if (to != address(0) && balanceOf(to) == 0 && amount > 0 && !isExcludedFromRewards[to]) {
            _addHolder(to);
        }
    }
    
    function _addHolder(address holder) internal {
        if (!isHolder[holder]) {
            isHolder[holder] = true;
            holderIndex[holder] = holders.length;
            holders.push(holder);
            emit HolderAdded(holder);
        }
    }
    
    function _removeHolder(address holder) internal {
        if (isHolder[holder]) {
            uint256 index = holderIndex[holder];
            uint256 lastIndex = holders.length - 1;
            
            if (index != lastIndex) {
                address lastHolder = holders[lastIndex];
                holders[index] = lastHolder;
                holderIndex[lastHolder] = index;
            }
            
            holders.pop();
            delete isHolder[holder];
            delete holderIndex[holder];
            emit HolderRemoved(holder);
        }
    }
    
    function _handleBuyTax(uint256 taxAmount) internal {
        uint256 treasuryTax = (taxAmount * TREASURY_TAX) / TAX_PERCENTAGE;
        uint256 autoBuyTax = taxAmount - treasuryTax;
        
        // Send treasury tax as WBNB
        if (treasuryTax > 0) {
            _swapTokensForWBNB(treasuryTax, treasuryWallet);
            emit TreasuryTaxCollected(treasuryTax);
        }
        
        // Auto-buy INTL with remaining tax
        if (autoBuyTax > 0) {
            _autoBuyINTL(autoBuyTax);
        }
    }
    
    function _handleSellTax(uint256 taxAmount) internal {
        uint256 treasuryTax = (taxAmount * TREASURY_TAX) / TAX_PERCENTAGE;
        uint256 stablecoinTax = taxAmount - treasuryTax;
        
        // Send treasury tax as WBNB
        if (treasuryTax > 0) {
            _swapTokensForWBNB(treasuryTax, treasuryWallet);
            emit TreasuryTaxCollected(treasuryTax);
        }
        
        // Convert to stablecoin and store in contract
        if (stablecoinTax > 0) {
            _swapTokensForStablecoin(stablecoinTax);
        }
    }
    
    function _swapTokensForWBNB(uint256 tokenAmount, address recipient) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = wbnbToken;
        
        _approve(address(this), pancakeRouter, tokenAmount);
        
        try IPancakeRouter02(pancakeRouter).swapExactTokensForTokens(
            tokenAmount,
            0, // Accept any amount of WBNB
            path,
            recipient,
            block.timestamp + 300
        ) {
            // Swap successful
        } catch {
            // If swap fails, just transfer tokens to treasury
            super._transfer(address(this), recipient, tokenAmount);
        }
    }
    
    function _swapTokensForStablecoin(uint256 tokenAmount) internal {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = wbnbToken;
        path[2] = stablecoin;
        
        _approve(address(this), pancakeRouter, tokenAmount);
        
        try IPancakeRouter02(pancakeRouter).swapExactTokensForTokens(
            tokenAmount,
            0, // Accept any amount of stablecoin
            path,
            address(this),
            block.timestamp + 300
        ) {
            // Swap successful, stablecoin stored in contract
        } catch {
            // If swap fails, just keep tokens in contract
        }
    }
    
    function _autoBuyINTL(uint256 tokenAmount) internal {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = wbnbToken;
        path[2] = intlToken;
        
        _approve(address(this), pancakeRouter, tokenAmount);
        
        try IPancakeRouter02(pancakeRouter).swapExactTokensForTokens(
            tokenAmount,
            0, // Accept any amount of INTL
            path,
            treasuryWallet, // Send INTL to treasury
            block.timestamp + 300
        ) returns (uint[] memory amounts) {
            emit AutoBuyINTL(tokenAmount, amounts[2]);
        } catch {
            // If swap fails, just keep tokens in contract
        }
    }
    
    // Manual reward distribution function (owner only)
    function distributeRewards() external onlyOwner nonReentrant {
        uint256 stablecoinBalance = IERC20(stablecoin).balanceOf(address(this));
        require(stablecoinBalance > 0, "No stablecoin to distribute");
        
        uint256 totalSupply = totalSupply();
        uint256 totalDistributed = 0;
        uint256 eligibleHolders = 0;
        
        // Count eligible holders
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            if (!isExcludedFromRewards[holder] && balanceOf(holder) > 0) {
                eligibleHolders++;
            }
        }
        
        if (eligibleHolders == 0) return;
        
        // Distribute rewards proportionally
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            if (!isExcludedFromRewards[holder] && balanceOf(holder) > 0) {
                uint256 holderReward = (stablecoinBalance * balanceOf(holder)) / totalSupply;
                if (holderReward > 0) {
                    IERC20(stablecoin).transfer(holder, holderReward);
                    totalRewardsReceived[holder] += holderReward;
                    totalDistributed += holderReward;
                }
            }
        }
        
        totalRewardDistributed += totalDistributed;
        emit RewardsDistributed(totalDistributed, eligibleHolders);
    }
    
    // Batch reward distribution to handle gas limits
    function distributeRewardsBatch(uint256 startIndex, uint256 endIndex) external onlyOwner nonReentrant {
        uint256 stablecoinBalance = IERC20(stablecoin).balanceOf(address(this));
        require(stablecoinBalance > 0, "No stablecoin to distribute");
        require(endIndex <= holders.length, "End index out of bounds");
        require(startIndex < endIndex, "Invalid range");
        
        uint256 totalSupply = totalSupply();
        uint256 totalDistributed = 0;
        uint256 eligibleHolders = 0;
        
        // Count eligible holders in batch
        for (uint256 i = startIndex; i < endIndex; i++) {
            address holder = holders[i];
            if (!isExcludedFromRewards[holder] && balanceOf(holder) > 0) {
                eligibleHolders++;
            }
        }
        
        if (eligibleHolders == 0) return;
        
        // Distribute rewards proportionally in batch
        for (uint256 i = startIndex; i < endIndex; i++) {
            address holder = holders[i];
            if (!isExcludedFromRewards[holder] && balanceOf(holder) > 0) {
                uint256 holderReward = (stablecoinBalance * balanceOf(holder)) / totalSupply;
                if (holderReward > 0) {
                    IERC20(stablecoin).transfer(holder, holderReward);
                    totalRewardsReceived[holder] += holderReward;
                    totalDistributed += holderReward;
                }
            }
        }
        
        totalRewardDistributed += totalDistributed;
        emit RewardsDistributed(totalDistributed, eligibleHolders);
    }
    
    // Admin functions
    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        require(_treasuryWallet != address(0), "Invalid treasury wallet");
        address oldWallet = treasuryWallet;
        treasuryWallet = _treasuryWallet;
        
        // Update exclusions
        isExcludedFromTax[oldWallet] = false;
        isExcludedFromTax[_treasuryWallet] = true;
        isExcludedFromRewards[oldWallet] = false;
        isExcludedFromRewards[_treasuryWallet] = true;
        
        emit TreasuryWalletUpdated(oldWallet, _treasuryWallet);
    }
    
    function setTaxExclusion(address account, bool excluded) external onlyOwner {
        isExcludedFromTax[account] = excluded;
        emit TaxExclusionUpdated(account, excluded);
    }
    
    function setRewardExclusion(address account, bool excluded) external onlyOwner {
        isExcludedFromRewards[account] = excluded;
        emit RewardExclusionUpdated(account, excluded);
    }
    
    function setLiquidityPair(address pair, bool isPair) external onlyOwner {
        isLiquidityPair[pair] = isPair;
        emit LiquidityPairUpdated(pair, isPair);
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
    
    // View functions
    function getStablecoinBalance() external view returns (uint256) {
        return IERC20(stablecoin).balanceOf(address(this));
    }
    
    function getWBNBBalance() external view returns (uint256) {
        return IERC20(wbnbToken).balanceOf(address(this));
    }
    
    function getINTLBalance() external view returns (uint256) {
        return IERC20(intlToken).balanceOf(address(this));
    }
    
    function getHoldersCount() external view returns (uint256) {
        return holders.length;
    }
    
    function getHolderAtIndex(uint256 index) external view returns (address) {
        require(index < holders.length, "Index out of bounds");
        return holders[index];
    }
    
    function getEligibleHoldersCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            if (!isExcludedFromRewards[holder] && balanceOf(holder) > 0) {
                count++;
            }
        }
        return count;
    }
    
    // Override decimals
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
} 