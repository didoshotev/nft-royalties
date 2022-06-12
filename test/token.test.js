const { expectRevert, constants } = require("@openzeppelin/test-helpers");
const { expect, assert } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

const TEST_HASH = "TEST";

describe("NFT token test", function () {
    let deployer, user1;
    let tokenInstance;

    before(async () => {
        [deployer, user1] = await ethers.getSigners()
        const RoyaltzNFT = await ethers.getContractFactory("RoyaltzNFT")
        tokenInstance = await RoyaltzNFT.deploy(deployer.address);
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

    describe("Test ERC721", () => {
        it("should returns the deployer", async () => {
            const owner = await tokenInstance.owner();
            expect(owner).equal(deployer.address)
        })

        it("should returns the initial royalty receiver", async () => {
            const receiver = await tokenInstance.getRoyaltyReceiver();
            expect(receiver).equal(deployer.address)
        })

        it("should set new royalty receiver", async () => {
            await tokenInstance.setRoyaltyReceiver(user1.address);
            const newReceiver = await tokenInstance.getRoyaltyReceiver();
            expect(newReceiver).equal(user1.address);
        })

        it("should mint", async () => {
            const balanceBefore = await tokenInstance.totalSupply();
            await tokenInstance.mint(user1.address, "1");
            const balanceAfter = await tokenInstance.totalSupply();
            
            expect(+balanceBefore).equal(+balanceAfter - 1);
            expect(await tokenInstance.balanceOf(user1.address)).equal("1");
        })

        it("should throw when called not by the Owner", async function () {
            let hasError = false;
            try {
                await tokenInstance.connect(user1).mint(deployer.address, "2");
            } catch (error) {
                hasError = true;
            }
            expect(hasError).to.be.true;
        })

        it("should throw when no hash provided", async () => {
            let hasError = false;
            try {
                await tokenInstance.mint(deployer.address, "");
            } catch (error) {
                hasError = true;
            }
            expect(hasError).to.be.true;
        })

        it("should throw when same hash provided", async () => {
            let hasError = false;
            try {
                await tokenInstance.mint(deployer.address, "TEST");
                await tokenInstance.mint(deployer.address, "TEST");
            } catch (error) {
                hasError = true;
            }
            expect(hasError).to.be.true;
        })

    })
})