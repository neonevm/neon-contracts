import { task, overrideTask } from "hardhat/config"
import hardhatToolboxMochaEthersPlugin from "@nomicfoundation/hardhat-toolbox-mocha-ethers"
import { deriveMasterKeyFromKeystore } from "./node_modules/@nomicfoundation/hardhat-keystore/src/internal/keystores/encryption.ts"
import { askPassword } from "./node_modules/@nomicfoundation/hardhat-keystore/src/internal/keystores/password.ts"
import { set } from "./node_modules/@nomicfoundation/hardhat-keystore/src/internal/tasks/set.ts"
import { get } from "./node_modules/@nomicfoundation/hardhat-keystore/src/internal/tasks/get.ts"
import { list } from "./node_modules/@nomicfoundation/hardhat-keystore/src/internal/tasks/list.ts"
import { remove } from "./node_modules/@nomicfoundation/hardhat-keystore/src/internal/tasks/delete.ts"
import { UserDisplayMessages } from "./node_modules/@nomicfoundation/hardhat-keystore/src/internal/ui/user-display-messages.ts"
import { setupKeystoreLoaderFrom } from "./node_modules/@nomicfoundation/hardhat-keystore/src/internal/utils/setup-keystore-loader-from.ts"
import pkg from './package.json';

// We define a custom project-specific file path for the encrypted keystore
const customKeystoreFilePath = (hre) => {
  return {
    keystore: {
      filePath: hre.config.keystore.filePath.split('keystore.json')[0] + `${pkg.name}-keystore.json`
    }
  }
}

// Custom subtask overriding the built-in keystore:set subtask to use our custom keystore file path instead of the
// default one
const setSecretTask = overrideTask(["keystore", "set"])
    .setAction(async (args, hre) => {
      const keystoreLoader = setupKeystoreLoaderFrom({ config: customKeystoreFilePath(hre) })
      await set(
          args,
          keystoreLoader,
          hre.interruptions.requestSecretInput.bind(hre.interruptions),
      );
    })
    .build()

// Custom subtask overriding the built-in keystore:get subtask to use our custom keystore file path instead of the
// default one
const getSecretTask = overrideTask(["keystore", "get"])
    .setAction(async (args, hre) => {
      const keystoreLoader = setupKeystoreLoaderFrom({ config: customKeystoreFilePath(hre) })
      await get(
          args,
          keystoreLoader,
          hre.interruptions.requestSecretInput.bind(hre.interruptions),
      );
    })
    .build()

// Custom subtask overriding the built-in keystore:list subtask to use our custom keystore file path instead of the
// default one
const listSecretsTask = overrideTask(["keystore", "list"])
    .setAction(async (args, hre) => {
      const keystoreLoader = setupKeystoreLoaderFrom({ config: customKeystoreFilePath(hre) })
      await list(keystoreLoader);
    })
    .build()

// Custom subtask overriding the built-in keystore:delete subtask to use our custom keystore file path instead of the
// default one
const deleteSecretTask = overrideTask(["keystore", "delete"])
    .setAction(async (args, hre) => {
      const keystoreLoader = setupKeystoreLoaderFrom({ config: customKeystoreFilePath(hre) })

      await remove(
          args,
          keystoreLoader,
          hre.interruptions.requestSecretInput.bind(hre.interruptions),
      );
    })
    .build()

// Custom subtask to the built-in keystore task to display the keystore file path in the CLI
const displayKeystoreFilePathTask = task(["keystore", "path"], "Displays the keystore file path in the CLI")
    .setAction(async (args, hre) => {
      const keystoreLoader = setupKeystoreLoaderFrom({ config: customKeystoreFilePath(hre) })
      if (!(await keystoreLoader.isKeystoreInitialized())) {
        console.log(UserDisplayMessages.displayNoKeystoreSetErrorMessage());
        process.exitCode = 1;
      }
      console.log(`Custom Hardhat keystore file path for ${pkg.name} project:`, customKeystoreFilePath(hre).keystore.filePath)
    })
    .build()

