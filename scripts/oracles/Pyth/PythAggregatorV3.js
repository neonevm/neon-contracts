// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
import hre from "hardhat"
import { getSecrets } from "../../../neon-secrets.js";

async function main() {
    const { wallets } = await getSecrets()
    const ethers = (await hre.network.connect()).ethers
    const PYTH_PRICE_FEED_ID = ""; // bytes32
    const PYTH_PRICE_FEED_ACCOUNT = ""; // bytes32
    const PythAggregatorV3Factory = await ethers.getContractFactory("PythAggregatorV3", wallets.owner);
    const PythAggregatorV3Address = "";
    let PythAggregatorV3;

    if (ethers.isAddress(PythAggregatorV3Address)) {
        PythAggregatorV3 = PythAggregatorV3Factory.attach(
            PythAggregatorV3Address
        );
    } else {
        PythAggregatorV3 = await upgrades.deployProxy(PythAggregatorV3Factory, [
            PYTH_PRICE_FEED_ID,
            PYTH_PRICE_FEED_ACCOUNT
        ], {kind: 'uups'});
        await PythAggregatorV3.waitForDeployment();

        console.log(
            `PythAggregatorV3 deployed to ${PythAggregatorV3.target}`
        );
    }

    console.log('\n Listing data for Pyth price feed:');
    console.log(await PythAggregatorV3.decimals(), 'decimals');
    console.log(await PythAggregatorV3.description(), 'description');
    console.log(await PythAggregatorV3.version(), 'version');
    console.log(await PythAggregatorV3.latestAnswer(), 'latestAnswer');
    console.log(await PythAggregatorV3.latestTimestamp(), 'latestTimestamp');
    console.log(await PythAggregatorV3.latestRound(), 'latestRound');
    console.log(await PythAggregatorV3.getAnswer(0), 'getAnswer');
    console.log(await PythAggregatorV3.getTimestamp(0), 'getTimestamp');
    console.log(await PythAggregatorV3.getRoundData(10), 'getRoundData');
    console.log(await PythAggregatorV3.latestRoundData(), 'latestRoundData');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});