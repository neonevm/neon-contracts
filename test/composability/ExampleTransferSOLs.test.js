const { ethers } = require("hardhat");
const { expect } = require("chai");
const web3 = require("@solana/web3.js");
const config = require("../config.js");
require("dotenv").config();

let owner;
let ExampleTransferSOLs;
let wSOL;
const wSOLAddress = "0xc7Fc9b46e479c5Cb42f6C458D1881e55E6B7986c"; // devnet wSOL
const RECEIPTS_COUNT = 10;
let neonEvmUser;
let solanaUser;
const connection = new web3.Connection(config.svm_node.neondevnet, "processed");

describe('Test init', async function () {
    before(async function() {
        [owner] = await ethers.getSigners();
        if (await ethers.provider.getBalance(owner.address) == 0) {
            await config.utils.airdropNEON(owner.address);
        }

        ExampleTransferSOLs = await ethers.deployContract('contracts/composability/ExampleTransferSOLs.sol:ExampleTransferSOLs', [
            wSOLAddress
        ]);
        wSOL = await hre.ethers.getContractAt('contracts/composability/interfaces/IERC20ForSpl.sol:IERC20ForSpl', wSOLAddress);

        await ExampleTransferSOLs.waitForDeployment();
        console.log('\ExampleTransferSOLs deployed at', "\x1b[32m", ExampleTransferSOLs.target, "\x1b[30m", '\n');

        let tx = await wSOL.approve(
            ExampleTransferSOLs.target,
            1 * 10 ** 9
        );
        await tx.wait(RECEIPTS_COUNT);

        neonEvmUser = '0xb8f913C9AB9944891993F6c6fDAc421D98461294';
        solanaUser = '0x8bD39E9EBB92987831fAf444c4ACDEcbE6c6804E';

        console.log(await ExampleTransferSOLs.isSolanaUser(neonEvmUser), 'isSolanaUser(neonEvmUser)'); // proves that this address is not a Solana user
        console.log(await ExampleTransferSOLs.isSolanaUser(solanaUser), 'isSolanaUser(solanaUser)'); // proves that this address is a Solana user
    });

    describe('Tests', function() {
        it('Transfer WSOL to Neon EVM user', async function () {
            const initialwSOLBalance = await wSOL.balanceOf(neonEvmUser);
            console.log(initialwSOLBalance, 'initialwSOLBalance');

            let tx = await ExampleTransferSOLs.transferSOLorWSOL(
                0.001 * 10 ** 9,
                neonEvmUser
            );
            console.log(tx.hash, 'hash');
            await tx.wait(RECEIPTS_COUNT);

            const afterwSOLBalance = await wSOL.balanceOf(neonEvmUser);
            console.log(afterwSOLBalance, 'afterwSOLBalance');

            expect(afterwSOLBalance).to.be.greaterThan(initialwSOLBalance);
        });

        it('Transfer SOL to Solana user', async function () {
            const initialSOLBalance = await connection.getBalance(new web3.PublicKey(ethers.encodeBase58(await ExampleTransferSOLs.isSolanaUser(solanaUser))));
            console.log(initialSOLBalance, 'initialSOLBalance');

            let tx = await ExampleTransferSOLs.transferSOLorWSOL(
                0.001 * 10 ** 9,
                solanaUser
            );
            console.log(tx.hash, 'hash');
            await tx.wait(RECEIPTS_COUNT);

            const afterSOLBalance = await connection.getBalance(new web3.PublicKey(ethers.encodeBase58(await ExampleTransferSOLs.isSolanaUser(solanaUser))));
            console.log(afterSOLBalance, 'afterSOLBalance');

            expect(afterSOLBalance).to.be.greaterThan(initialSOLBalance);
        });
    });
});