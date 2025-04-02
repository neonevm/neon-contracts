# Solidity libraries for composability with _Solana_'s Raydium CPMM program

## LibRaydiumProgram library
This library provides helper functions for formatting instructions to be executed by _Solana_'s **Raydium** 
program.

### Available Raydium CPMM program instructions
* `createPool` - Deploying CPMM pool on Raydium for selected tokens pair. [Info](LibRaydiumProgram.sol#L29)
* `addLiquidity` - Adding liquidity for selected tokens pair. [Info](LibRaydiumProgram.sol#L135)
* `withdrawLiquidity` - Withdrawing liquidity from selected tokens pair. [Info](LibRaydiumProgram.sol#L230)
* `lockLiquidity` - Locking liquidity position. [Info](LibRaydiumProgram.sol#L316)
* `collectFees` - Collecting fees for locked LP position. [Info](LibRaydiumProgram.sol#L424)
* `swapInput` - Swapping exact token input amount, example - swap 100 tokensA for X tokensB. [Info](LibRaydiumProgram.sol#L524)
* `swapOutput` - Swapping tokens to exact token output amount, example - swap X tokensA for 100 tokensB. [Info](LibRaydiumProgram.sol#L571)

## LibRaydiumData library
This library provides a set of getter functions for querying different accounts & data. Also some calculations such as swap input or output amount; convert LP amount to tokens amounts; etc. Here are some of the getters:
* `getPoolData` - Returns the data of Raydium CPMM pool. [Info](LibRaydiumData.sol#L150)
* `getConfigData` - Returns the data for requested config index. [Info](LibRaydiumData.sol#L173)
* `getTokenReserve` - Returns pool token reserve for selected token mint. [Info](LibRaydiumData.sol#L194)
* `getPoolLpAmount` - Returns the pool's LP amount. [Info](LibRaydiumData.sol#L199)
* `lpToAmount` - Converts LP amount to reserves amounts. [Info](LibRaydiumData.sol#L204)
* `getSwapOutput` - Returns a swap quote of provided exact input amount. [Info](LibRaydiumData.sol#L224)
* `getSwapInput` - Returns a swap quote of provided exact output amount. [Info](LibRaydiumData.sol#L240)


## LibRaydiumErrors library
This library provides a set of custom errors that may be thrown when using **LibRaydiumProgram** and **LibRaydiumData** 
libraries.