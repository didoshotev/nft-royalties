require("@nomiclabs/hardhat-waffle");
require('dotenv').config();



const accounts = [
	{ privateKey: process.env.DEPLOYER_PRIVATE_KEY, balance: "10000000000000000000000" },
	{ privateKey: process.env.TREASURY_WALLET_PRIVATE_KEY, balance: "20000000000000000000000" },
];


/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
	defaultNetwork: "hardhat",
	networks: {
		hardhat: { 
			chainId: 1337,
			gasPrice: 225000000000,
			accounts,
			forking: {
				url: "https://api.avax-test.network/ext/bc/C/rpc", // avax
			}
		}
	},
	solidity: {
		compilers: [
			{
				version: "0.5.0",
				settings: {
					optimizer: {
						enabled: true,
						runs: 200
					}
				},
			},
			{
				version: "0.6.12",
				settings: {
					optimizer: {
						enabled: true,
						runs: 200
					}
				},
			},
			{
				version: "0.8.4",
				settings: {
					optimizer: {
						enabled: true,
						runs: 200
					}
				},
			},
		],
	},
};
