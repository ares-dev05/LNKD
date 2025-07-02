const { ethers } = require("hardhat");

async function main() {
  console.log("Starting LNKD Token deployment...");

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // BSC Mainnet addresses
  const BSC_ADDRESSES = {
    // Mainnet
    WBNB: "0xbb4CdB9CBd36B01bD1cBaEF60aF1789F6e9E0B9B",
    USDC: "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d",
    USDT: "0x55d398326f99059fF775485246999027B3197955",
    PANCAKESWAP_ROUTER: "0x10ED43C718714eb63d5aA57B78B54704E256024E",
    PANCAKESWAP_FACTORY: "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73",
  };

  // BSC Testnet addresses
  const BSC_TESTNET_ADDRESSES = {
    WBNB: "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",
    USDC: "0x64544969ed7EBf5f083679233325356EbE738930",
    USDT: "0x337610d27c682E347C9cD60BD4b3b107C9d34dDd",
    PANCAKESWAP_ROUTER: "0xD99D1c33F9fC3444f8101754aBC46c52416550D1",
    PANCAKESWAP_FACTORY: "0x6725F303b657a9451d8BA641348b6761A6CC7a17",
  };

  // Get network to determine which addresses to use
  const network = await ethers.provider.getNetwork();
  const isTestnet = network.chainId === 97; // BSC Testnet
  
  const addresses = isTestnet ? BSC_TESTNET_ADDRESSES : BSC_ADDRESSES;
  
  console.log(`Deploying to ${isTestnet ? 'BSC Testnet' : 'BSC Mainnet'}`);
  console.log("Using addresses:", addresses);

  // Configuration - Update these values before deployment
  const config = {
    treasuryWallet: "0x0000000000000000000000000000000000000000", // UPDATE: Your treasury wallet address
    intlToken: "0x0000000000000000000000000000000000000000", // UPDATE: INTL token address
    stablecoin: addresses.USDT, // USDT or USDC
  };

  // Validate configuration
  if (config.treasuryWallet === "0x0000000000000000000000000000000000000000") {
    throw new Error("Please update treasuryWallet address in deploy.js");
  }
  
  if (config.intlToken === "0x0000000000000000000000000000000000000000") {
    throw new Error("Please update intlToken address in deploy.js");
  }

  console.log("Deployment configuration:");
  console.log("- Treasury Wallet:", config.treasuryWallet);
  console.log("- INTL Token:", config.intlToken);
  console.log("- Stablecoin:", config.stablecoin);
  console.log("- WBNB:", addresses.WBNB);
  console.log("- PancakeSwap Router:", addresses.PANCAKESWAP_ROUTER);
  console.log("- PancakeSwap Factory:", addresses.PANCAKESWAP_FACTORY);

  // Deploy LNKD Token
  console.log("\nDeploying LNKD Token...");
  const LNKDToken = await ethers.getContractFactory("LNKDToken");
  const lnkdToken = await LNKDToken.deploy(
    config.treasuryWallet,
    config.intlToken,
    addresses.WBNB,
    config.stablecoin,
    addresses.PANCAKESWAP_ROUTER,
    addresses.PANCAKESWAP_FACTORY
  );

  await lnkdToken.waitForDeployment();
  const lnkdTokenAddress = await lnkdToken.getAddress();

  console.log("LNKD Token deployed to:", lnkdTokenAddress);

  // Wait a few blocks for deployment to be confirmed
  console.log("Waiting for deployment confirmation...");
  await ethers.provider.waitForTransaction(lnkdToken.deploymentTransaction().hash, 5);

  // Verify deployment
  console.log("\nVerifying deployment...");
  const deployedToken = await ethers.getContractAt("LNKDToken", lnkdTokenAddress);
  
  console.log("Token name:", await deployedToken.name());
  console.log("Token symbol:", await deployedToken.symbol());
  console.log("Total supply:", ethers.formatEther(await deployedToken.totalSupply()));
  console.log("Owner:", await deployedToken.owner());
  console.log("Treasury wallet:", await deployedToken.treasuryWallet());
  console.log("INTL token:", await deployedToken.intlToken());
  console.log("WBNB token:", await deployedToken.wbnbToken());
  console.log("Stablecoin:", await deployedToken.stablecoin());
  console.log("PancakeSwap router:", await deployedToken.pancakeRouter());
  console.log("Trading enabled:", await deployedToken.tradingEnabled());

  // Post-deployment setup
  console.log("\nPost-deployment setup:");
  
  // Set liquidity pairs (you'll need to update these after creating LP)
  console.log("Note: Remember to call setLiquidityPair() for your LP addresses after creating liquidity");
  
  // Enable trading (optional - you can do this later)
  // console.log("Enabling trading...");
  // await deployedToken.enableTrading();
  // console.log("Trading enabled!");

  console.log("\n=== DEPLOYMENT COMPLETE ===");
  console.log("LNKD Token Address:", lnkdTokenAddress);
  console.log("Network:", isTestnet ? "BSC Testnet" : "BSC Mainnet");
  console.log("Chain ID:", network.chainId);
  
  console.log("\n=== NEXT STEPS ===");
  console.log("1. Verify contract on BSCScan");
  console.log("2. Create liquidity pair on PancakeSwap");
  console.log("3. Call setLiquidityPair() with your LP address");
  console.log("4. Call enableTrading() when ready");
  console.log("5. Test the contract functionality");

  // Save deployment info
  const deploymentInfo = {
    network: isTestnet ? "BSC Testnet" : "BSC Mainnet",
    chainId: network.chainId,
    lnkdTokenAddress: lnkdTokenAddress,
    deployer: deployer.address,
    treasuryWallet: config.treasuryWallet,
    intlToken: config.intlToken,
    stablecoin: config.stablecoin,
    wbnb: addresses.WBNB,
    pancakeRouter: addresses.PANCAKESWAP_ROUTER,
    pancakeFactory: addresses.PANCAKESWAP_FACTORY,
    deploymentTx: lnkdToken.deploymentTransaction().hash,
    timestamp: new Date().toISOString()
  };

  console.log("\nDeployment info saved to deployment-info.json");
  require('fs').writeFileSync(
    'deployment-info.json', 
    JSON.stringify(deploymentInfo, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  }); 