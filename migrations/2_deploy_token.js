const Token = artifacts.require("Token");
const env = require("../env");

module.exports = function (deployer) {
  deployer.deploy(
    Token,
    env.tokenName,
    env.tokenSymbol,
    env.intialSupply,
    env.maxSuply,
    env.transactionFee
  );
};
