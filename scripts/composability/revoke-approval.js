const { ethers, network, run } = require("hardhat")
const web3 = require("@solana/web3.js")
const { deployContract, getSolanaTransactions } = require("./utils")
const { getAccount } = require("@solana/spl-token")
const config = require("./config");

async function main(callSPLTokenProgramContractAddress = null) {
    await run("compile")

    console.log("\n\u{231B}", "\x1b[33m Testing on-chain formatting and execution of Solana's SPL Token program's \x1b[36mrevoke\x1b[33m instruction\x1b[0m")

    console.log("\nNetwork name: " + network.name)

    const solanaConnection = new web3.Connection(process.env.SOLANA_NODE, "processed")

    const { deployer, contract: callSPLTokenProgram } = await deployContract('CallSPLTokenProgram', callSPLTokenProgramContractAddress)

    // =================================== Delegate deployer ATA to NeonEVM user ====================================

    const tokenMintInBytes =  await callSPLTokenProgram.getTokenMintAccount(deployer.address, Buffer.from(config.tokenMintSeed[network.name]))
    const deployerPublicKeyInBytes = await callSPLTokenProgram.getNeonAddress(deployer.address)
    const deployerATAInBytes = await callSPLTokenProgram.getAssociatedTokenAccount(
        tokenMintInBytes,
        deployerPublicKeyInBytes,
    )

    // =================================== Revoke all delegation from deployer ATA ====================================

    console.log('\nCalling callSPLTokenProgram.revokeApproval: ')

    let tx = await callSPLTokenProgram.connect(deployer).revokeApproval(
        tokenMintInBytes,
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

    let info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes)))
    console.log(info, '<-- deployer ATA info after revoke')

    console.log("\n\u{2705} \x1b[32mSuccess!\x1b[0m\n")

    return(callSPLTokenProgram.target)
}

module.exports = {
    main
}
