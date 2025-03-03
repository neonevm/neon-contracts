const { ethers, network, run } = require("hardhat")
const web3 = require("@solana/web3.js")
const { deployContract, getSolanaTransactions } = require("./utils")
const config = require("./config");

async function main(callSPLTokenProgramContractAddress = null) {
    await run("compile")

    console.log("\n\u{231B}", "\x1b[33m Testing on-chain formatting and execution of Solana's SPL Token program's \x1b[36mmintTo\x1b[33m instruction\x1b[0m")

    console.log("\nNetwork name: " + network.name)

    const { deployer, contract: callSPLTokenProgram } = await deployContract('CallSPLTokenProgram', callSPLTokenProgramContractAddress)

    // =================================== Mint SPL token amount to deployer ATA ====================================

    const seed = config.tokenMintSeed[network.name]
    const tokenMintInBytes =  await callSPLTokenProgram.getTokenMintAccount(deployer.address, Buffer.from(seed))
    const decimals = config.tokenMintDecimals[network.name]
    const deployerPublicKeyInBytes = await callSPLTokenProgram.getNeonAddress(deployer.address)
    const deployerATA = await callSPLTokenProgram.getAssociatedTokenAccount(
        tokenMintInBytes,
        deployerPublicKeyInBytes,
    )

    console.log('\nCalling callSPLTokenProgram.mintTokens: ')

    let tx = await callSPLTokenProgram.connect(deployer).mintTokens(
        Buffer.from(seed), // Seed that was used to generate SPL token mint
        deployerATA, // Solana recipient ATA
        1000 * 10 ** decimals // amount (mint 1000 tokens)
    )

    console.log('\nNeonEVM transaction hash: ' + tx.hash)
    await tx.wait(1) // Wait for 1 confirmation
    let txReceipt = await ethers.provider.getTransactionReceipt(tx.hash)
    console.log(txReceipt.status, 'txReceipt.status')

    let solanaTransactions = (await (await getSolanaTransactions(tx.hash)).json()).result

    console.log('\nSolana transactions signatures:')
    for await (let txId of solanaTransactions) {
        console.log(txId)
    }
    console.log('\n')

    const solanaConnection = new web3.Connection(process.env.SOLANA_NODE, "processed")
    const info = await solanaConnection.getTokenAccountBalance(
        new web3.PublicKey(ethers.encodeBase58(deployerATA))
    )
    console.log(info, '<-- deployer ATA info')

    console.log("\n\u{2705} \x1b[32mSuccess!\x1b[0m\n")

    return(callSPLTokenProgram.target)
}

module.exports = {
    main
}