// Custom subtask to the built-in keystore task to ask for the keystore password in the CLI while running mocha tests
const askPasswordTask = task(["keystore", "askpwd"], "Asks for the keystore password in the CLI")
    .setAction(async (args, hre) => {
      return await askPassword(hre.interruptions.requestSecretInput.bind(hre.interruptions))
    })
    .build()

// Custom subtask to the built-in keystore task to decrypt keystore secrets while running mocha tests
const decryptSecretTask = task(["keystore", "decrypt"], "Decrypts a secret value given a key and a password")
    .addPositionalArgument({
      name: "key",
      type: "STRING",
      description: "Specifies the key of the secret value we want to decrypt"
    })
    .addPositionalArgument({
      name: "password",
      type: "STRING",
      description: "The password that was used to encrypt the secret value"
    })
    .setAction(async (args, hre) => {
      return await decryptSecret(hre, args.key, args.password)
    })
    .build()

// Custom function to decrypt keystore secrets while running mocha tests
async function decryptSecret(hre, key, password) {
  const keystoreLoader = setupKeystoreLoaderFrom({ config: customKeystoreFilePath(hre) })
  if (!(await keystoreLoader.isKeystoreInitialized())) {
    console.error(UserDisplayMessages.displayNoKeystoreSetErrorMessage())
    process.exitCode = 1
    return
  }
  const keystore = await keystoreLoader.loadKeystore()
  const masterKey = deriveMasterKeyFromKeystore({
    encryptedKeystore: keystore.toJSON(),
    password
  })
  if (!(await keystore.hasKey(key, masterKey))) {
    console.error(UserDisplayMessages.displayKeyNotFoundErrorMessage(key))
    process.exitCode = 1
    return
  }
  return await keystore.readValue(key, masterKey)
}

const config = {
  plugins: [hardhatToolboxMochaEthersPlugin],
  tasks: [
    setSecretTask,
    getSecretTask,
    listSecretsTask,
    deleteSecretTask,
    displayKeystoreFilePathTask,
    askPasswordTask,
    decryptSecretTask
  ],
  solidity: {
    compilers:[
      {
        version: '0.8.28',
        settings: {
          evmVersion: "cancun",
          viaIR: true,
          optimizer: {
              enabled: true,
              runs: 200
          }
        }
      }
    ]
  },
  docgen: {
    path: './docs',
    pages: 'files',
    clear: true,
    runOnCompile: true
  },
  etherscan: {
    apiKey: {
      neonevm: "test"
    },
    customChains: [
      {
        network: "neonevm",
        chainId: 245022926,
        urls: {
          apiURL: "https://devnet-api.neonscan.org/hardhat/verify",
          browserURL: "https://devnet.neonscan.org"
        }
      },
      {
        network: "neonevm",
        chainId: 245022934,
        urls: {
          apiURL: "https://api.neonscan.org/hardhat/verify",
          browserURL: "https://neonscan.org"
        }
      }
    ]
  },
  networks: {
    curvestand: {
      type: "http",
      chainType: "generic",
      url: "https://curve-stand.neontest.xyz",
      accounts: [],
      allowUnlimitedContractSize: false,
      gasMultiplier: 2,
      maxFeePerGas: 10000,
      maxPriorityFeePerGas: 5000
    },
    neondevnet: {
      type: "http",
      chainType: "generic",
      url: "https://devnet.neonevm.org",
      accounts: [],
      chainId: 245022926,
      allowUnlimitedContractSize: false,
      gasMultiplier: 2,
      maxFeePerGas: '10000000000000',
      maxPriorityFeePerGas: '5000000000000'
    },
    neonmainnet: {
      type: "http",
      chainType: "generic",
      url: "https://neon-proxy-mainnet.solana.p2p.org",
      accounts: [],
      chainId: 245022934,
      allowUnlimitedContractSize: false,
      gas: "auto",
      gasPrice: "auto"
    }
  },
  mocha: {
    timeout: 5000000
  }
}

export default config
