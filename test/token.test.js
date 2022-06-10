const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("NFT royalty token test", function () {
    before(async () => {
        const [deployer, treasury] = await ethers.getSigners()
        const RoyaltzNFT = await ethers.getContractFactory("RoyaltzNFT")
        const royaltzNFT = await RoyaltzNFT.deploy(deployer.address);
    })

    it("Initial", () => {
        console.log('Hello Deffect...!');
    })
})