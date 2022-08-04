const web3 = require("web3");

const env = {
  tokenName: "Token",
  tokenSymbol: "TKN",
  intialSupply: web3.utils.toBN(10e18),
  maxSuply: web3.utils.toBN(100e18),
  transactionFee: 10,
};

module.exports = env;
