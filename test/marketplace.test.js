const { expect } = require("chai");
const { ethers } = require("hardhat");


describe.skip("Marketplace test", function () {

    let deployer, user1;
    let royaltzNFTInstance, marketplaceInstance;

    before(async () => {
        [deployer, user1] = await ethers.getSigners();

        const RoyaltzNFT = await ethers.getContractFactory("RoyaltzNFT");
        royaltzNFTInstance = await RoyaltzNFT.deploy(deployer.address);
        
        const Marketplace = await ethers.getContractFactory("Marketplace");
        marketplaceInstance = await Marketplace.deploy(royaltzNFTInstance.address); 
    })
    
    it("init", async () => { 
        console.log('Hello deffect');
        console.log(marketplaceInstance);
    })
})