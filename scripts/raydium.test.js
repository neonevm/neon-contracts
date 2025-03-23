// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers } = require("hardhat");
const web3 = require("@solana/web3.js");
const {
    getAccount,
    getAssociatedTokenAddress
} = require('@solana/spl-token');

async function main() {
    const [owner] = await ethers.getSigners();
    const connection = new web3.Connection("https://api.devnet.solana.com", "processed");

    let CallRaydiumProgramAddress = "0xEEDb4C7B1BB91Df85DDD314A62A87AebC058eBDe";
    const CallRaydiumProgramFactory = await ethers.getContractFactory("CallRaydiumProgram");
    let CallRaydiumProgram;

    if (ethers.isAddress(CallRaydiumProgramAddress)) {
        CallRaydiumProgram = CallRaydiumProgramFactory.attach(
            CallRaydiumProgramAddress
        );
    } else {
        CallRaydiumProgram = await ethers.deployContract("CallRaydiumProgram");
        await CallRaydiumProgram.waitForDeployment();
        CallRaydiumProgramAddress = CallRaydiumProgram.target;

        console.log(
            `CallRaydiumProgram deployed to ${CallRaydiumProgram.target}`
        );
    }

    console.log(await CallRaydiumProgram.getNeonAddress(CallRaydiumProgram.target), 'getNeonAddress');
    const payer = await CallRaydiumProgram.getPayer();
    console.log(payer, 'getPayer');
    const tokenA = 'So11111111111111111111111111111111111111112';
    const tokenB = 'GDjDoYF47Es9ffM4h17nHSmJy1hxcQv8YZwUTDpegZov';

    /* let tx = await CallRaydiumProgram.createPoolAndLockLP(
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenA)), 32),
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenB)), 32),
        20000000,
        10000000,
        0,
        ethers.zeroPadValue(ethers.toBeHex(owner.address), 32), // salt
        false
    );
    await tx.wait(1);
    console.log(tx, 'tx');
    return; */

    // CREATE POOL EXAMPLE
    /* let tx = await CallRaydiumProgram.createPool(
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenA)), 32),
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenB)), 32),
        20000000,
        10000000,
        0
    );
    await tx.wait(1);
    console.log(tx, 'tx');
    return; */


    const poolId = '2amySAHQBitNonz5NAjcuTbRroUUsVUkrKfr38QXt5Zc';
    const poolData = await CallRaydiumProgram.getPoolData(
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenA)), 32),
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenB)), 32),
    );
    console.log(poolData, 'getPoolData');

    
    const getPdaLpMint = await CallRaydiumProgram.getPdaLpMint(ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32));
    const lpMintATA = await getAssociatedTokenAddress( // calculates Token Account PDA of some account
        new web3.PublicKey(ethers.encodeBase58(getPdaLpMint)),
        new web3.PublicKey(ethers.encodeBase58(await CallRaydiumProgram.getPayer())),
        true
    );
    const poolTokens = [poolData[5], poolData[6]];
    console.log(poolTokens, 'getPoolTokens');
    console.log(await CallRaydiumProgram.getTokenReserve(ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32), poolTokens[0]), 'reserve 0');
    console.log(await CallRaydiumProgram.getTokenReserve(ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32), poolTokens[1]), 'reserve 1');

    /* const baseReserve = await CallRaydiumProgram.getTokenReserve(ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32), poolTokens[0]);
    const quoteReserve = await CallRaydiumProgram.getTokenReserve(ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32), poolTokens[1]);
    const totalLpAmount = await CallRaydiumProgram.getPoolLpAmount(ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32));
    const slippage = 0.99;
    const lpAmount = 0; // change value
    const amountMintA = ((lpAmount * parseInt(baseReserve)) / parseInt(totalLpAmount)) * slippage;
    const amountMintB = ((lpAmount * parseInt(quoteReserve)) / parseInt(totalLpAmount)) * slippage;
    console.log(amountMintA, 'amountMintA');
    console.log(amountMintB, 'amountMintB'); */

    const inputAmount = 0.0025 * 10 ** 9;
    const baseIn = false;
    const lpDivisor = (baseIn) ? 
    await CallRaydiumProgram.getTokenReserve(ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32), poolTokens[0]) : 
    await CallRaydiumProgram.getTokenReserve(ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32), poolTokens[1]);
    const poolLpAmount = await CallRaydiumProgram.getPoolLpAmount(ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32));
    const lpAmount = (BigInt(inputAmount) * poolLpAmount) / lpDivisor;
    console.log(poolLpAmount, 'poolLpAmount');
    console.log(lpAmount, 'lpAmount');
    const lpToAmount = await CallRaydiumProgram.lpToAmount(
        lpAmount,
        await CallRaydiumProgram.getTokenReserve(ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32), poolTokens[0]),
        await CallRaydiumProgram.getTokenReserve(ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32), poolTokens[1]),
        poolLpAmount
    );
    console.log(lpToAmount, 'lpToAmount');

    // ADD LIQUDITY EXAMPLE
    tx = await CallRaydiumProgram.addLiquidity(
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32),
        inputAmount,
        baseIn,
        1
    );
    await tx.wait(1);
    console.log(tx, 'tx ADD LP');

    // WITHDRAW LIQUDITY EXAMPLE
    tx = await CallRaydiumProgram.withdrawLiquidity(
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32),
        parseInt(parseInt((await getAccount(connection, lpMintATA)).amount) / 2),
        1
    );
    await tx.wait(1);
    console.log(tx, 'tx WITHDRAW LP');

    // LOCK LIQUDITY EXAMPLE
    const salt = ethers.zeroPadValue(ethers.toBeHex(ethers.Wallet.createRandom().address), 32);
    tx = await CallRaydiumProgram.lockLiquidity(
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32),
        parseInt(parseInt((await getAccount(connection, lpMintATA)).amount) / 5),
        true,
        salt
    );
    await tx.wait(1);
    console.log(tx, 'tx LOCK LP');

    // CLAIM FEES EXAMPLE
    tx = await CallRaydiumProgram.collectFees(
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32),
        99999999,
        salt
    );
    await tx.wait(1);
    console.log(tx, 'tx CLAIM FEES');

    // SWAP INPUT & OUTPUT EXAMPLES
    console.log(await CallRaydiumProgram.getSwapOutput(
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32),
        poolData[0],
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenA)), 32),
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenB)), 32),
        20000
    ), 'getSwapOutput');

    console.log(await CallRaydiumProgram.getSwapInput(
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32),
        poolData[0],
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenB)), 32),
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenA)), 32),
        20000
    ), 'getSwapOutput');

    tx = await CallRaydiumProgram.swapOutput(
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32),
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenB)), 32),
        20000,
        1
    );
    await tx.wait(1);
    console.log(tx, 'tx SWAP OUTPUT');

    tx = await CallRaydiumProgram.swapInput(
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(poolId)), 32),
        ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenB)), 32),
        20000,
        1
    );
    await tx.wait(1);
    console.log(tx, 'tx SWAP INPUT');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});