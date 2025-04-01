# Solidity libraries for composability with _Solana_'s Raydium program

## LibRaydium library
This library provides helper functions for formatting instructions to be executed by _Solana_'s **Raydium** 
program.

### Available SPL Token program instructions
* `createPool` - Deploying CPMM pool on Raydium for selected tokens pair. [Info](LibRaydium.sol#L29)
* `addLiquidity` - Adding liquidity for selected tokens pair. [Info](LibRaydium.sol#L136)
* `withdrawLiquidity` - Withdrawing liquidity from selected tokens pair. [Info](LibRaydium.sol#L232)
* `lockLiquidity` - Locking liquidity position. [Info](LibRaydium.sol#L319)
* `collectFees` - Collecting fees for locked LP position. [Info](LibRaydium.sol#L429)
* `swapInput` - Swapping exact token input amount, example - swap 100 tokensA for X tokensB. [Info](LibRaydium.sol#L531)
* `swapOutput` - Swapping tokens to exact token output amount, example - swap X tokensA for 100 tokensB. [Info](LibRaydium.sol#L580)

## LibRaydiumData library
This library provides a set of getter functions for querying different accounts & data. Also some calculations such as swap input or output amount; convert LP amount to tokens amounts; etc. Here are some of the getters:
* `getPoolData` - Returns the data of Raydium CPMM pool. [Info](LibRaydiumData.sol#148)
* `getConfigData` - Returns the data for requested config index. [Info](LibRaydiumData.sol#171)
* `getTokenReserve` - Returns pool token reserve for selected token mint. [Info](LibRaydiumData.sol#192)
* `getPoolLpAmount` - Returns the pool's LP amount. [Info](LibRaydiumData.sol#197)
* `lpToAmount` - Converts LP amount to reserves amounts. [Info](LibRaydiumData.sol#202)
* `getSwapOutput` - Returns a swap quote of provided exact input amount. [Info](LibRaydiumData.sol#222)
* `getSwapInput` - Returns a swap quote of provided exact output amount. [Info](LibRaydiumData.sol#238)


## LibRaydiumErrors library
This library provides a set of custom errors that may be thrown when using **LibRaydium** and **LibRaydiumData** 
libraries.