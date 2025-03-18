const { network, ethers} = require("hardhat");
const { expect } = require("chai");
const web3 = require("@solana/web3.js");
const { getAccount, TOKEN_PROGRAM_ID, ACCOUNT_SIZE } = require("@solana/spl-token");
const { deployContract } = require("./utils");

describe('\u{1F680} \x1b[36mSystem program composability tests\x1b[33m',  async function() {

    console.log("Network name: " + network.name)

    const solanaConnection = new web3.Connection(process.env.SOLANA_NODE, "processed")

    const ZERO_AMOUNT = BigInt(0)
    const ZERO_BYTES32 = Buffer.from('0000000000000000000000000000000000000000000000000000000000000000', 'hex')
    let deployer,
        neonEVMUser,
        callSystemProgram,
        tx,
        seed,
        basePubKey,
        rentExemptBalance,
        createWithSeedAccountInBytes,
        info

    before(async function() {
        const deployment = await deployContract('CallSystemProgram', null)
        deployer = deployment.deployer
        neonEVMUser = deployment.user
        callSystemProgram = deployment.contract

        basePubKey = await callSystemProgram.getNeonAddress(callSystemProgram.target)
        rentExemptBalance = await solanaConnection.getMinimumBalanceForRentExemption(ACCOUNT_SIZE)
    })

    describe('\n\u{231B} \x1b[33m Testing on-chain formatting and execution of Solana\'s System program \x1b[36mcreateAccountWithSeed\x1b[33m instruction\x1b[0m', function() {

        it('Create account with seed', async function() {

            seed = 'seed' + Date.now().toString()

            createWithSeedAccountInBytes = await callSystemProgram.getCreateWithSeedAccount(
                basePubKey,
                TOKEN_PROGRAM_ID.toBuffer(),
                Buffer.from(seed)
            )

            tx = await callSystemProgram.createAccountWithSeed(
                TOKEN_PROGRAM_ID.toBuffer(), // SPL token program
                Buffer.from(seed),
                ACCOUNT_SIZE, // SPL token account data size
                rentExemptBalance  // SPL token account minimum balance for rent exemption
            )
            await tx.wait(1) // Wait for 1 confirmation

            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(createWithSeedAccountInBytes)))
            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(createWithSeedAccountInBytes))
            expect(info.mint.toBase58()).to.eq(ethers.encodeBase58(ZERO_BYTES32))
            expect(info.owner.toBase58()).to.eq(ethers.encodeBase58(ZERO_BYTES32))
            expect(info.delegate).to.eq(null)
            expect(info.closeAuthority).to.eq(null)
            expect(info.amount).to.eq(ZERO_AMOUNT)
            expect(info.delegatedAmount).to.eq(ZERO_AMOUNT)
            expect(info.isInitialized).to.eq(false)
            expect(info.isFrozen).to.eq(false)
            expect(info.isNative).to.eq(false)
            expect(info.rentExemptReserve).to.eq(null)
            expect(info.tlvData.length).to.eq(0)
        })
    })
})
