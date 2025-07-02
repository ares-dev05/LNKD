// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/LNKDToken.sol";

contract DeployScript is Script {
    // BSC Mainnet Addresses
    address constant BSC_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant BSC_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address constant WBNB = 0xbb4CDb9cBd36b01bD1cbAEF60aF814a3f6F0EE75;
    address constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Get addresses from environment
        address treasuryWallet = vm.envAddress("TREASURY_WALLET");
        address intlToken = vm.envAddress("INTL_TOKEN");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy LNKD Token
        LNKDToken lnkdToken = new LNKDToken(
            treasuryWallet,
            intlToken,
            WBNB,
            USDC, // Using USDC as stablecoin
            BSC_ROUTER,
            BSC_FACTORY
        );
        
        console.log("LNKD Token deployed at:", address(lnkdToken));
        console.log("Treasury Wallet:", treasuryWallet);
        console.log("INTL Token:", intlToken);
        console.log("WBNB:", WBNB);
        console.log("USDC:", USDC);
        console.log("Pancake Router:", BSC_ROUTER);
        console.log("Pancake Factory:", BSC_FACTORY);
        
        vm.stopBroadcast();
    }
} 