# Solidity libraries for composability with _Solana_'s Raydium CPMM program

## LibRaydiumProgram library
This library provides helper functions for formatting instructions to be executed by _Solana_'s **Raydium** 
program.

### Available Raydium CPMM program instructions
* `createPool` - Deploying CPMM pool on Raydium for selected tokens pair. [Info](LibRaydiumProgram.sol#L29)
* `addLiquidity` - Adding liquidity for selected tokens pair. [Info](LibRaydiumProgram.sol#L136)
* `withdrawLiquidity` - Withdrawing liquidity from selected tokens pair. [Info](LibRaydiumProgram.sol#L232)
* `lockLiquidity` - Locking liquidity position. [Info](LibRaydiumProgram.sol#L319)
* `collectFees` - Collecting fees for locked LP position. [Info](LibRaydiumProgram.sol#L429)
* `swapInput` - Swapping exact token input amount, example - swap 100 tokensA for X tokensB. [Info](LibRaydiumProgram.sol#L531)
* `swapOutput` - Swapping tokens to exact token output amount, example - swap X tokensA for 100 tokensB. [Info](LibRaydiumProgram.sol#L580)

## LibRaydiumProgramData library
This library provides a set of getter functions for querying different accounts & data. Also some calculations such as swap input or output amount; convert LP amount to tokens amounts; etc. Here are some of the getters:
* `getPoolData` - Returns the data of Raydium CPMM pool. [Info](LibRaydiumProgramData.sol#L148)
* `getConfigData` - Returns the data for requested config index. [Info](LibRaydiumProgramData.sol#L171)
* `getTokenReserve` - Returns pool token reserve for selected token mint. [Info](LibRaydiumProgramData.sol#L192)
* `getPoolLpAmount` - Returns the pool's LP amount. [Info](LibRaydiumProgramData.sol#L197)
* `lpToAmount` - Converts LP amount to reserves amounts. [Info](LibRaydiumProgramData.sol#L202)
* `getSwapOutput` - Returns a swap quote of provided exact input amount. [Info](LibRaydiumProgramData.sol#L222)
* `getSwapInput` - Returns a swap quote of provided exact output amount. [Info](LibRaydiumProgramData.sol#L238)


## LibRaydiumProgramErrors library
This library provides a set of custom errors that may be thrown when using **LibRaydiumProgram** and **LibRaydiumProgramData** 
libraries.