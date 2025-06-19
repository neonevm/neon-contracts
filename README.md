# Neon EVM contracts

This repository is a set of various contracts and integrations that aim to help developers building on Neon EVM.

### Integrations on Neon EVM
* [ERC20ForSPL & ERC20ForSPLFactory](contracts/token/ERC20ForSpl)
* [Solidity libraries to interact with Solana](contracts/composability)
* [Pyth oracle](contracts/oracles/Pyth)
* [Solana VRF](contracts/oracles/SolanaVRF)

### Precompiles on Neon EVM
Neon EVM provides a set of custom precompiles which are built to connect Solidity developers with Solana. The list of the precompiles and their code can be found [here](contracts/precompiles).

### Helpers
Helper libraries which could be used to prepare and validate data being passed to and return from Solana can be found [here](contracts/utils).

### Secret values setup
Secret values (such as private keys) used in tests and scripts should be stored using Hardhat's encrypted keystore file. 
This keystore file is specific to this _Hardhat_ project, you can run the following command in the CLI to display the 
keystore file path for this _Hardhat_ project: 

```shell
npx hardhat keystore path
```

To store encrypted secret values into this project's Hardhat keystore file, run the following commands in the CLI:

```shell
npx hardhat keystore set PRIVATE_KEY_OWNER
```
```shell
npx hardhat keystore set PRIVATE_KEY_USER_1
```
```shell
npx hardhat keystore set PRIVATE_KEY_USER_2
```
```shell
npx hardhat keystore set PRIVATE_KEY_USER_3
```
```shell
npx hardhat keystore set PRIVATE_KEY_SOLANA
```
```shell
npx hardhat keystore set PRIVATE_KEY_SOLANA_2
```
```shell
npx hardhat keystore set PRIVATE_KEY_SOLANA_3
```
```shell
npx hardhat keystore set PRIVATE_KEY_SOLANA_4
```

You will be asked to choose a password (which will be used to encrypt provided secrets) and to enter the secret values
to be encrypted. The keystore password can be added to the `.env` file (as `KEYSTORE_PASSWORD`)  which allows secrets
to be decrypted automatically when running Hardhat tests and scripts. Otherwise, each running Hardhat test and script
will have the CLI prompt a request to enter the keystore password manually.

> [!CAUTION]
> Although it is not recommended (as it involves risks of leaking secrets) it is possible to store plain-text secrets in
`.env` file using the same keys as listed above. When doing so, user will be asked to confirm wanting to use plain-text
secrets found in `.env` file when running Hardhat tests and scripts.
