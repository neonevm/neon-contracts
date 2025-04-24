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