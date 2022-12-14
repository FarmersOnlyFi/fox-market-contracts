import "@nomicfoundation/hardhat-toolbox";
import '@openzeppelin/hardhat-upgrades';

import "dotenv/config";

import "./tasks";

module.exports = {
  solidity: {
    compilers: ["0.8.16", "0.8.9", "0.8.2", "0.6.0"].map(version => ({
      version,
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    })),
  },
  networks: {
    klaytn: {
      url: 'https://public-node-api.klaytnapi.com/v1/cypress',
      chainId: 8217,
      accounts: [process.env.PRIVATE_KEY]
    },
    dfk: {
      url: 'https://avax-dfk.gateway.pokt.network/v1/lb/6244818c00b9f0003ad1b619//ext/bc/q2aTwKuyzgs8pynF7UXBZCU7DejbZbZ6EUyHr3JQzYgwNPUPi/rpc',
      chainId: 53935,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: {
      klaytn: 'not needed',
      dfk: 'not needed'
    },
    customChains: [
      {
        network: "klaytn",
        chainId: 8217,
        urls: {
          apiURL: "https://api-cypress-v3.scope.klaytn.com/",
          browserURL: "https://scope.klaytn.com/",
        },
      },
      {
        network: "dfk",
        chainId: 53935,
        urls: {
          apiURL: "https://subnets.avax.network/defi-kingdoms/dfk-chain/explorer",
          browserURL: "https://subnets.avax.network/defi-kingdoms/dfk-chain/explorer",
        },
      }
    ]
  }
};
