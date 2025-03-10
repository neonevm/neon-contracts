const {ethers, network} = require("hardhat")
const config = require("./config")

async function asyncTimeout(timeout) {
    return new Promise((resolve) => {
        setTimeout(() => resolve(), timeout)
    })
}

async function airdropNEON(address, amount) {
    await fetch(process.env.NEON_FAUCET, {
        method: 'POST',
        body: JSON.stringify({"amount": amount, "wallet": address}),
        headers: { 'Content-Type': 'application/json' }
    })
    console.log("\nAirdropping " + ethers.formatUnits(amount.toString(), 0) + " NEON to " + address)
    await asyncTimeout(3000)
}

async function airdropSOL(pubKey, amount) {
    const params = [pubKey, amount]
    const res = await fetch(process.env.SOLANA_NODE, {
        method: 'POST',
        body: JSON.stringify({"jsonrpc":"2.0", "id":1, "method": "requestAirdrop", "params": params}),
        headers: { 'Content-Type': 'application/json' }
    })
    // console.log("\nAirdropping " + ethers.formatUnits(amount.toString(), 9) + " SOL to " + pubKey)
    await asyncTimeout(3000)
}

async function deployContract(contractName, contractAddress = null) {
    if (!process.env.PRIVATE_KEY_OWNER) {
        throw new Error("\nMissing private key: PRIVATE_KEY_OWNER")
    }
    if (!process.env.USER1_KEY) {
        throw new Error("\nMissing private key: USER1_KEY")
    }
    const minBalance = ethers.parseUnits("10000", 18) // 10000 NEON
    const deployer = (await ethers.getSigners())[0]
    let deployerBalance = BigInt(await ethers.provider.getBalance(deployer.address))
    if(
        deployerBalance < minBalance &&
        parseInt(ethers.formatUnits((minBalance - deployerBalance).toString(), 18)) > 0
    ) {
        await airdropNEON(deployer.address, parseInt(ethers.formatUnits((minBalance - deployerBalance).toString(), 18)))
    }
    const user = (await ethers.getSigners())[1]
    let userBalance = BigInt(await ethers.provider.getBalance(user.address))
    if(
        userBalance < minBalance &&
        parseInt(ethers.formatUnits((minBalance - userBalance).toString(), 18)) > 0
    ) {
        await airdropNEON(user.address, parseInt(ethers.formatUnits((minBalance - userBalance).toString(), 18)))
    }

    const contractFactory = await ethers.getContractFactory(contractName)
    let contract
    if (!config[contractName][network.name] && !contractAddress) {
        console.log("\nDeployer address: " + deployer.address)
        deployerBalance = BigInt(await ethers.provider.getBalance(deployer.address))
        console.log("\nDeployer balance: " + ethers.formatUnits(deployerBalance.toString(), 18) + " NEON")

        console.log("\nDeploying " + contractName + " contract to " + network.name + "...")
        contract = await contractFactory.deploy()
        await contract.waitForDeployment()
        console.log("\n" + contractName + " contract deployed to: " + contract.target)
    } else {
        const deployedContractAddress = contractAddress ? contractAddress : config[contractName][network.name]
        console.log("\n" + contractName + " contract already deployed to: " + deployedContractAddress)
        contract = contractFactory.attach(deployedContractAddress)
    }

    return { deployer, user, contract }
}

async function getSolanaTransactions(neonTxHash) {
    return await fetch(process.env.NEON_EVM_NODE, {
        method: 'POST',
        body: JSON.stringify({
            "jsonrpc":"2.0",
            "method":"neon_getSolanaTransactionByNeonTransaction",
            "params":[neonTxHash],
            "id":1
        }),
        headers: { 'Content-Type': 'application/json' }
    })
}

async function executeSolanaInstruction(instruction, lamports, contractInstance, salt, msgSender) {
    if (salt === undefined) {
        salt = '0x0000000000000000000000000000000000000000000000000000000000000000';
    }

    const tx = await contractInstance.connect(msgSender).execute(
        lamports,
        salt,
        prepareInstruction(instruction)
    );

    const receipt = await tx.wait(3);
    return [tx, receipt];
}

function prepareInstructionAccounts(instruction, overwriteAccounts) {
    let encodeKeys = '';
    for (let i = 0, len = instruction.keys.length; i < len; ++i) {
        if (typeof(overwriteAccounts) != "undefined" && Object.hasOwn(overwriteAccounts, i)) {
            // console.log(publicKeyToBytes32(overwriteAccounts[i].key), 'publicKey');
            encodeKeys+= ethers.solidityPacked(["bytes32"], [publicKeyToBytes32(overwriteAccounts[i].key)]).substring(2);
            encodeKeys+= ethers.solidityPacked(["bool"], [overwriteAccounts[i].isSigner]).substring(2);
            encodeKeys+= ethers.solidityPacked(["bool"], [overwriteAccounts[i].isWritable]).substring(2);
        } else {
            // console.log(publicKeyToBytes32(instruction.keys[i].pubkey.toString()), 'publicKey');
            encodeKeys+= ethers.solidityPacked(["bytes32"], [publicKeyToBytes32(instruction.keys[i].pubkey.toString())]).substring(2);
            encodeKeys+= ethers.solidityPacked(["bool"], [instruction.keys[i].isSigner]).substring(2);
            encodeKeys+= ethers.solidityPacked(["bool"], [instruction.keys[i].isWritable]).substring(2);
        }
    }

    return '0x' + ethers.zeroPadBytes(ethers.toBeHex(instruction.keys.length), 8).substring(2) + encodeKeys;
}

function prepareInstructionData(instruction) {
    const packedInstructionData = ethers.solidityPacked(
        ["bytes"],
        [instruction.data]
    ).substring(2);
    // console.log(packedInstructionData, 'packedInstructionData');

    return '0x' + ethers.zeroPadBytes(ethers.toBeHex(instruction.data.length), 8).substring(2) + packedInstructionData;
}

function prepareInstruction(instruction) {
    return publicKeyToBytes32(instruction.programId.toBase58()) + prepareInstructionAccounts(instruction).substring(2) + prepareInstructionData(instruction).substring(2);
}

function publicKeyToBytes32(pubkey) {
    return ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(pubkey)), 32);
}

module.exports = {
    airdropSOL,
    asyncTimeout,
    deployContract,
    getSolanaTransactions,
    executeSolanaInstruction
}