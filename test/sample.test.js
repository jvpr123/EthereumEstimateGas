const GasCost = require("./.config/estimateGas");
const env = require("../env");

const Token = artifacts.require("Token");

contract("Sample Test: Token Contract", async (accounts) => {
  const [deployer, recipient] = accounts;

  before(async () => {
    // Instantiate class passing Etherscan API-key
    this.gasCost = new GasCost(env.etherScanApiKey);

    // Initialize by internally fetching gas and ether prices
    await this.gasCost.init();

    // Logs current gas and ether prices fetched from Etherscan API
    this.gasCost.currentRates();

    // Logs estimated deploy cost
    await this.gasCost.estimateDeploy(Token, [
      env.tokenName,
      env.tokenSymbol,
      env.intialSupply,
      env.maxSuply,
      env.transactionFee,
    ]);
  });

  beforeEach(async () => {
    this.instance = await Token.new(
      env.tokenName,
      env.tokenSymbol,
      env.intialSupply,
      env.maxSuply,
      env.transactionFee
    );
  });

  it("Contract Functions Cost", async () => {
    // Logs estimate of cost by calling transfer() method
    await this.gasCost.estimate(this.instance, "transfer", [
      recipient,
      1000,
      { from: deployer },
    ]);

    // Logs estimate of cost by calling balanceOf() method
    await this.gasCost.estimate(this.instance, "balanceOf", [deployer]);
  });
});
