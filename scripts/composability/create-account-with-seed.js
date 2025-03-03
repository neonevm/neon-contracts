const { ethers, network, run } = require("hardhat")
const web3 = require("@solana/web3.js")
const { ACCOUNT_SIZE, TOKEN_PROGRAM_ID } = require("@solana/spl-token")
const { deployContract, getSolanaTransactions } = require("./utils")

async function main(callSystemProgramContractAddress = null) {
    await run("compile")

    console.log("\n\u{231B}", "\x1b[33m Testing on-chain formatting and execution of Solana's System program's \x1b[36mcreateAccountWithSeed\x1b[33m instruction\x1b[0m")

    console.log("\nNetwork name: " + network.name)

    const { contract: callSystemProgram } = await deployContract('CallSystemProgram', callSystemProgramContractAddress)

    const solanaConnection = new web3.Connection(process.env.SOLANA_NODE, "processed")

    const rentExemptBalance = await solanaConnection.getMinimumBalanceForRentExemption(ACCOUNT_SIZE)
    const seed = 'seed' + Date.now().toString()
    const basePubKey = await callSystemProgram.getNeonAddress(callSystemProgram.target)
    const createWithSeedAccount = await callSystemProgram.getCreateWithSeedAccount(
        basePubKey,
        TOKEN_PROGRAM_ID.toBuffer(),
        Buffer.from(seed)
    )
    console.log('\n' + ethers.encodeBase58(createWithSeedAccount), 'createWithSeedAccount')

    console.log('\nCalling callSystemProgram.createAccountWithSeed: ')

    // Here we create a SPL token account
    let tx = await callSystemProgram.createAccountWithSeed(
        TOKEN_PROGRAM_ID.toBuffer(), // SPL token program
        Buffer.from(seed),
        ACCOUNT_SIZE, // SPL token account data size
        rentExemptBalance  // SPL token account minimum balance for rent exemption
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

    console.log("\n\u{2705} \x1b[32mSuccess!\x1b[0m\n")

    return(callSystemProgram.target)
}

module.exports = {
    main
}
