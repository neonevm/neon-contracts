const { ethers, network, run } = require("hardhat")
const web3 = require("@solana/web3.js")
const { deployContract, getSolanaTransactions } = require("./utils")
const { getAccount } = require("@solana/spl-token")
const config = require("./config");

async function main(callSPLTokenProgramContractAddress = null) {
    await run("compile")

    console.log("\n\u{231B}", "\x1b[33m Testing on-chain \x1b[36mgetters\x1b[33m of Solana's SPL Token accounts data\x1b[0m")

    console.log("\nNetwork name: " + network.name)

    const solanaConnection = new web3.Connection(process.env.SOLANA_NODE, "processed")

    const { deployer, contract: callSPLTokenProgram } = await deployContract('CallSPLTokenProgram', callSPLTokenProgramContractAddress)

    // ============================================= Read SPL Token data ===============================================

    const tokenMintInBytes =  await callSPLTokenProgram.getTokenMintAccount(deployer.address, Buffer.from(config.tokenMintSeed[network.name]))
    const deployerPublicKeyInBytes = await callSPLTokenProgram.getNeonAddress(deployer.address)
    const deployerATAInBytes = await callSPLTokenProgram.getAssociatedTokenAccount(
        tokenMintInBytes,
        deployerPublicKeyInBytes,
    )

    console.log('\nCalling callSPLTokenProgram.getSPLTokenAccountBalance: ')
    let result = await callSPLTokenProgram.getSPLTokenAccountBalance(deployerATAInBytes);
    console.log(result, '<-- deployer ATA balance')

    console.log('\nCalling callSPLTokenProgram.getSPLTokenAccountOwner: ')
    result = await callSPLTokenProgram.getSPLTokenAccountOwner(deployerATAInBytes);
    console.log(ethers.encodeBase58(result), '<-- deployer ATA owner')

    console.log('\nCalling callSPLTokenProgram.getSPLTokenAccountMint: ')
    result = await callSPLTokenProgram.getSPLTokenAccountMint(deployerATAInBytes);
    console.log(ethers.encodeBase58(result), '<-- deployer ATA mint')

    console.log('\nCalling callSPLTokenProgram.getSPLTokenAccountDelegate: ')
    result = await callSPLTokenProgram.getSPLTokenAccountDelegate(deployerATAInBytes);
    console.log(ethers.encodeBase58(result), '<-- deployer ATA delegate')

    console.log('\nCalling callSPLTokenProgram.getSPLTokenAccountDelegatedAmount: ')
    result = await callSPLTokenProgram.getSPLTokenAccountDelegatedAmount(deployerATAInBytes);
    console.log(result, '<-- deployer ATA delegated amount')

    console.log('\nCalling callSPLTokenProgram.getSPLTokenAccountIsInitialized: ')
    result = await callSPLTokenProgram.getSPLTokenAccountIsInitialized(deployerATAInBytes);
    console.log(result, '<-- deployer ATA isInitialized')

    console.log('\nCalling callSPLTokenProgram.getSPLTokenAccountIsNative: ')
    result = await callSPLTokenProgram.getSPLTokenAccountIsNative(deployerATAInBytes);
    console.log(result, '<-- deployer ATA isNative')

    console.log('\nCalling callSPLTokenProgram.getSPLTokenAccountCloseAuthority: ')
    result = await callSPLTokenProgram.getSPLTokenAccountCloseAuthority(deployerATAInBytes);
    console.log(result, '<-- deployer ATA closeAuthority')

    console.log('\nCalling callSPLTokenProgram.getSPLTokenAccountData: ')
    result = await callSPLTokenProgram.getSPLTokenAccountData(deployerATAInBytes);
    console.log(result, '<-- deployer ATA data')

    return(callSPLTokenProgram.target)
}

module.exports = {
    main
}
