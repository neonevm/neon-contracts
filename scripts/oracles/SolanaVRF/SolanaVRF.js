// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
import hre from "hardhat"
import web3 from '@solana/web3.js'
import { getSecrets } from "../../../neon-secrets.js";

async function main() {
    const { wallets } = await getSecrets()
    const ethers = (await hre.network.connect()).ethers
    const SolanaVRFFactory = await ethers.getContractFactory("SolanaVRF", wallets.owner);
    let SolanaVRFAddress = "";
    let SolanaVRF;

    if (ethers.isAddress(SolanaVRFAddress)) {
        SolanaVRF = SolanaVRFFactory.attach(SolanaVRFAddress);

        console.log(
            `SolanaVRF attached at ${SolanaVRFAddress}`
        );
    } else {
        SolanaVRF = await ethers.deployContract("SolanaVRF", wallets.owner);
        await SolanaVRF.waitForDeployment();
        SolanaVRFAddress = SolanaVRF.target;

        console.log(
            `SolanaVRF deployed to ${SolanaVRFAddress}`
        );
    }

    async function requestRandomness() {
        const randomKeypair = web3.Keypair.generate();
        const seed = ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(randomKeypair.publicKey.toBase58())), 32);
        console.log(seed, 'seed');
        console.log(await SolanaVRF.randomnessAccountAddress(seed), 'randomnessAccountAddress');

        let tx = await SolanaVRF.requestRandomness(
            seed,
            7103920 // needed SOL amount in lamports in order to create VRF account on Solana
        );
        await tx.wait(1);
        console.log(tx, 'tx');
    }

    async function getRandomness(seed) {
        console.log(await SolanaVRF.randomnessAccountAddress(seed), 'randomnessAccountAddress');
        console.log(
            await SolanaVRF.getRandomness(seed), 
            'getRandomness'
        );
    }

    requestRandomness();

    //getRandomness(''); // place your seed here
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});