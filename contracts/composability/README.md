# Solidity libraries for NeonEVM composability

The composability feature allows dApps deployed on _NeonEVM_ to interact with _Solana_ programs, which involves 
formatting instructions in ways that are specific to each program.

Here we provide a set of **Solidity** libraries which make it possible to easily implement secure interactions with 
_Solana_'s **System** and **SPL Token** programs.

This work is an example of what program-specific **Solidity** libraries for _NeonEVM_ composability could look like.

## LibSystemProgram library

This library provides helper functions for formatting instructions intended to be executed by _Solana_'s **System** 
program.

## LibSPLTokenProgram library

This library provides helper functions for formatting instructions intended to be executed by _Solana_'s **SPL Token** 
program.

## LibSPLTokenData library

This library provides a set of getter functions for querying SPL Token accounts data from Solana.

## CallSystemProgram contract

This contract demonstrates how the **LibSystemProgram** library can be used in practice to interact with Solana's System 
program.

## CallSPLTokenProgram contract

This contract demonstrates how the **LibSPLTokenProgram** library can be used in practice to interact with Solana's SPL 
Token program.

### Token accounts ownership and authentication

The **CallSPLTokenProgram** contract provides its users with methods to create and initialize SPL token mints and 
associated token accounts, as well as to mint and transfer tokens using those accounts. It features a built-in 
authentication logic ensuring that users remain in control of created accounts.

#### SPL token mint ownership and authentication

The `createInitializeTokenMint` function takes a `seed` parameter as input which is used along with 
`msg.sender` to derive the created token mint account. While the **CallSPLTokenProgram** contract is given mint/freeze 
authority on the created token mint account, the `mintTokens` function grants `msg.sender` permission to mint tokens
by providing the `seed` that was used to create the token mint account.

#### Associated token account ownership and authentication

The `createInitializeATA` function can be used for three different purposes:

* To create and initialize an associated token account (ATA) to be used by `msg.sender` to send tokens through the 
**CallSPLTokenProgram** contract. In this case, both the `owner` and `tokenOwner` parameters passed to the function 
should be left empty. The ATA to be created is derived from `msg.sender` and a `nonce` (that can be incremented to 
create different ATAs). The owner of the ATA is the **CallSPLTokenProgram** contract. The `transferTokens` function 
grants `msg.sender` permission to transfer tokens from this ATA by providing the `nonce` that was used to create the ATA.

* To create and initialize an associated token account (ATA) to be used by a third party `user` NeonEVM account through 
the **CallSPLTokenProgram** contract. In this case, the `owner` parameter passed to the function should be  
`CallSPLTokenProgram.getNeonAddress(user)` and the `tokenOwner` parameter should be left empty. The ATA to be created is 
derived from the `user` account and a `nonce` (that can be incremented to create different ATAs). The owner of the ATA 
is the **CallSPLTokenProgram** contract. The `transferTokens` function grants `user` permission to transfer tokens 
from this ATA by providing the `nonce` that was used to create the ATA.

* To create and initialize an associated token account (ATA) to be used by a third party `solanaUser` _Solana_ account
to send tokens directly on _Solana_ without interacting with the **CallSPLTokenProgram** contract. In this case, both the 
`owner` and the `tokenOwner` parameters passed to the function should be `solanaUser`. The ATA to be created is derived 
from the `solanaUser` account and a `nonce` (that can be incremented to create different ATAs). The owner of the ATA is 
the `solanaUser` account. The `solanaUser` account cannot transfer tokens from this ATA by interacting with the 
**CallSPLTokenProgram** contract, instead it must interact directly with the **SPL Token** program on _Solana_ by signing 
and executing a `transfer` instruction.

## Tests

The `CallSystemProgram` or `CallSPLTokenProgram` contract is deployed at the beginning of each test, unless the 
`config.js` file already contains an address for this contract.

To run all composability test cases on _Curvestand_ test network:

`npm run test-composability-curvestand`

