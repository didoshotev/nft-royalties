const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("NFT royalty token test", function () {
    let royaltzNFT;

    before(async () => {
        const [deployer, treasury] = await ethers.getSigners()
        const RoyaltzNFT = await ethers.getContractFactory("RoyaltzNFT")
        royaltzNFT = await RoyaltzNFT.deploy(deployer.address);

        const tokens = await royaltzNFT.tokensOfOwner(deployer.address);
        console.log('tokens: ', tokens);
    })

    beforeEach(async () => {

        await ethers.provider.send(
            "hardhat_reset",
            [
                {
                    forking: {
                        jsonRpcUrl: "https://api.avax-test.network/ext/bc/C/rpc"
                    }
                }
            ]
        );
        // send any token amounts here
    });

    it("Initial", () => {
        console.log('Hello Deffect...!');
    })
})