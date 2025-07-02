const { ethers } = require("hardhat");

async function main() {
  console.log("Starting post-deployment setup...");

  // Load deployment info
  let deploymentInfo;
  try {
    deploymentInfo = JSON.parse(require('fs').readFileSync('deployment-info.json', 'utf8'));
  } catch (error) {
    console.error("Error: deployment-info.json not found. Please run deployment first.");
    process.exit(1);
  }

  const [deployer] = await ethers.getSigners();
  console.log("Setup with account:", deployer.address);

  // Get contract instance
  const lnkdToken = await ethers.getContractAt("LNKDToken", deploymentInfo.lnkdTokenAddress);
  console.log("Contract address:", deploymentInfo.lnkdTokenAddress);

  // Configuration - Update these values
  const config = {
    liquidityPairs: [
      // Add your LP pair addresses here
      // "0x0000000000000000000000000000000000000000", // Example LP address
    ],
    enableTrading: false, // Set to true when ready to enable trading
  };

  console.log("\n=== Current Contract State ===");
  console.log("Trading enabled:", await lnkdToken.tradingEnabled());
  console.log("Owner:", await lnkdToken.owner());
  console.log("Treasury wallet:", await lnkdToken.treasuryWallet());
  console.log("INTL token:", await lnkdToken.intlToken());
  console.log("Stablecoin:", await lnkdToken.stablecoin());

  // Set liquidity pairs
  if (config.liquidityPairs.length > 0) {
    console.log("\n=== Setting Liquidity Pairs ===");
    for (let i = 0; i < config.liquidityPairs.length; i++) {
      const pairAddress = config.liquidityPairs[i];
      if (pairAddress !== "0x0000000000000000000000000000000000000000") {
        console.log(`Setting liquidity pair ${i + 1}: ${pairAddress}`);
        const tx = await lnkdToken.setLiquidityPair(pairAddress, true);
        await tx.wait();
        console.log(`✓ Liquidity pair ${i + 1} set successfully`);
      }
    }
  } else {
    console.log("\n⚠️  No liquidity pairs configured. Please update config.liquidityPairs in setup.js");
  }

  // Enable trading if configured
  if (config.enableTrading) {
    console.log("\n=== Enabling Trading ===");
    const tx = await lnkdToken.enableTrading();
    await tx.wait();
    console.log("✓ Trading enabled successfully");
  } else {
    console.log("\n⚠️  Trading not enabled. Set config.enableTrading = true when ready");
  }

  // Display final state
  console.log("\n=== Final Contract State ===");
  console.log("Trading enabled:", await lnkdToken.tradingEnabled());
  console.log("Total holders:", await lnkdToken.getHoldersCount());
  console.log("Eligible holders for rewards:", await lnkdToken.getEligibleHoldersCount());

  console.log("\n=== Setup Complete ===");
  console.log("Contract is ready for use!");
  
  if (!config.enableTrading) {
    console.log("\n⚠️  Remember to enable trading when ready:");
    console.log("await lnkdToken.enableTrading();");
  }

  console.log("\n=== Next Steps ===");
  console.log("1. Test contract functionality");
  console.log("2. Create liquidity on PancakeSwap");
  console.log("3. Update liquidity pair addresses in setup.js");
  console.log("4. Enable trading when ready");
  console.log("5. Test reward distribution");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Setup failed:", error);
    process.exit(1);
  }); 