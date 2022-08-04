const axios = require("axios");
const { expect } = require("./.config/setup");
const env = require("../env");

const BN = web3.utils.BN;
const Token = artifacts.require("Token");

contract("Sample Test: Token Contract", async (accounts) => {
  const [deployer, recipient] = accounts;
  let etherPrice;
  let gasPrice;

  beforeEach(async () => {
    this.instance = await Token.new(
      env.tokenName,
      env.tokenSymbol,
      env.intialSupply,
      env.maxSuply,
      env.transactionFee
    );

    etherPrice = await axios.get(
      "https://api.etherscan.io/api?module=stats&action=ethprice&apikey=MyApiKey"
    );
    gasPrice = await axios.get(
      "https://api.etherscan.io/api?module=gastracker&action=gasoracle&apikey=MyApiKey"
    );
  });

  it("Deploy Cost", async () => {
    const result = await Token.new.estimateGas(
      env.tokenName,
      env.tokenSymbol,
      env.intialSupply,
      env.maxSuply,
      env.transactionFee
    );

    expect(1).to.be.equal(1);

    console.log(`GasPrice: ${gasPrice.data.result.SafeGasPrice} GWEI`);
    console.log(`EtherPrice: US$ ${etherPrice.data.result.ethusd}`);
    console.log(`Gas usage: ${result}`);
    console.log(
      `Cost: US$ ${
        result *
        gasPrice.data.result.SafeGasPrice *
        1e-9 *
        etherPrice.data.result.ethusd
      }`
    );
  });

  it("Transfer Cost", async () => {
    const result = await this.instance.transfer.estimateGas(recipient, 1000, {
      from: deployer,
    });

    expect(1).to.be.equal(1);

    console.log(`GasPrice: ${gasPrice.data.result.SafeGasPrice} GWEI`);
    console.log(`EtherPrice: US$ ${etherPrice.data.result.ethusd}`);
    console.log(`Gas usage: ${result}`);
    console.log(
      `Cost: US$ ${
        result *
        gasPrice.data.result.SafeGasPrice *
        1e-9 *
        etherPrice.data.result.ethusd
      }`
    );
  });
});
