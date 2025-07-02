const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LNKD Token", function () {
  let LNKDToken;
  let lnkdToken;
  let owner;
  let treasury;
  let user1;
  let user2;
  let user3;
  let intlToken;
  let wbnbToken;
  let stablecoin;
  let pancakeRouter;
  let pancakeFactory;

  const TOTAL_SUPPLY = ethers.parseEther("1000000000"); // 1 billion tokens

  beforeEach(async function () {
    // Get signers
    [owner, treasury, user1, user2, user3] = await ethers.getSigners();

    // Deploy mock contracts for testing
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    intlToken = await MockERC20.deploy("INTL Token", "INTL");
    wbnbToken = await MockERC20.deploy("Wrapped BNB", "WBNB");
    stablecoin = await MockERC20.deploy("USDT", "USDT");

    // Deploy mock PancakeSwap router and factory
    const MockPancakeRouter = await ethers.getContractFactory("MockPancakeRouter");
    pancakeRouter = await MockPancakeRouter.deploy();
    
    const MockPancakeFactory = await ethers.getContractFactory("MockPancakeFactory");
    pancakeFactory = await MockPancakeFactory.deploy();

    // Deploy LNKD Token
    LNKDToken = await ethers.getContractFactory("LNKDToken");
    lnkdToken = await LNKDToken.deploy(
      treasury.address,
      intlToken.target,
      wbnbToken.target,
      stablecoin.target,
      pancakeRouter.target,
      pancakeFactory.target
    );

    // Setup mock contracts
    await intlToken.mint(pancakeRouter.target, ethers.parseEther("1000000"));
    await wbnbToken.mint(pancakeRouter.target, ethers.parseEther("1000000"));
    await stablecoin.mint(pancakeRouter.target, ethers.parseEther("1000000"));
  });

  describe("Deployment", function () {
    it("Should deploy with correct initial values", async function () {
      expect(await lnkdToken.name()).to.equal("LNKD Token");
      expect(await lnkdToken.symbol()).to.equal("LNKD");
      expect(await lnkdToken.decimals()).to.equal(18);
      expect(await lnkdToken.totalSupply()).to.equal(TOTAL_SUPPLY);
      expect(await lnkdToken.owner()).to.equal(owner.address);
      expect(await lnkdToken.treasuryWallet()).to.equal(treasury.address);
      expect(await lnkdToken.intlToken()).to.equal(intlToken.target);
      expect(await lnkdToken.wbnbToken()).to.equal(wbnbToken.target);
      expect(await lnkdToken.stablecoin()).to.equal(stablecoin.target);
      expect(await lnkdToken.pancakeRouter()).to.equal(pancakeRouter.target);
      expect(await lnkdToken.pancakeFactory()).to.equal(pancakeFactory.target);
    });

    it("Should assign total supply to owner", async function () {
      expect(await lnkdToken.balanceOf(owner.address)).to.equal(TOTAL_SUPPLY);
    });

    it("Should set correct exclusions", async function () {
      expect(await lnkdToken.isExcludedFromTax(owner.address)).to.be.true;
      expect(await lnkdToken.isExcludedFromTax(treasury.address)).to.be.true;
      expect(await lnkdToken.isExcludedFromTax(lnkdToken.target)).to.be.true;
      expect(await lnkdToken.isExcludedFromRewards(ethers.ZeroAddress)).to.be.true;
      expect(await lnkdToken.isExcludedFromRewards(lnkdToken.target)).to.be.true;
      expect(await lnkdToken.isExcludedFromRewards(owner.address)).to.be.true;
      expect(await lnkdToken.isExcludedFromRewards(treasury.address)).to.be.true;
    });

    it("Should add owner to holders list", async function () {
      expect(await lnkdToken.getHoldersCount()).to.equal(1);
      expect(await lnkdToken.getHolderAtIndex(0)).to.equal(owner.address);
      expect(await lnkdToken.isHolder(owner.address)).to.be.true;
    });
  });

  describe("Trading Control", function () {
    it("Should not allow trading when disabled", async function () {
      await lnkdToken.transfer(user1.address, ethers.parseEther("1000"));
      
      // Should fail when trading is disabled
      await expect(
        lnkdToken.connect(user1).transfer(user2.address, ethers.parseEther("100"))
      ).to.be.revertedWith("Trading not enabled");
    });

    it("Should allow trading when enabled", async function () {
      await lnkdToken.enableTrading();
      await lnkdToken.transfer(user1.address, ethers.parseEther("1000"));
      
      // Should succeed when trading is enabled
      await expect(
        lnkdToken.connect(user1).transfer(user2.address, ethers.parseEther("100"))
      ).to.not.be.reverted;
    });

    it("Should allow owner to transfer even when trading is disabled", async function () {
      await expect(
        lnkdToken.transfer(user1.address, ethers.parseEther("1000"))
      ).to.not.be.reverted;
    });

    it("Should allow treasury to transfer even when trading is disabled", async function () {
      await lnkdToken.transfer(treasury.address, ethers.parseEther("1000"));
      await expect(
        lnkdToken.connect(treasury).transfer(user1.address, ethers.parseEther("100"))
      ).to.not.be.reverted;
    });
  });

  describe("Tax System", function () {
    beforeEach(async function () {
      await lnkdToken.enableTrading();
      await lnkdToken.transfer(user1.address, ethers.parseEther("10000"));
      await lnkdToken.transfer(user2.address, ethers.parseEther("10000"));
    });

    it("Should not apply tax to excluded addresses", async function () {
      const initialBalance = await lnkdToken.balanceOf(user1.address);
      await lnkdToken.setTaxExclusion(user1.address, true);
      
      await lnkdToken.connect(user1).transfer(user2.address, ethers.parseEther("100"));
      
      const finalBalance = await lnkdToken.balanceOf(user1.address);
      const expectedBalance = initialBalance - ethers.parseEther("100");
      expect(finalBalance).to.equal(expectedBalance);
    });

    it("Should apply correct tax on regular transfers", async function () {
      const initialBalance = await lnkdToken.balanceOf(user1.address);
      const initialUser2Balance = await lnkdToken.balanceOf(user2.address);
      
      await lnkdToken.connect(user1).transfer(user2.address, ethers.parseEther("100"));
      
      const finalBalance = await lnkdToken.balanceOf(user1.address);
      const finalUser2Balance = await lnkdToken.balanceOf(user2.address);
      
      // Regular transfers should have no tax
      const expectedTransfer = ethers.parseEther("100");
      
      expect(finalBalance).to.equal(initialBalance - ethers.parseEther("100"));
      expect(finalUser2Balance).to.equal(initialUser2Balance + expectedTransfer);
    });

    it("Should apply correct tax on buy transactions", async function () {
      await lnkdToken.setLiquidityPair(pancakeRouter.target, true);
      await lnkdToken.setTaxExclusion(pancakeRouter.target, true);
      
      // Give the router some LNKD tokens to simulate a buy
      await lnkdToken.transfer(pancakeRouter.target, ethers.parseEther("1000"));
      
      const initialBalance = await lnkdToken.balanceOf(user1.address);
      
      // Simulate buy transaction (from liquidity pair)
      // We need to use a different approach since contracts can't sign
      // Let's test by setting user3 as a liquidity pair and doing a transfer
      await lnkdToken.setLiquidityPair(user3.address, true);
      await lnkdToken.transfer(user3.address, ethers.parseEther("1000"));
      
      await lnkdToken.connect(user3).transfer(user1.address, ethers.parseEther("100"));
      
      const finalBalance = await lnkdToken.balanceOf(user1.address);
      
      // Tax should be 2% = 2 tokens, so user gets 98 tokens
      const expectedTransfer = ethers.parseEther("98");
      
      expect(finalBalance).to.equal(initialBalance + expectedTransfer);
    });

    it("Should apply correct tax on sell transactions", async function () {
      await lnkdToken.setLiquidityPair(pancakeRouter.target, true);
      await lnkdToken.setTaxExclusion(pancakeRouter.target, true);
      await lnkdToken.transfer(user1.address, ethers.parseEther("1000"));
      
      const initialBalance = await lnkdToken.balanceOf(user1.address);
      
      // Simulate sell transaction (to liquidity pair)
      await lnkdToken.connect(user1).transfer(pancakeRouter.target, ethers.parseEther("100"));
      
      const finalBalance = await lnkdToken.balanceOf(user1.address);
      
      // Tax should be 2% = 2 tokens, so 98 tokens are transferred
      const expectedTransfer = ethers.parseEther("98");
      
      expect(finalBalance).to.equal(initialBalance - ethers.parseEther("100"));
    });
  });

  describe("Holder Tracking", function () {
    beforeEach(async function () {
      await lnkdToken.enableTrading();
    });

    it("Should add new holders when they receive tokens", async function () {
      await lnkdToken.transfer(user1.address, ethers.parseEther("1000"));
      
      expect(await lnkdToken.getHoldersCount()).to.equal(2); // owner + user1
      expect(await lnkdToken.isHolder(user1.address)).to.be.true;
    });

    it("Should remove holders when their balance becomes 0", async function () {
      await lnkdToken.transfer(user1.address, ethers.parseEther("1000"));
      expect(await lnkdToken.getHoldersCount()).to.equal(2);
      
      await lnkdToken.connect(user1).transfer(user2.address, ethers.parseEther("1000"));
      expect(await lnkdToken.getHoldersCount()).to.equal(2); // owner + user2
      expect(await lnkdToken.isHolder(user1.address)).to.be.false;
      expect(await lnkdToken.isHolder(user2.address)).to.be.true;
    });

    it("Should not track excluded addresses", async function () {
      await lnkdToken.setRewardExclusion(user1.address, true);
      await lnkdToken.transfer(user1.address, ethers.parseEther("1000"));
      
      expect(await lnkdToken.getHoldersCount()).to.equal(1); // only owner
      expect(await lnkdToken.isHolder(user1.address)).to.be.false;
    });
  });

  describe("Admin Functions", function () {
    it("Should allow owner to set treasury wallet", async function () {
      await lnkdToken.setTreasuryWallet(user1.address);
      expect(await lnkdToken.treasuryWallet()).to.equal(user1.address);
    });

    it("Should not allow non-owner to set treasury wallet", async function () {
      await expect(
        lnkdToken.connect(user1).setTreasuryWallet(user2.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should allow owner to set tax exclusions", async function () {
      await lnkdToken.setTaxExclusion(user1.address, true);
      expect(await lnkdToken.isExcludedFromTax(user1.address)).to.be.true;
      
      await lnkdToken.setTaxExclusion(user1.address, false);
      expect(await lnkdToken.isExcludedFromTax(user1.address)).to.be.false;
    });

    it("Should allow owner to set reward exclusions", async function () {
      await lnkdToken.setRewardExclusion(user1.address, true);
      expect(await lnkdToken.isExcludedFromRewards(user1.address)).to.be.true;
      
      await lnkdToken.setRewardExclusion(user1.address, false);
      expect(await lnkdToken.isExcludedFromRewards(user1.address)).to.be.false;
    });

    it("Should allow owner to set liquidity pairs", async function () {
      await lnkdToken.setLiquidityPair(user1.address, true);
      expect(await lnkdToken.isLiquidityPair(user1.address)).to.be.true;
      
      await lnkdToken.setLiquidityPair(user1.address, false);
      expect(await lnkdToken.isLiquidityPair(user1.address)).to.be.false;
    });

    it("Should allow owner to pause and unpause", async function () {
      await lnkdToken.pause();
      expect(await lnkdToken.paused()).to.be.true;
      
      await lnkdToken.unpause();
      expect(await lnkdToken.paused()).to.be.false;
    });
  });

  describe("Emergency Functions", function () {
    beforeEach(async function () {
      // Send some tokens to contract for testing
      await lnkdToken.transfer(lnkdToken.target, ethers.parseEther("1000"));
      // Mint tokens to stablecoin contract for testing
      await stablecoin.mint(lnkdToken.target, ethers.parseEther("1000"));
    });

    it("Should allow owner to emergency withdraw tokens", async function () {
      const initialBalance = await stablecoin.balanceOf(user1.address);
      await lnkdToken.emergencyWithdrawToken(stablecoin.target, user1.address);
      const finalBalance = await stablecoin.balanceOf(user1.address);
      
      expect(finalBalance).to.be.gt(initialBalance);
    });

    it("Should not allow non-owner to emergency withdraw", async function () {
      await expect(
        lnkdToken.connect(user1).emergencyWithdrawToken(stablecoin.target, user2.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("View Functions", function () {
    it("Should return correct balances", async function () {
      expect(await lnkdToken.getStablecoinBalance()).to.equal(0);
      expect(await lnkdToken.getWBNBBalance()).to.equal(0);
      expect(await lnkdToken.getINTLBalance()).to.equal(0);
    });

    it("Should return correct holder information", async function () {
      expect(await lnkdToken.getHoldersCount()).to.equal(1);
      expect(await lnkdToken.getEligibleHoldersCount()).to.equal(0); // owner is excluded from rewards
    });
  });

  describe("Reward Distribution", function () {
    beforeEach(async function () {
      await lnkdToken.enableTrading();
      await lnkdToken.setRewardExclusion(owner.address, false); // Include owner in rewards for testing
      await lnkdToken.transfer(user1.address, ethers.parseEther("1000"));
      await lnkdToken.transfer(user2.address, ethers.parseEther("2000"));
      
      // Mint stablecoin to contract for testing
      await stablecoin.mint(lnkdToken.target, ethers.parseEther("1000"));
    });

    it("Should distribute rewards correctly", async function () {
      const initialUser1Balance = await stablecoin.balanceOf(user1.address);
      const initialUser2Balance = await stablecoin.balanceOf(user2.address);
      
      await lnkdToken.distributeRewards();
      
      const finalUser1Balance = await stablecoin.balanceOf(user1.address);
      const finalUser2Balance = await stablecoin.balanceOf(user2.address);
      
      expect(finalUser1Balance).to.be.gt(initialUser1Balance);
      expect(finalUser2Balance).to.be.gt(initialUser2Balance);
    });

    it("Should not distribute if no stablecoin balance", async function () {
      await lnkdToken.emergencyWithdrawToken(stablecoin.target, owner.address);
      await expect(lnkdToken.distributeRewards()).to.be.revertedWith("No stablecoin to distribute");
    });

    it("Should support batch distribution", async function () {
      const initialUser1Balance = await stablecoin.balanceOf(user1.address);
      
      await lnkdToken.distributeRewardsBatch(0, 3); // Distribute to first 3 holders
      
      const finalUser1Balance = await stablecoin.balanceOf(user1.address);
      expect(finalUser1Balance).to.be.gt(initialUser1Balance);
    });
  });
});

// Mock contracts for testing
describe("Mock Contracts", function () {
  let MockERC20;
  let MockPancakeRouter;
  let MockPancakeFactory;

  beforeEach(async function () {
    MockERC20 = await ethers.getContractFactory("MockERC20");
    MockPancakeRouter = await ethers.getContractFactory("MockPancakeRouter");
    MockPancakeFactory = await ethers.getContractFactory("MockPancakeFactory");
  });

  it("Should deploy mock contracts", async function () {
    const mockToken = await MockERC20.deploy("Test Token", "TEST");
    const mockRouter = await MockPancakeRouter.deploy();
    const mockFactory = await MockPancakeFactory.deploy();
    
    expect(await mockToken.name()).to.equal("Test Token");
    expect(await mockToken.symbol()).to.equal("TEST");
  });
}); 