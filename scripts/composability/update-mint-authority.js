const { ethers, network, run } = require("hardhat")
const web3 = require("@solana/web3.js")
const { getMint } = require('@solana/spl-token')
const { deployContract, getSolanaTransactions } = require("./utils")
const config = require("./config");

async function main(callSPLTokenProgramContractAddress = null) {
    await run("compile")

    console.log("\n\u{231B}", "\x1b[33m Testing on-chain formatting and execution of Solana's SPL Token program's \x1b[36mcreateSetAuthority\x1b[33m instruction\x1b[0m")

    console.log("\nNetwork name: " + network.name)

    const solanaConnection = new web3.Connection(process.env.SOLANA_NODE, "processed")

    const { deployer, contract: callSPLTokenProgram } = await deployContract('CallSPLTokenProgram', callSPLTokenProgramContractAddress)

    // =================================== Update SPL token mint authority ====================================

    const newAuthority = (await web3.Keypair.generate()).publicKey.toBuffer()
    const seed = config.tokenMintSeed[network.name]

    console.log('\nCalling callSPLTokenProgram.updateMintAuthority: ')

    let tx = await callSPLTokenProgram.updateMintAuthority(
        Buffer.from(seed), // Seed that was used to generate SPL token mint
        newAuthority,
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

    console.log("\n")

    const tokenMintInBytes =  await callSPLTokenProgram.getTokenMintAccount(deployer.address, Buffer.from(config.tokenMintSeed[network.name]))
    console.log(ethers.encodeBase58(tokenMintInBytes), '<-- token mint to update\n')
    const info = await getMint(solanaConnection, new web3.PublicKey(ethers.encodeBase58(tokenMintInBytes)))
    console.log(info, '<-- updated token mint info')

    console.log("\n\u{2705} \x1b[32mSuccess!\x1b[0m\n")

    return(callSPLTokenProgram.target)
}

module.exports = {
    main
}
