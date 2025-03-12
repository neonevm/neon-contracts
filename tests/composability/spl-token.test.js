const { network, ethers} = require("hardhat");
const { expect } = require("chai");
const web3 = require("@solana/web3.js");
const { getMint, getAccount } = require("@solana/spl-token");
const config = require("./config");
const { deployContract, airdropSOL } = require("./utils");

describe('\u{1F680} \x1b[36mSPL Token program composability tests\x1b[33m',  function() {

    console.log("Network name: " + network.name)

    const solanaConnection = new web3.Connection(process.env.SOLANA_NODE, "processed")

    const seed = config.tokenMintSeed[network.name]
    const decimals = config.tokenMintDecimals[network.name]
    const AMOUNT = ethers.parseUnits('1000', decimals)
    const SMALL_AMOUNT = ethers.parseUnits('100', decimals)
    const ZERO_AMOUNT = BigInt(0)
    const ZERO_BYTES32 = Buffer.from('0000000000000000000000000000000000000000000000000000000000000000', 'hex')
    const ZERO_BYTE =  Buffer.from('00', 'hex')
    const ONE_BYTE =  Buffer.from('01', 'hex')
    const ZERO_BYTES8 =  Buffer.from('0000000000000000', 'hex')
    const ONE_BYTES8 =  Buffer.from('0000000000000001', 'hex')
    const WSOL_MINT_PUBKEY = Buffer.from('069b8857feab8184fb687f634618c035dac439dc1aeb3b5598a0f00000000001', 'hex')

    let deployer,
        neonEVMUser,
        otherNeonEVMUser,
        callSPLTokenProgram,
        tx,
        contractPublicKeyInBytes,
        deployerPublicKeyInBytes,
        neonEVMUserPublicKeyInBytes,
        otherNeonEVMUserPublicKeyInBytes,
        solanaUserPublicKey,
        tokenMintInBytes,
        deployerATAInBytes,
        deployerWSOLATAInBytes,
        neonEVMUserATAInBytes,
        solanaUserATAInBytes,
        newMintAuthorityInBytes,
        newFreezeAuthorityInBytes,
        newOwnerInBytes,
        newCloseAuthorityInBytes,
        initialDeployerBalance,
        newDeployerBalance,
        initialDeployerATABalance,
        newDeployerATABalance,
        initialDeployerATASOLBalance,
        newDeployerATASOLBalance,
        initialDeployerATAwSOLBalance,
        newDeployerATAwSOLBalance,
        initialNeonEVMUserATABalance,
        newNeonEVMUserATABalance,
        initialSolanaUserATABalance,
        info

    before(async function() {
        const deployment = await deployContract('CallSPLTokenProgram', null)
        deployer = deployment.deployer
        neonEVMUser = deployment.user
        otherNeonEVMUser = deployment.otherUser
        callSPLTokenProgram = deployment.contract
    })

    describe('\n\u{231B} \x1b[33m Testing on-chain formatting and execution of Solana\'s SPL Token program\'s \x1b[36minitializeMint2\x1b[33m instruction\x1b[0m', function() {

        it('Create and initialize new SPL token mint', async function() {
            tx = await callSPLTokenProgram.connect(deployer).createInitializeTokenMint(
                Buffer.from(seed), // Seed to generate new SPL token mint account on-chain
                decimals, // Decimals value for the new SPL token to be created on Solana
            )
            await tx.wait(1) // Wait for 1 confirmation

            tokenMintInBytes =  await callSPLTokenProgram.getTokenMintAccount(deployer.address, Buffer.from(seed))
            contractPublicKeyInBytes =  await callSPLTokenProgram.getNeonAddress(callSPLTokenProgram.target)
            info = await getMint(solanaConnection, new web3.PublicKey(ethers.encodeBase58(tokenMintInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))
            expect(info.mintAuthority.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.freezeAuthority.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.supply).to.eq(ZERO_AMOUNT)
            expect(info.decimals).to.eq(decimals)
            expect(info.isInitialized).to.eq(true)
            expect(info.tlvData.length).to.eq(0)
        })
    })

    describe('\n\u{231B} \x1b[33m Testing on-chain formatting and execution of Solana\'s SPL Token program\'s \x1b[36minitializeAccount2\x1b[33m instruction\x1b[0m', function() {

        it('Create and initialize new ATA for deployer', async function() {
            tx = await callSPLTokenProgram.connect(deployer).createInitializeATA(
                tokenMintInBytes,
                Buffer.from('0000000000000000000000000000000000000000000000000000000000000000', 'hex'), // Leave owner field empty so that msg.sender controls the ATA through CallSPLTokenProgram contract
                Buffer.from('0000000000000000000000000000000000000000000000000000000000000000', 'hex'), // Leave tokenOwner field empty so that CallSPLTokenProgram contract owns the ATA
            )
            await tx.wait(1) // Wait for 1 confirmation

            deployerPublicKeyInBytes = await callSPLTokenProgram.getNeonAddress(deployer.address)
            deployerATAInBytes = await callSPLTokenProgram.getAssociatedTokenAccount(
                tokenMintInBytes,
                deployerPublicKeyInBytes,
            )
            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(deployerATAInBytes))
            expect(info.mint.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))
            expect(info.owner.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.delegate).to.be.null
            expect(info.closeAuthority).to.be.null
            expect(info.amount).to.eq(ZERO_AMOUNT)
            expect(info.delegatedAmount).to.eq(ZERO_AMOUNT)
            expect(info.isInitialized).to.eq(true)
            expect(info.isFrozen).to.eq(false)
            expect(info.isNative).to.eq(false)
            expect(info.rentExemptReserve).to.be.null
            expect(info.tlvData.length).to.eq(0)
        })

        it('Create and initialize new ATA for third party NeonEVM user', async function() {

            neonEVMUserPublicKeyInBytes = await callSPLTokenProgram.getNeonAddress(neonEVMUser.address)

            tx = await callSPLTokenProgram.connect(deployer).createInitializeATA(
                tokenMintInBytes,
                neonEVMUserPublicKeyInBytes, // Pass NeonEVM user public key so that neonEVMUser controls the ATA through CallSPLTokenProgram contract
                Buffer.from('0000000000000000000000000000000000000000000000000000000000000000', 'hex'), // Leave tokenOwner field empty so that CallSPLTokenProgram contract owns the ATA
            )
            await tx.wait(1) // Wait for 1 confirmation

            neonEVMUserATAInBytes = await callSPLTokenProgram.getAssociatedTokenAccount(
                tokenMintInBytes,
                neonEVMUserPublicKeyInBytes,
            )
            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(neonEVMUserATAInBytes))
            expect(info.mint.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))
            expect(info.owner.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.delegate).to.be.null
            expect(info.closeAuthority).to.be.null
            expect(info.amount).to.eq(ZERO_AMOUNT)
            expect(info.delegatedAmount).to.eq(ZERO_AMOUNT)
            expect(info.isInitialized).to.eq(true)
            expect(info.isFrozen).to.eq(false)
            expect(info.isNative).to.eq(false)
            expect(info.rentExemptReserve).to.be.null
            expect(info.tlvData.length).to.eq(0)
        })

        it('Create and initialize new ATA for third party Solana user', async function() {

            solanaUserPublicKey = (await web3.Keypair.generate()).publicKey

            tx = await callSPLTokenProgram.connect(deployer).createInitializeATA(
                tokenMintInBytes,
                solanaUserPublicKey.toBuffer(), // Pass Solana user public key so that Solana user controls the ATA through CallSPLTokenProgram contract
                solanaUserPublicKey.toBuffer(), // Pass Solana user public key as tokenOwner so that  Solana user owns the ATA
            )
            await tx.wait(1) // Wait for 1 confirmation

            solanaUserATAInBytes = await callSPLTokenProgram.getAssociatedTokenAccount(
                tokenMintInBytes,
                solanaUserPublicKey.toBuffer(),
            )
            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(solanaUserATAInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(solanaUserATAInBytes))
            expect(info.mint.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))
            expect(info.owner.toBase58()).to.eq(solanaUserPublicKey.toBase58())
            expect(info.delegate).to.be.null
            expect(info.closeAuthority).to.be.null
            expect(info.amount).to.eq(ZERO_AMOUNT)
            expect(info.delegatedAmount).to.eq(ZERO_AMOUNT)
            expect(info.isInitialized).to.eq(true)
            expect(info.isFrozen).to.eq(false)
            expect(info.isNative).to.eq(false)
            expect(info.rentExemptReserve).to.be.null
            expect(info.tlvData.length).to.eq(0)
        })
    })

    describe('\n\u{231B} \x1b[33m Testing on-chain formatting and execution of Solana\'s SPL Token program\'s \x1b[36mmintTo\x1b[33m instruction\x1b[0m', function() {

        it('Mint SPL token amount to deployer ATA', async function() {

            initialDeployerATABalance = BigInt((await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes))
            )).value.amount)

            tx = await callSPLTokenProgram.connect(deployer).mint(
                Buffer.from(seed), // Seed that was used to generate SPL token mint
                deployerATAInBytes, // Recipient ATA
                AMOUNT // Amount to mint
            )
            await tx.wait(1) // Wait for 1 confirmation

            info = await getMint(solanaConnection, new web3.PublicKey(ethers.encodeBase58(tokenMintInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))
            expect(info.mintAuthority.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.freezeAuthority.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.supply).to.eq(AMOUNT)
            expect(info.decimals).to.eq(decimals)
            expect(info.isInitialized).to.eq(true)
            expect(info.tlvData.length).to.eq(0)

            info = await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes))
            )

            expect(info.value.amount).to.eq((initialDeployerATABalance + AMOUNT).toString())
            expect(info.value.decimals).to.eq(decimals)
            expect(info.value.uiAmount).to.eq(parseInt(ethers.formatUnits((initialDeployerATABalance + AMOUNT), decimals)))
            expect(info.value.uiAmountString).to.eq(ethers.formatUnits((initialDeployerATABalance + AMOUNT), decimals).split('.')[0])
        })

        it('Third party user cannot mint (transaction reverts)', async function() {

            initialNeonEVMUserATABalance = BigInt((await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes))
            )).value.amount)

            // Mint tokens (transaction reverts)
            await expect(callSPLTokenProgram.connect(neonEVMUser).mint(
                Buffer.from(seed), // Seed that was used to generate SPL token mint
                neonEVMUserATAInBytes, // Recipient ATA
                AMOUNT // Amount to mint
            )).to.be.revertedWith(
                "External call fails TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA: Error processing Instruction 0: custom program error: 0x3"
            )

            newNeonEVMUserATABalance = BigInt((await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes))
            )).value.amount)

            expect(newNeonEVMUserATABalance).to.eq(initialNeonEVMUserATABalance)
        })
    })

    describe('\n\u{231B} \x1b[33m Testing on-chain formatting and execution of Solana\'s SPL Token program\'s \x1b[36mtransfer\x1b[33m instruction\x1b[0m', function() {

        it('Transfer SPL token amount from deployer ATA to NeonEVM user ATA', async function() {

            initialDeployerATABalance = BigInt((await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes))
            )).value.amount)
            initialNeonEVMUserATABalance = BigInt((await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes))
            )).value.amount)

            neonEVMUserATAInBytes = await callSPLTokenProgram.getAssociatedTokenAccount(
                tokenMintInBytes,
                neonEVMUserPublicKeyInBytes,
            )

            tx = await callSPLTokenProgram.connect(deployer).transfer(
                tokenMintInBytes,
                neonEVMUserATAInBytes, // Recipient is NeonEVM user ATA
                SMALL_AMOUNT // Amount to transfer
            )
            await tx.wait(1) // Wait for 1 confirmation

            info = await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes))
            )

            expect(info.value.amount).to.eq((initialDeployerATABalance - SMALL_AMOUNT).toString())
            expect(info.value.decimals).to.eq(decimals)
            expect(info.value.uiAmount).to.eq(parseInt(ethers.formatUnits((initialDeployerATABalance - SMALL_AMOUNT), decimals)))
            expect(info.value.uiAmountString).to.eq(ethers.formatUnits((initialDeployerATABalance - SMALL_AMOUNT), decimals).split('.')[0])

            info = await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes))
            )

            expect(info.value.amount).to.eq((initialNeonEVMUserATABalance + SMALL_AMOUNT).toString())
            expect(info.value.decimals).to.eq(decimals)
            expect(info.value.uiAmount).to.eq(parseInt(ethers.formatUnits((initialNeonEVMUserATABalance + SMALL_AMOUNT), decimals)))
            expect(info.value.uiAmountString).to.eq(ethers.formatUnits((initialNeonEVMUserATABalance + SMALL_AMOUNT), decimals).split('.')[0])
        })

        it('Transfer SPL token amount from NeonEVM user ATA to Solana user ATA', async function() {

            initialNeonEVMUserATABalance = BigInt((await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes))
            )).value.amount)
            initialSolanaUserATABalance = BigInt((await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(solanaUserATAInBytes))
            )).value.amount)

            tx = await callSPLTokenProgram.connect(neonEVMUser).transfer(
                tokenMintInBytes,
                solanaUserATAInBytes, // Recipient is NeonEVM user ATA
                SMALL_AMOUNT // Amount to transfer
            )
            await tx.wait(1) // Wait for 1 confirmation

            info = await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes))
            )

            expect(info.value.amount).to.eq((initialNeonEVMUserATABalance - SMALL_AMOUNT).toString())
            expect(info.value.decimals).to.eq(decimals)
            expect(info.value.uiAmount).to.eq(parseInt(ethers.formatUnits((initialNeonEVMUserATABalance - SMALL_AMOUNT), decimals)))
            expect(info.value.uiAmountString).to.eq(ethers.formatUnits((initialNeonEVMUserATABalance - SMALL_AMOUNT), decimals).split('.')[0])

            info = await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(solanaUserATAInBytes))
            )

            expect(info.value.amount).to.eq((initialSolanaUserATABalance + SMALL_AMOUNT).toString())
            expect(info.value.decimals).to.eq(decimals)
            expect(info.value.uiAmount).to.eq(parseInt(ethers.formatUnits((initialSolanaUserATABalance + SMALL_AMOUNT), decimals)))
            expect(info.value.uiAmountString).to.eq(ethers.formatUnits((initialSolanaUserATABalance + SMALL_AMOUNT), decimals).split('.')[0])
        })

        it('User with zero balance cannot transfer (transaction reverts)', async function() {

            initialNeonEVMUserATABalance = BigInt((await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes))
            )).value.amount)

            expect(initialNeonEVMUserATABalance).to.eq(ZERO_AMOUNT)

            await expect(callSPLTokenProgram.connect(neonEVMUser).transfer(
                tokenMintInBytes,
                neonEVMUserATAInBytes,
                AMOUNT
            )).to.be.revertedWith(
                "External call fails TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA: Error processing Instruction 0: custom program error: 0x1"
            )

            newNeonEVMUserATABalance = BigInt((await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes))
            )).value.amount)

            expect(newNeonEVMUserATABalance).to.eq(initialNeonEVMUserATABalance)
        })
    })

    describe('\n\u{231B} \x1b[33m Testing on-chain formatting and execution of Solana\'s SPL Token program\'s \x1b[36mapprove\x1b[33m instruction\x1b[0m', function() {

        it('User without approval cannot claim (transaction reverts)', async function() {

            await expect(callSPLTokenProgram.connect(neonEVMUser).claim(
                deployerATAInBytes, // Spend from deployer ATA
                neonEVMUserATAInBytes, // Recipient ATA
                SMALL_AMOUNT // Claimed amount
            )).to.be.revertedWith(
                "CallSPLTokenProgram.claim: msg.sender is not approved to spend from ata"
            )
        })

        it('Delegate deployer ATA to NeonEVM user', async function() {

            initialDeployerATABalance = BigInt((await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes))
            )).value.amount)

            tx = await callSPLTokenProgram.connect(deployer).approve(
                tokenMintInBytes,
                neonEVMUserPublicKeyInBytes, // delegate
                SMALL_AMOUNT // Delegated amount
            )
            await tx.wait(1) // Wait for 1 confirmation

            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(deployerATAInBytes))
            expect(info.mint.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))
            expect(info.owner.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.delegate.toBase58()).to.eq(ethers.encodeBase58(neonEVMUserPublicKeyInBytes))
            expect(info.closeAuthority).to.be.null
            expect(info.amount).to.eq(initialDeployerATABalance)
            expect(info.delegatedAmount).to.eq(SMALL_AMOUNT)
            expect(info.isInitialized).to.eq(true)
            expect(info.isFrozen).to.eq(false)
            expect(info.isNative).to.eq(false)
            expect(info.rentExemptReserve).to.be.null
            expect(info.tlvData.length).to.eq(0)
        })

        it('Claim tokens from delegated ATA', async function() {

            initialDeployerATABalance = BigInt((await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes))
            )).value.amount)
            initialNeonEVMUserATABalance = BigInt((await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes))
            )).value.amount)

            tx = await callSPLTokenProgram.connect(neonEVMUser).claim(
                deployerATAInBytes, // Spend from deployer ATA
                neonEVMUserATAInBytes, // Recipient ATA
                SMALL_AMOUNT // Claimed amount
            )
            await tx.wait(1) // Wait for 1 confirmation

            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(deployerATAInBytes))
            expect(info.mint.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))
            expect(info.owner.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.delegate.toBase58()).to.eq(ethers.encodeBase58(neonEVMUserPublicKeyInBytes))
            expect(info.closeAuthority).to.be.null
            expect(info.amount).to.eq(initialDeployerATABalance - SMALL_AMOUNT)
            expect(info.delegatedAmount).to.eq(SMALL_AMOUNT)
            expect(info.isInitialized).to.eq(true)
            expect(info.isFrozen).to.eq(false)
            expect(info.isNative).to.eq(false)
            expect(info.rentExemptReserve).to.be.null
            expect(info.tlvData.length).to.eq(0)

            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(neonEVMUserATAInBytes))
            expect(info.mint.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))
            expect(info.owner.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.delegate).to.be.null
            expect(info.closeAuthority).to.be.null
            expect(info.amount).to.eq(initialNeonEVMUserATABalance + SMALL_AMOUNT)
            expect(info.delegatedAmount).to.eq(ZERO_AMOUNT)
            expect(info.isInitialized).to.eq(true)
            expect(info.isFrozen).to.eq(false)
            expect(info.isNative).to.eq(false)
            expect(info.rentExemptReserve).to.be.null
            expect(info.tlvData.length).to.eq(0)
        })

        it('User without initialized ATA cannot delegate (transaction reverts)', async function() {
            await expect(callSPLTokenProgram.connect(otherNeonEVMUser).approve(
                tokenMintInBytes,
                neonEVMUserPublicKeyInBytes,
                AMOUNT
            )).to.be.revertedWith(
                "External call fails TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA: Error processing Instruction 0: invalid account data for instruction"
            )
        })
    })

    describe('\n\u{231B} \x1b[33m Testing on-chain formatting and execution of Solana\'s SPL Token program\'s \x1b[36mrevoke\x1b[33m instruction\x1b[0m', function() {

        it('Revoke deployer ATA delegation to NeonEVM user', async function() {

            initialDeployerATABalance = BigInt((await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes))
            )).value.amount)

            tx = await callSPLTokenProgram.connect(deployer).revokeApproval(
                tokenMintInBytes,
            )
            await tx.wait(1) // Wait for 1 confirmation

            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(deployerATAInBytes))
            expect(info.mint.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))
            expect(info.owner.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.delegate).to.be.null
            expect(info.closeAuthority).to.be.null
            expect(info.amount).to.eq(initialDeployerATABalance)
            expect(info.delegatedAmount).to.eq(ZERO_AMOUNT)
            expect(info.isInitialized).to.eq(true)
            expect(info.isFrozen).to.eq(false)
            expect(info.isNative).to.eq(false)
            expect(info.rentExemptReserve).to.be.null
            expect(info.tlvData.length).to.eq(0)
        })

        it('User without initialized ATA cannot revoke approval (transaction reverts)', async function() {
            await expect(callSPLTokenProgram.connect(otherNeonEVMUser).revokeApproval(
                tokenMintInBytes
            )).to.be.revertedWith(
                "External call fails TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA: Error processing Instruction 0: invalid account data for instruction"
            )
        })
    })

    describe('\n\u{231B} \x1b[33m Testing on-chain formatting and execution of Solana\'s SPL Token program\'s \x1b[36msetAuthority\x1b[33m instruction\x1b[0m', function() {

        it("User can only update SPL token mint's MINT or FREEZE authority (otherwise transaction reverts)", async function() {
            newOwnerInBytes = (await web3.Keypair.generate()).publicKey.toBuffer()

            await expect(callSPLTokenProgram.connect(otherNeonEVMUser).updateTokenMintAuthority(
                Buffer.from(seed), // Seed that was used to generate SPL token mint
                2, // OWNER authority
                newOwnerInBytes
            )).to.be.revertedWith(
                "CallSPLTokenProgram.updateTokenMintAuthority: authority type must be MINT or FREEZE"
            )
        })

        it("Update SPL token mint's MINT authority", async function() {

            newMintAuthorityInBytes = (await web3.Keypair.generate()).publicKey.toBuffer()

            tx = await callSPLTokenProgram.connect(deployer).updateTokenMintAuthority(
                Buffer.from(seed), // Seed that was used to generate SPL token mint
                0, // MINT authority
                newMintAuthorityInBytes
            )
            await tx.wait(1) // Wait for 1 confirmation

            info = await getMint(solanaConnection, new web3.PublicKey(ethers.encodeBase58(tokenMintInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))
            expect(info.mintAuthority.toBase58()).to.eq(ethers.encodeBase58(newMintAuthorityInBytes))
            expect(info.freezeAuthority.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.supply).to.eq(AMOUNT)
            expect(info.decimals).to.eq(decimals)
            expect(info.isInitialized).to.eq(true)
            expect(info.tlvData.length).to.eq(0)
        })

        it("Previous MINT authority cannot update SPL token mint's MINT authority anymore (transaction reverts)", async function() {
            await expect(callSPLTokenProgram.connect(deployer).updateTokenMintAuthority(
                Buffer.from(seed), // Seed that was used to generate SPL token mint
                0, // MINT authority
                newMintAuthorityInBytes
            )).to.be.revertedWith(
                "CallSPLTokenProgram.updateTokenMintAuthority: only token mint's mint authority can update mint authority"
            )
        })

        it("Third party user cannot update SPL token mint's MINT authority (transaction reverts)", async function() {
            await expect(callSPLTokenProgram.connect(otherNeonEVMUser).updateTokenMintAuthority(
                Buffer.from(seed), // Seed that was used to generate SPL token mint
                0, // MINT authority
                newMintAuthorityInBytes
            )).to.be.revertedWith(
        "LibSPLTokenData.getSPLTokenMintAuthority: failed to query SPL Token mint data"
            )
        })

        it("Update SPL token mint's FREEZE authority", async function() {

            newFreezeAuthorityInBytes = (await web3.Keypair.generate()).publicKey.toBuffer()

            tx = await callSPLTokenProgram.connect(deployer).updateTokenMintAuthority(
                Buffer.from(seed), // Seed that was used to generate SPL token mint
                1, // FREEZE authority
                newFreezeAuthorityInBytes
            )
            await tx.wait(1) // Wait for 1 confirmation

            info = await getMint(solanaConnection, new web3.PublicKey(ethers.encodeBase58(tokenMintInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))
            expect(info.mintAuthority.toBase58()).to.eq(ethers.encodeBase58(newMintAuthorityInBytes))
            expect(info.freezeAuthority.toBase58()).to.eq(ethers.encodeBase58(newFreezeAuthorityInBytes))
            expect(info.supply).to.eq(AMOUNT)
            expect(info.decimals).to.eq(decimals)
            expect(info.isInitialized).to.eq(true)
            expect(info.tlvData.length).to.eq(0)
        })

        it("Previous FREEZE authority cannot update SPL token mint's FREEZE authority anymore (transaction reverts)", async function() {
            await expect(callSPLTokenProgram.connect(deployer).updateTokenMintAuthority(
                Buffer.from(seed), // Seed that was used to generate SPL token mint
                1, // FREEZE authority
                newFreezeAuthorityInBytes
            )).to.be.revertedWith(
                "CallSPLTokenProgram.updateTokenMintAuthority: only token mint's freeze authority can update freeze authority"
            )
        })

        it("Third party user cannot update SPL token mint's FREEZE authority (transaction reverts)", async function() {
            await expect(callSPLTokenProgram.connect(otherNeonEVMUser).updateTokenMintAuthority(
                Buffer.from(seed), // Seed that was used to generate SPL token mint
                1, // FREEZE authority
                newFreezeAuthorityInBytes
            )).to.be.revertedWith(
                "LibSPLTokenData.getSPLTokenFreezeAuthority: failed to query SPL Token mint data"
            )
        })

        it("SPL token account's OWNER can update undefined SPL token account's CLOSE authority", async function() {

            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes)))
            expect(info.closeAuthority).to.be.null

            tx = await callSPLTokenProgram.connect(neonEVMUser).updateTokenAccountAuthority(
                tokenMintInBytes, // Token mint associated with the token account of which we want to update authority
                3, // CLOSE authority
                contractPublicKeyInBytes,
            )
            await tx.wait(1) // Wait for 1 confirmation

            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(neonEVMUserATAInBytes))
            expect(info.mint.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))
            expect(info.owner.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.delegate).to.be.null
            expect(info.closeAuthority.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.isInitialized).to.eq(true)
            expect(info.isFrozen).to.eq(false)
            expect(info.isNative).to.eq(false)
            expect(info.rentExemptReserve).to.be.null
            expect(info.tlvData.length).to.eq(0)
        })

        it("SPL token account's CLOSE authority can update SPL token account's CLOSE authority", async function() {

            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes)))
            expect(info.closeAuthority.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))

            newCloseAuthorityInBytes = (await web3.Keypair.generate()).publicKey.toBuffer()

            tx = await callSPLTokenProgram.connect(neonEVMUser).updateTokenAccountAuthority(
                tokenMintInBytes, // Token mint associated with the token account of which we want to update authority
                3, // CLOSE authority
                newCloseAuthorityInBytes,
            )
            await tx.wait(1) // Wait for 1 confirmation

            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(neonEVMUserATAInBytes))
            expect(info.mint.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))
            expect(info.owner.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.delegate).to.be.null
            expect(info.closeAuthority.toBase58()).to.eq(ethers.encodeBase58(newCloseAuthorityInBytes))
            expect(info.isInitialized).to.eq(true)
            expect(info.isFrozen).to.eq(false)
            expect(info.isNative).to.eq(false)
            expect(info.rentExemptReserve).to.be.null
            expect(info.tlvData.length).to.eq(0)
        })

        it("SPL token account's OWNER cannot update already defined SPL token account's CLOSE authority (transaction reverts)", async function() {

            await expect(callSPLTokenProgram.connect(neonEVMUser).updateTokenAccountAuthority(
                tokenMintInBytes,
                3,
                contractPublicKeyInBytes,
            )).to.be.revertedWith(
                "External call fails TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA: Error processing Instruction 0: custom program error: 0x4"
            )
        })

        it("User without initialized ATA cannot update SPL token account's CLOSE authority (transaction reverts)", async function() {
            await expect(callSPLTokenProgram.connect(otherNeonEVMUser).updateTokenAccountAuthority(
                tokenMintInBytes, // Token mint associated with the token account of which we want to update authority
                3, // CLOSE authority
                newCloseAuthorityInBytes,
            )).to.be.revertedWith(
                "LibSPLTokenData.getSPLTokenAccountOwner: failed to query SPL Token account data"
            )
        })

        it("SPL token account's OWNER can update SPL token account's OWNER authority", async function() {

            newOwnerInBytes = (await web3.Keypair.generate()).publicKey.toBuffer()

            tx = await callSPLTokenProgram.connect(neonEVMUser).updateTokenAccountAuthority(
                tokenMintInBytes, // Token mint associated with the token account of which we want to update authority
                2, // OWNER authority
                newOwnerInBytes,
            )
            await tx.wait(1) // Wait for 1 confirmation

            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(neonEVMUserATAInBytes))
            expect(info.mint.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))
            expect(info.owner.toBase58()).to.eq(ethers.encodeBase58(newOwnerInBytes))
            expect(info.delegate).to.be.null
            expect(info.closeAuthority.toBase58()).to.eq(ethers.encodeBase58(newCloseAuthorityInBytes))
            expect(info.isInitialized).to.eq(true)
            expect(info.isFrozen).to.eq(false)
            expect(info.isNative).to.eq(false)
            expect(info.rentExemptReserve).to.be.null
            expect(info.tlvData.length).to.eq(0)
        })

        it("Previous token account's OWNER cannot update SPL token account OWNER anymore (transaction reverts)", async function() {
            newOwnerInBytes = (await web3.Keypair.generate()).publicKey.toBuffer()

            await expect(callSPLTokenProgram.connect(neonEVMUser).updateTokenAccountAuthority(
                tokenMintInBytes, // Token mint associated with the token account of which we want to update authority
                2, // OWNER authority
                newOwnerInBytes,
            )).to.be.revertedWith(
                "CallSPLTokenProgram.updateTokenAccountAuthority: only token account owner can update owner authority"
            )
        })

        it("Previous token account's OWNER cannot update SPL token account CLOSE authority (transaction reverts)", async function() {
            newCloseAuthorityInBytes = (await web3.Keypair.generate()).publicKey.toBuffer()

            await expect(callSPLTokenProgram.connect(neonEVMUser).updateTokenAccountAuthority(
                tokenMintInBytes, // Token mint associated with the token account of which we want to update authority
                3, // CLOSE authority
                newCloseAuthorityInBytes,
            )).to.be.revertedWith(
                "CallSPLTokenProgram.updateTokenAccountAuthority: only token account owner or close authority can update close authority"
            )
        })
    })

    describe('\n\u{231B} \x1b[33m Testing on-chain formatting and execution of Solana\'s SPL Token program\'s \x1b[36mburn\x1b[33m instruction\x1b[0m', function() {

        it("Burn tokens", async function() {

            // Check initial token balance of deployer ATA
            info = await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes))
            )
            initialDeployerATABalance = BigInt(info.value.amount)

            // Burn tokens
            tx = await callSPLTokenProgram.connect(deployer).burn(
                tokenMintInBytes, // Token mint associated with the token account from which we want to burn tokens
                SMALL_AMOUNT, // Amount we want to burn
            )
            await tx.wait(1) // Wait for 1 confirmation

            // Check new token balance of deployer ATA
            info = await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes))
            )
            newDeployerATABalance = BigInt(info.value.amount)

            expect(initialDeployerATABalance - newDeployerATABalance).to.eq(SMALL_AMOUNT)
        })

        it("User cannot burn more than token balance (transaction reverts)", async function() {

            // Check initial token balance of deployer ATA
            info = await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes))
            )
            initialDeployerATABalance = BigInt(info.value.amount)

            // Burn tokens
            await expect(callSPLTokenProgram.connect(deployer).burn(
                tokenMintInBytes,
                initialDeployerATABalance + SMALL_AMOUNT,
            )).to.be.revertedWith("External call fails TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA: Error processing Instruction 0: custom program error: 0x1")
        })
    })

    describe('\n\u{231B} \x1b[33m Testing on-chain formatting and execution of Solana\'s SPL Token program\'s \x1b[36msyncNative\x1b[33m instruction\x1b[0m', function() {

        before('Create and initialize new WSOL ATA for deployer', async function() {

            tx = await callSPLTokenProgram.connect(deployer).createInitializeATA(
                WSOL_MINT_PUBKEY,
                Buffer.from('0000000000000000000000000000000000000000000000000000000000000000', 'hex'), // Leave owner field empty so that msg.sender controls the ATA through CallSPLTokenProgram contract
                Buffer.from('0000000000000000000000000000000000000000000000000000000000000000', 'hex'), // Leave tokenOwner field empty so that CallSPLTokenProgram contract owns the ATA
            )
            await tx.wait(1) // Wait for 1 confirmation

            deployerPublicKeyInBytes = await callSPLTokenProgram.getNeonAddress(deployer.address)
            deployerWSOLATAInBytes = await callSPLTokenProgram.getAssociatedTokenAccount(
                WSOL_MINT_PUBKEY,
                deployerPublicKeyInBytes,
            )
            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(deployerWSOLATAInBytes)))

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(deployerWSOLATAInBytes))
            expect(info.mint.toBase58()).to.eq(ethers.encodeBase58(WSOL_MINT_PUBKEY))
            expect(info.owner.toBase58()).to.eq(ethers.encodeBase58(contractPublicKeyInBytes))
            expect(info.delegate).to.be.null
            expect(info.closeAuthority).to.be.null
            expect(info.amount).to.eq(ZERO_AMOUNT)
            expect(info.delegatedAmount).to.eq(ZERO_AMOUNT)
            expect(info.isInitialized).to.eq(true)
            expect(info.isFrozen).to.eq(false)
            expect(info.isNative).to.eq(true) // WSOL ATAs are "native" topken accounts
            expect(info.rentExemptReserve).to.eq(await callSPLTokenProgram.ATA_RENT_EXEMPT_BALANCE()) // WSOL ATAs have rentExemptReserve
            expect(info.tlvData.length).to.eq(0)
        })


        it("Sync deployer's WSOL token balance", async function() {

            // Airdrop SOL to deployer's WSOL ATA
            await airdropSOL(ethers.encodeBase58(deployerWSOLATAInBytes), parseInt(SMALL_AMOUNT.toString()))
            initialDeployerATASOLBalance = await solanaConnection.getBalance(new web3.PublicKey(ethers.encodeBase58(deployerWSOLATAInBytes)))
            expect(initialDeployerATASOLBalance).to.eq((await callSPLTokenProgram.ATA_RENT_EXEMPT_BALANCE()) + SMALL_AMOUNT)

            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(deployerWSOLATAInBytes)))
            initialDeployerATAwSOLBalance = info.amount
            expect(initialDeployerATAwSOLBalance).to.eq(ZERO_AMOUNT)

            // Sync native
            tx = await callSPLTokenProgram.syncWrappedSOLAccount(deployerWSOLATAInBytes)
            await tx.wait(1) // Wait for 1 confirmation

            // Check ATA WSOL and SOL balances
            newDeployerATASOLBalance = await solanaConnection.getBalance(new web3.PublicKey(ethers.encodeBase58(deployerWSOLATAInBytes)))
            expect(newDeployerATASOLBalance).to.eq(initialDeployerATASOLBalance) // SOL balance has not changed
            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(deployerWSOLATAInBytes)))
            newDeployerATAwSOLBalance = info.amount
            expect(newDeployerATAwSOLBalance - initialDeployerATAwSOLBalance).to.eq(SMALL_AMOUNT) // wSOL balance has been synced
        })

        it("User cannot sync a non-native token account (transaction reverts)", async function() {

            // Airdrop SOL to deployer's non-native token account
            await airdropSOL(ethers.encodeBase58(deployerATAInBytes), parseInt(SMALL_AMOUNT.toString()))
            initialDeployerATASOLBalance = await solanaConnection.getBalance(new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes)))
            expect(initialDeployerATASOLBalance).to.eq((await callSPLTokenProgram.ATA_RENT_EXEMPT_BALANCE()) + SMALL_AMOUNT)

            // Sync native
            await expect(callSPLTokenProgram.syncWrappedSOLAccount(deployerATAInBytes)).to.be.revertedWith(
                "External call fails TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA: Error processing Instruction 0: custom program error: 0x13"
            )
        })
    })

    describe('\n\u{231B} \x1b[33m Testing on-chain formatting and execution of Solana\'s SPL Token program\'s \x1b[36mcloseAccount\x1b[33m instruction\x1b[0m', function() {

        it("User cannot close SPL token account which has non-zero token balance (transaction reverts)", async function() {

            // Check initial token balance of deployer ATA
            info = await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes))
            )
            initialDeployerATABalance = BigInt(info.value.amount)

            expect(BigInt(initialDeployerATABalance)).to.be.greaterThan(ZERO_AMOUNT)

            // Close deployer ATA
            await expect(callSPLTokenProgram.connect(deployer).closeTokenAccount(
                tokenMintInBytes,
                deployerPublicKeyInBytes
            )).to.be.revertedWith(
                "External call fails TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA: Error processing Instruction 0: custom program error: 0xb"
            )
        })

        it("Close SPL token account", async function() {

            // Check initial token balance of deployer ATA
            info = await solanaConnection.getTokenAccountBalance(
                new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes))
            )
            initialDeployerATABalance = BigInt(info.value.amount)

            // SPL token account must have zero token balance before being closed
            if(initialDeployerATABalance > 0) {
                tx = await callSPLTokenProgram.connect(deployer).transfer(
                    tokenMintInBytes,
                    neonEVMUserATAInBytes, // Recipient is NeonEVM user ATA
                    initialDeployerATABalance // Amount to transfer
                )
                await tx.wait(1) // Wait for 1 confirmation

                info = await solanaConnection.getTokenAccountBalance(
                    new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes))
                )
                expect(info.value.amount).to.eq(ZERO_AMOUNT.toString())
            }

            // Deployer ATA's SOL balance will be transferred to deployer account
            initialDeployerBalance = await solanaConnection.getBalance(new web3.PublicKey(ethers.encodeBase58(deployerPublicKeyInBytes)))
            initialDeployerATASOLBalance = await solanaConnection.getBalance(new web3.PublicKey(ethers.encodeBase58(deployerATAInBytes)))

            // Close deployer ATA
            tx = await callSPLTokenProgram.connect(deployer).closeTokenAccount(
                tokenMintInBytes, // Token mint associated with the token account which we want to close
                deployerPublicKeyInBytes // account which will receive the closed ATA's SOL balance
            )
            await tx.wait(1) // Wait for 1 confirmation

            // Check that ATA does not exist anymore
            await expect(callSPLTokenProgram.getSPLTokenAccountData(deployerATAInBytes)).to.be.revertedWith(
                "LibSPLTokenData: failed to query SPL Token account data"
            )

            // Check that ATA balance was transferred to deployer account
            newDeployerBalance = await solanaConnection.getBalance(new web3.PublicKey(ethers.encodeBase58(deployerPublicKeyInBytes)))
            expect(newDeployerBalance - initialDeployerBalance).to.eq(initialDeployerATASOLBalance)
        })

        it("User cannot close SPL token account which has not been initialized (transaction reverts)", async function() {

            otherNeonEVMUserPublicKeyInBytes = await callSPLTokenProgram.getNeonAddress(otherNeonEVMUser.address)

            // Close user ATA
            await expect(callSPLTokenProgram.connect(otherNeonEVMUser).closeTokenAccount(
                tokenMintInBytes,
                otherNeonEVMUserPublicKeyInBytes
            )).to.be.revertedWith(
                "External call fails TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA: Error processing Instruction 0: invalid account data for instruction"
            )
        })
    })

    describe('\n\u{231B} \x1b[33m Testing Solana\'s SPL Token program \x1b[36mdata getters\x1b[33m\x1b[0m', async function() {

        it('Call SPL token mint data getters', async function() {

            info = await getMint(solanaConnection, new web3.PublicKey(ethers.encodeBase58(tokenMintInBytes)))

            const tokenMintIsInitialized= await callSPLTokenProgram.getSPLTokenMintIsInitialized(tokenMintInBytes)
            const tokenSupply = await callSPLTokenProgram.getSPLTokenSupply(tokenMintInBytes)
            const tokenDecimals = await callSPLTokenProgram.getSPLTokenDecimals(tokenMintInBytes)
            const tokenMintAuthority = await callSPLTokenProgram.getSPLTokenMintAuthority(tokenMintInBytes)
            const tokenFreezeAuthority = await callSPLTokenProgram.getSPLTokenFreezeAuthority(tokenMintInBytes)
            const tokenMintData = await callSPLTokenProgram.getSPLTokenMintData(tokenMintInBytes)

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(tokenMintInBytes))

            if(info.isInitialized) {
                expect(tokenMintIsInitialized).to.eq('0x' + ONE_BYTE.toString('hex'))
                expect(tokenMintData[4]).to.eq('0x' + ONE_BYTE.toString('hex'))
            } else {
                expect(tokenMintIsInitialized).to.eq('0x' + ZERO_BYTE.toString('hex'))
                expect(tokenMintData[4]).to.eq('0x' + ZERO_BYTE.toString('hex'))
            }

            expect(info.supply).to.eq(tokenSupply)
            expect(info.supply).to.eq(tokenMintData[2])

            expect(info.decimals).to.eq(tokenDecimals)
            expect(info.decimals).to.eq(tokenMintData[3])

            expect(info.mintAuthority.toBase58()).to.eq(ethers.encodeBase58(tokenMintAuthority))
            expect(info.mintAuthority.toBase58()).to.eq(ethers.encodeBase58(tokenMintData[1]))

            expect(info.freezeAuthority.toBase58()).to.eq(ethers.encodeBase58(tokenFreezeAuthority))
            expect(info.freezeAuthority.toBase58()).to.eq(ethers.encodeBase58(tokenMintData[6]))
        })


        it('Call SPL token account data getters', async function() {

            info = await getAccount(solanaConnection, new web3.PublicKey(ethers.encodeBase58(neonEVMUserATAInBytes)))

            const ataIsInitialized = await callSPLTokenProgram.getSPLTokenAccountIsInitialized(neonEVMUserATAInBytes)
            const ataIsNative = await callSPLTokenProgram.getSPLTokenAccountIsNative(neonEVMUserATAInBytes)
            const ataBalance = await callSPLTokenProgram.getSPLTokenAccountBalance(neonEVMUserATAInBytes)
            const ataOwner = await callSPLTokenProgram.getSPLTokenAccountOwner(neonEVMUserATAInBytes)
            const ataMint = await callSPLTokenProgram.getSPLTokenAccountMint(neonEVMUserATAInBytes)
            const ataDelegate = await callSPLTokenProgram.getSPLTokenAccountDelegate(neonEVMUserATAInBytes)
            const ataDelegatedAmount = await callSPLTokenProgram.getSPLTokenAccountDelegatedAmount(neonEVMUserATAInBytes)
            const ataCloseAuthority = await callSPLTokenProgram.getSPLTokenAccountCloseAuthority(neonEVMUserATAInBytes)
            const ataData = await callSPLTokenProgram.getSPLTokenAccountData(neonEVMUserATAInBytes)

            expect(info.address.toBase58()).to.eq(ethers.encodeBase58(neonEVMUserATAInBytes))

            if(info.isInitialized) {
                expect(ataIsInitialized).to.eq('0x' + ONE_BYTE.toString('hex'))
                expect(ataData[5]).to.eq('0x' + ONE_BYTE.toString('hex'))
            } else {
                expect(ataIsInitialized).to.eq('0x' + ZERO_BYTE.toString('hex'))
                expect(ataData[5]).to.eq('0x' + ZERO_BYTE.toString('hex'))
            }

            if(info.isNative) {
                expect(ataIsNative).to.eq('0x' + ONE_BYTES8.toString('hex'))
                expect(ataData[7]).to.eq('0x' + ONE_BYTES8.toString('hex'))
            } else {
                expect(ataIsNative).to.eq('0x' + ZERO_BYTES8.toString('hex'))
                expect(ataData[7]).to.eq('0x' + ZERO_BYTES8.toString('hex'))
            }

            expect(info.amount).to.eq(ataBalance)
            expect(info.amount).to.eq(ataData[2])

            expect(info.owner.toBase58()).to.eq(ethers.encodeBase58(ataOwner))
            expect(info.owner.toBase58()).to.eq(ethers.encodeBase58(ataData[1]))

            expect(info.mint.toBase58()).to.eq(ethers.encodeBase58(ataMint))
            expect(info.mint.toBase58()).to.eq(ethers.encodeBase58(ataData[0]))

            if(info.delegate) {
                expect(info.delegate.toBase58()).to.eq(ethers.encodeBase58(ataDelegate))
                expect(info.delegate.toBase58()).to.eq(ethers.encodeBase58(ataData[4]))
            }

            expect(info.delegatedAmount).to.eq(ataDelegatedAmount)
            expect(info.delegatedAmount).to.eq(ataData[8])

            if(info.closeAuthority) {
                expect(info.closeAuthority.toBase58()).to.eq(ethers.encodeBase58(ataCloseAuthority))
                expect(info.closeAuthority.toBase58()).to.eq(ethers.encodeBase58(ataData[10]))
            } else {
                expect(ataCloseAuthority).to.eq('0x' + ZERO_BYTES32.toString('hex'))
                expect(ataData[10]).to.eq('0x' + ZERO_BYTES32.toString('hex'))
            }
        })
    })
})
