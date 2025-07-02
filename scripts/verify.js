const { ethers } = require("hardhat");

async function main() {
  console.log("Starting contract verification...");

  // Load deployment info
  let deploymentInfo;
  try {
    deploymentInfo = JSON.parse(require('fs').readFileSync('deployment-info.json', 'utf8'));
  } catch (error) {
    console.error("Error: deployment-info.json not found. Please run deployment first.");
    process.exit(1);
  }

  console.log("Contract address:", deploymentInfo.lnkdTokenAddress);
  console.log("Network:", deploymentInfo.network);

  // Get network to determine constructor arguments
  const network = await ethers.provider.getNetwork();
  const isTestnet = network.chainId === 97;

  // BSC addresses
  const BSC_ADDRESSES = {
    WBNB: "0xbb4CdB9CBd36B01bD1cBaEF60aF1789F6e9E0B9B",
    USDC: "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d",
    USDT: "0x55d398326f99059fF775485246999027B3197955",
    PANCAKESWAP_ROUTER: "0x10ED43C718714eb63d5aA57B78B54704E256024E",
    PANCAKESWAP_FACTORY: "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73",
  };

  const BSC_TESTNET_ADDRESSES = {
    WBNB: "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",
    USDC: "0x64544969ed7EBf5f083679233325356EbE738930",
    USDT: "0x337610d27c682E347C9cD60BD4b3b107C9d34dDd",
    PANCAKESWAP_ROUTER: "0xD99D1c33F9fC3444f8101754aBC46c52416550D1",
    PANCAKESWAP_FACTORY: "0x6725F303b657a9451d8BA641348b6761A6CC7a17",
  };

  const addresses = isTestnet ? BSC_TESTNET_ADDRESSES : BSC_ADDRESSES;

  // Constructor arguments
  const constructorArgs = [
    deploymentInfo.treasuryWallet,
    deploymentInfo.intlToken,
    addresses.WBNB,
    deploymentInfo.stablecoin,
    addresses.PANCAKESWAP_ROUTER,
    addresses.PANCAKESWAP_FACTORY
  ];

  console.log("Constructor arguments:", constructorArgs);

  try {
    console.log("Verifying contract on BSCScan...");
    
    // This will use the hardhat-verify plugin
    await hre.run("verify:verify", {
      address: deploymentInfo.lnkdTokenAddress,
      constructorArguments: constructorArgs,
    });

    console.log("✓ Contract verified successfully!");
    console.log(`BSCScan URL: https://${isTestnet ? 'testnet.' : ''}bscscan.com/address/${deploymentInfo.lnkdTokenAddress}`);
    
  } catch (error) {
    if (error.message.includes("Already Verified")) {
      console.log("✓ Contract is already verified!");
    } else {
      console.error("Verification failed:", error.message);
      console.log("\nManual verification instructions:");
      console.log("1. Go to BSCScan");
      console.log("2. Navigate to the contract address");
      console.log("3. Click 'Contract' tab");
      console.log("4. Click 'Verify and Publish'");
      console.log("5. Select 'Solidity (Single file)'");
      console.log("6. Use compiler version: 0.8.20");
      console.log("7. Use optimization: Enabled, 200 runs");
      console.log("8. Enter constructor arguments:", constructorArgs);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Verification failed:", error);
    process.exit(1);
  }); 