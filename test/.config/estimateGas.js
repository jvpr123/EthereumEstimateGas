const axios = require("axios");

class GasCost {
  apiKey;
  gasPrice;
  ethPrice;

  constructor(apiKey) {
    this.apiKey = apiKey;
  }

  init = async () => {
    try {
      const gasPriceResponse = await axios.get(
        `https://api.etherscan.io/api?module=gastracker&action=gasoracle&apikey=${this.apiKey}`
      );
      const ethPriceResponse = await axios.get(
        `https://api.etherscan.io/api?module=stats&action=ethprice&apikey=${this.apiKey}`
      );

      this.gasPrice = gasPriceResponse.data.result.SafeGasPrice;
      this.ethPrice = ethPriceResponse.data.result.ethusd;
    } catch (error) {
      throw new Error(error);
    }
  };

  currentRates = () => {
    console.group("Current rates");
    console.table({
      "Gas rate": `${this.gasPrice} GWEI`,
      "Eth rate": `US$ ${this.ethPrice} `,
    });
    console.groupEnd();
  };

  estimateDeploy = async (artifact, params) => {
    const gasUsage = await artifact.new.estimateGas(...params);
    const gasCost = gasUsage * this.gasPrice * 1e-9 * this.ethPrice;

    console.group("\nDeploy Cost");
    console.table({
      Method: "Deploy Cost",
      "Gas usage": gasUsage,
      Cost: `US$ ${gasCost}`,
    });
    console.groupEnd();
  };

  estimate = async (contract, method, params) => {
    try {
      const gasUsage = await contract[method].estimateGas(...params);
      const gasCost = gasUsage * this.gasPrice * 1e-9 * this.ethPrice;

      console.group(`\nMethod: ${method}`);
      console.table({
        "Gas usage": gasUsage,
        Cost: `US$ ${gasCost}`,
      });
      console.groupEnd();
    } catch (error) {
      throw new Error(error);
    }
  };
}

module.exports = GasCost;
