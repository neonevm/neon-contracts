# Solidity libraries for NeonEVM composability

The composability feature allows dApps deployed on _NeonEVM_ to interact with _Solana_ programs, which involves 
formatting instructions in ways that are specific to each program.

Here we provide a set of **Solidity** libraries which make it possible to easily implement secure interactions with 
_Solana_'s **System**, **SPL Token** and **Raydium** programs.

## System program

### LibSystemProgram library

This library provides helper functions for formatting instructions intended to be executed by _Solana_'s **System** 
program.

### LibSystemData library

This library provides a set of getter functions for querying System accounts data from Solana.

### CallSystemProgram contract

This contract demonstrates how the **LibSystemProgram** library can be used in practice to interact with Solana's System
program.

## SPL Token program

### LibSPLTokenProgram library

This library provides helper functions for formatting instructions intended to be executed by _Solana_'s **SPL Token** 
program.

### LibSPLTokenData library

This library provides a set of getter functions for querying SPL Token accounts data from Solana.

### CallSPLTokenProgram contract

This contract demonstrates how the **LibSPLTokenProgram** library can be used in practice to interact with Solana's SPL 
Token program.

### Token accounts

The **CallSPLTokenProgram** contract provides its users with methods to create and initialize SPL _token mints_ and 
_arbitrary token accounts_ as well as to mint and transfer tokens using those accounts. It features a built-in 
authentication logic ensuring that users remain in control of created accounts.

#### Associated token accounts vs Arbitrary token accounts

_Arbitrary token accounts_ are derived using a `seed` which includes the token account `owner`'s public key and an 
arbitrary `nonce` (among other parameters). By using different `nonce` values it is possible to derive different 
_arbitrary token accounts_ for the same `owner` which can be useful for some use cases.

However, there exists a canonical way of deriving a token account for a specific `owner` and this token account is 
called an _associated token account_. Associated token accounts are used widely by application s running on _Solana_ and 
it generally expected that token transfers are made to and from _associated token accounts_.

#### Ownership and authentication

##### SPL token mint ownership and authentication

The `createInitializeTokenMint` function takes a `seed` parameter as input which is used along with 
`msg.sender` to derive the created token mint account. While the **CallSPLTokenProgram** contract is given mint/freeze 
authority on the created token mint account, the `mintTokens` function grants `msg.sender` permission to mint tokens
by providing the `seed` that was used to create the token mint account.

##### Arbitrary token account ownership and authentication

The `createInitializeATA` function can be used for three different purposes:

* To create and initialize an _arbitrary token account_ to be used by `msg.sender` to send tokens through the 
**CallSPLTokenProgram** contract. In this case, both the `owner` and `tokenOwner` parameters passed to the function 
should be left empty. The _arbitrary token account_ to be created is derived from `msg.sender` and a `nonce` (that can 
be incremented to create different _arbitrary token accounts_). The owner of the _arbitrary token account_ is the 
**CallSPLTokenProgram** contract. The `transferTokens` function grants `msg.sender` permission to transfer tokens from 
this _arbitrary token account_ by providing the `nonce` that was used to create the _arbitrary token account_.

* To create and initialize an _arbitrary token account_ to be used by a third party `user` NeonEVM account through 
the **CallSPLTokenProgram** contract. In this case, the `owner` parameter passed to the function should be  
`CallSPLTokenProgram.getNeonAddress(user)` and the `tokenOwner` parameter should be left empty. The _arbitrary token 
account_ to be created is derived from the `user` account and a `nonce` (that can be incremented to create different
  _arbitrary token accounts_). The owner of the _arbitrary token account_ is the **CallSPLTokenProgram** contract. The 
`transferTokens` function grants `user` permission to transfer tokens from this _arbitrary token account_ by providing 
the `nonce` that was used to create the _arbitrary token account_.

* To create and initialize an _arbitrary token account_ to be used by a third party `solanaUser` _Solana_ account
to send tokens directly on _Solana_ without interacting with the **CallSPLTokenProgram** contract. In this case, both the 
`owner` and the `tokenOwner` parameters passed to the function should be `solanaUser`. The _arbitrary token account_ to 
be created is derived from the `solanaUser` account and a `nonce` (that can be incremented to create different 
_arbitrary token accounts_). The owner of the _arbitrary token account_ is the `solanaUser` account. The `solanaUser` 
account cannot transfer tokens from this _arbitrary token account_ by interacting with the **CallSPLTokenProgram** 
contract, instead it must interact directly with the **SPL Token** program on _Solana_ by signing and executing a 
`transfer` instruction.

## Tests

Contracts are deployed at the beginning of each test unless the `config.js` file already contains the contract address.

The `system.test.js` and `spl-token.test.js` test cases can be run on either _Curvestand_ test network or _Neon devnet_ 
using the following commands:

`npx hardhat test ./tests/composability/system.test.js --network < curvestand or neondevnet >`

`npx hardhat test ./tests/composability/spl-token.test.js --network < curvestand or neondevnet >`

The `raydium.test.js` and `raydium-create-pool-and-lock-LP.test.js` test cases can only be run on _Neon devnet_ using the 
following commands:

`npx hardhat test ./tests/composability/raydium.test.js --network neondevnet`

`npx hardhat test ./tests/composability/raydium-create-pool-and-lock-LP.test.js --network neondevnet`





