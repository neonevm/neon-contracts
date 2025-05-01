const args = process.argv.slice(2);
const network = args[0];
const web3 = require("@solana/web3.js");
const {
    getAssociatedTokenAddress,
    createInitializeMint2Instruction,
    TOKEN_PROGRAM_ID,
    ASSOCIATED_TOKEN_PROGRAM_ID,
    MINT_SIZE,
    createMintToInstruction,
    createAssociatedTokenAccountInstruction
} = require('@solana/spl-token');
const { Metaplex } = require("@metaplex-foundation/js");
const bs58 = require("bs58");
const { createCreateMetadataAccountV3Instruction } = require("@metaplex-foundation/mpl-token-metadata");
const utils = require('../utils');
const config = require('../../config.js');
require("dotenv").config({path: __dirname + '/../../.env'});

const connection = new web3.Connection(config.svm_node[network], "processed");

const keypair = web3.Keypair.fromSecretKey(
    bs58.decode(process.env.PRIVATE_KEY_SOLANA)
);
console.log(keypair.publicKey.toBase58(), 'publicKey');

const solanaUser4 = web3.Keypair.fromSecretKey( // Solana user with tokens balance for airdropping tokens
    bs58.decode(process.env.PRIVATE_KEY_SOLANA_4)
);

async function init() {
    if (await connection.getBalance(keypair.publicKey) == 0) {
        await utils.airdropSOL(keypair);
    }

    const seed = 'seed' + Date.now().toString(); // random seed on each script call
    const createWithSeed = await web3.PublicKey.createWithSeed(keypair.publicKey, seed, new web3.PublicKey(TOKEN_PROGRAM_ID));
    console.log(createWithSeed, 'SPLToken mint address');

    let keypairAta = await getAssociatedTokenAddress(
        createWithSeed,
        keypair.publicKey,
        false
    );

    let keypairAta4 = await getAssociatedTokenAddress(
        createWithSeed,
        solanaUser4.publicKey,
        false
    );

    let tx = new web3.Transaction();
    tx.add(
        web3.SystemProgram.createAccountWithSeed({
            fromPubkey: keypair.publicKey,
            basePubkey: keypair.publicKey,
            newAccountPubkey: createWithSeed,
            seed: seed,
            lamports: await connection.getMinimumBalanceForRentExemption(MINT_SIZE), // enough lamports to make the account rent exempt
            space: MINT_SIZE,
            programId: new web3.PublicKey(TOKEN_PROGRAM_ID) // programId
        })
    );

    tx.add(
        createInitializeMint2Instruction(
            createWithSeed, 
            9, // decimals
            keypair.publicKey,
            keypair.publicKey,
            new web3.PublicKey(TOKEN_PROGRAM_ID) // programId
        )
    );

    const metaplex = new Metaplex(connection);
    const metadata = metaplex.nfts().pdas().metadata({mint: createWithSeed});
    tx.add(
        createCreateMetadataAccountV3Instruction(
            {
                metadata: metadata,
                mint: createWithSeed,
                mintAuthority: keypair.publicKey,
                payer: keypair.publicKey,
                updateAuthority: keypair.publicKey
            },
            {
                createMetadataAccountArgsV3: {
                    data: {
                        name: "Dev Neon EVM",
                        symbol: "devNEON",
                        uri: 'https://ipfs.io/ipfs/QmTZGs6GyUi3hTGtQiFNu4cYNMdMv4RS1XCyYVTQtjaXYF',
                        sellerFeeBasisPoints: 0,
                        collection: null,
                        creators: null,
                        uses: null
                    },
                    isMutable: true,
                    collectionDetails: null
                },
            }
        )
    );

    tx.add(
        createAssociatedTokenAccountInstruction(
            keypair.publicKey,
            keypairAta,
            keypair.publicKey,
            createWithSeed,
            TOKEN_PROGRAM_ID, 
            ASSOCIATED_TOKEN_PROGRAM_ID
        )
    );

    tx.add(
        createAssociatedTokenAccountInstruction(
            keypair.publicKey,
            keypairAta4,
            solanaUser4.publicKey,
            createWithSeed,
            TOKEN_PROGRAM_ID, 
            ASSOCIATED_TOKEN_PROGRAM_ID
        )
    );

    tx.add(
        createMintToInstruction(
            createWithSeed,
            keypairAta,
            keypair.publicKey,
            1500 * 10 ** 9 // mint 1500 tokens
        )
    );
    
    tx.add(
        createMintToInstruction(
            createWithSeed,
            keypairAta4,
            keypair.publicKey,
            1500 * 10 ** 9 // mint 1500 tokens
        )
    );

    await web3.sendAndConfirmTransaction(connection, tx, [keypair]);
    console.log('Transaction on Solana completed.');
    return;
}
init();