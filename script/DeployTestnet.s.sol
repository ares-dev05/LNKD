// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/LNKDToken.sol";

contract DeployTestnetScript is Script {
    // BSC Testnet Addresses
    address constant BSC_TESTNET_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address constant BSC_TESTNET_FACTORY = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;
    address constant BSC_TESTNET_WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address constant BSC_TESTNET_USDC = 0x64544969ed7EBf5f083679233325356EbE738930;
    
    // Test addresses for audit
    address constant TREASURY = 0x1234567890123456789012345678901234567890;
    address constant INTL_TOKEN = 0x1234567890123456789012345678901234567891;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy LNKD Token on BSC Testnet
        LNKDToken lnkdToken = new LNKDToken(
            TREASURY,
            INTL_TOKEN,
            BSC_TESTNET_WBNB,
            BSC_TESTNET_USDC,
            BSC_TESTNET_ROUTER,
            BSC_TESTNET_FACTORY
        );
        
        console.log("=== LNKD Token Deployed on BSC Testnet ===");
        console.log("Contract Address:", address(lnkdToken));
        console.log("Treasury Wallet:", TREASURY);
        console.log("INTL Token:", INTL_TOKEN);
        console.log("WBNB:", BSC_TESTNET_WBNB);
        console.log("USDC:", BSC_TESTNET_USDC);
        console.log("Pancake Router:", BSC_TESTNET_ROUTER);
        console.log("Pancake Factory:", BSC_TESTNET_FACTORY);
        console.log("Total Supply:", lnkdToken.totalSupply());
        console.log("==========================================");
        
        vm.stopBroadcast();
    }
} 