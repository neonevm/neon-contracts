const { ethers } = require("hardhat");
const { expect } = require("chai");
const web3 = require("@solana/web3.js");
const { config } = require('./config');
require("dotenv").config();

let owner;
const ERC20ForSPLFactoryAddress = config.DATA.ADDRESSES.ERC20ForSplFactory;
let ERC20ForSPLFactory;
let ERC20ForSPL;
let ERC20ForSPLMintable;
let ERC20ForSplContractFactory;
let ERC20ForSplMintableContractFactory;
const TOKEN_MINT = config.utils.publicKeyToBytes32(config.DATA.ADDRESSES.ERC20ForSplTokenMint);
const RECEIPTS_COUNT = 1;

describe('Test init', async function () {
    before(async function() {
        [owner] = await ethers.getSigners();

        if (await ethers.provider.getBalance(owner.address) == 0) {
            await config.utils.airdropNEON(owner.address);
        }

        const ERC20ForSplFactoryContractFactory = await ethers.getContractFactory('contracts/token/ERC20ForSpl/erc20_for_spl_factory.sol:ERC20ForSplFactory');
        ERC20ForSplContractFactory = await ethers.getContractFactory('contracts/token/ERC20ForSpl/erc20_for_spl.sol:ERC20ForSpl');
        ERC20ForSplMintableContractFactory = await ethers.getContractFactory('contracts/token/ERC20ForSpl/erc20_for_spl.sol:ERC20ForSplMintable');
        
        if (ethers.isAddress(ERC20ForSPLFactoryAddress)) {
            console.log('\nCreating instance of already deployed ERC20ForSPLFactory contract on Neon EVM with address', "\x1b[32m", ERC20ForSPLFactoryAddress, "\x1b[30m", '\n');
            ERC20ForSPLFactory = ERC20ForSplFactoryContractFactory.attach(ERC20ForSPLFactoryAddress);
        } else {
            // deploy ERC20ForSPLFactory
            ERC20ForSPLFactory = await ethers.deployContract('contracts/token/ERC20ForSpl/erc20_for_spl_factory.sol:ERC20ForSplFactory');
            await ERC20ForSPLFactory.waitForDeployment();
            console.log('\nCreating instance of just now deployed ERC20ForSplFactory contract on Neon EVM with address', "\x1b[32m", ERC20ForSPLFactory.target, "\x1b[30m", '\n'); 
        }
    });

    describe('ERC20ForSPL tests', function() {
        it('createErc20ForSpl', async function () {
            if (TOKEN_MINT == '') {
                this.skip();
            }

            tx = await ERC20ForSPLFactory.createErc20ForSpl(TOKEN_MINT);
            await tx.wait(RECEIPTS_COUNT);

            const getErc20ForSpl = await ERC20ForSPLFactory.getErc20ForSpl(TOKEN_MINT);
            expect(getErc20ForSpl).to.not.eq(ethers.ZeroAddress);
            expect(await ethers.provider.getCode(getErc20ForSpl)).to.not.eq('0x');

            ERC20ForSPL = ERC20ForSplContractFactory.attach(getErc20ForSpl);
        });

        it('createErc20ForSplMintable', async function () {
            tx = await ERC20ForSPLFactory.createErc20ForSplMintable(
                "Test",
                "TESTCOIN",
                9,
                owner.address
            );
            await tx.wait(RECEIPTS_COUNT);

            const getErc20ForSplMintable = await ERC20ForSPLFactory.allErc20ForSpl(
                parseInt((await ERC20ForSPLFactory.allErc20ForSplLength()).toString()) - 1
            );
            expect(getErc20ForSplMintable).to.not.eq(ethers.ZeroAddress);
            expect(await ethers.provider.getCode(getErc20ForSplMintable)).to.not.eq('0x');

            ERC20ForSPLMintable = ERC20ForSplMintableContractFactory.attach(getErc20ForSplMintable);
        });

        it('allErc20ForSplLength', async function () {
            expect(await ERC20ForSPLFactory.allErc20ForSplLength()).to.eq(2);
        });
        
        describe('Reverts',  function() {
            it('ERC20ForSplAlreadyExists', async function () {
                await expect(
                    ERC20ForSPLFactory.createErc20ForSpl(TOKEN_MINT)
                ).to.be.revertedWithCustomError(
                    ERC20ForSPLFactory,
                    'ERC20ForSplAlreadyExists'
                );
            });

            it('ERC20ForSplNotCreated', async function () {
                await expect(
                    ERC20ForSPLFactory.createErc20ForSpl("0x0000000000000000000000000000000000000000000000000000000000000001")
                ).to.be.revertedWithCustomError(
                    ERC20ForSPLFactory,
                    'ERC20ForSplNotCreated'
                );
            });
            
            it('ERC20ForSplMintableNotCreated', async function () {
                await expect(
                    ERC20ForSPLFactory.createErc20ForSplMintable(
                        "Test",
                        "TESTCOIN",
                        9,
                        ethers.ZeroAddress
                    )
                ).to.be.revertedWithCustomError(
                    ERC20ForSPLFactory,
                    'ERC20ForSplMintableNotCreated'
                );
            });
        });
    });
});