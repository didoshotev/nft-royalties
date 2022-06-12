const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("NFT royalty token test", function () {
    let deployer, user1;
    let royaltzNFT;

    before(async () => {
        [deployer, user1] = await ethers.getSigners()
        const RoyaltzNFT = await ethers.getContractFactory("RoyaltzNFT")
        royaltzNFT = await RoyaltzNFT.deploy(deployer.address);
        // const tokens = await royaltzNFT.tokensOfOwner(deployer.address);
        const owner = await royaltzNFT.owner();
        console.log('owner: ', owner);
    })

    // beforeEach(async () => {

    //     await ethers.provider.send(
    //         "hardhat_reset",
    //         [
    //             {
    //                 forking: {
    //                     jsonRpcUrl: "https://api.avax-test.network/ext/bc/C/rpc"
    //                 }
    //             }
    //         ]
    //     );
    //     // send any token amounts here
    // });

    it("should returns the deployer", async () => {
        const owner = await royaltzNFT.owner();
        expect(owner).equal(deployer.address)
    })

    it("should returns the initial royalty receiver", async () => {
        const receiver = await royaltzNFT.getRoyaltyReceiver();
        expect(receiver).equal(deployer.address)
    })

    it("should set new royalty receiver", async () => { 
        await royaltzNFT.setRoyaltyReceiver(user1.address);
        const newReceiver = await royaltzNFT.getRoyaltyReceiver();
        expect(newReceiver).equal(user1.address);
    })

    it("should mint and returns the tokens of an address", async () => { 
        await royaltzNFT.mint(user1.address, "test_uri_0");
        const tokens = await royaltzNFT.tokensOfOwner(user1.address);
        expect(tokens).to.have.length(1);
    })
})