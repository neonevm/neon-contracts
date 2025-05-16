import hre from "hardhat"
import web3 from "@solana/web3.js"
import bs58 from "bs58"
import "dotenv/config"

export async function decryptWallets() {

    console.log("\n ", "\u{1F512} \x1b[36mDecrypting keystore secrets...\x1b[0m\n")

    const wallets = {}

    let keystorePassword
    if(process.env.KEYSTORE_PASSWORD) { // Keystore password can be stored in .env file
        keystorePassword = process.env.KEYSTORE_PASSWORD
    } else { // If not, ask for password in CLI
        keystorePassword = await hre.tasks.getTask("keystore").subtasks.get("askpwd").run()
    }

    const ethers = (await hre.network.connect()).ethers

    try{
        wallets.owner = new ethers.Wallet(
            await hre.tasks.getTask("keystore").subtasks.get("decrypt").run(
                {
                    key: "PRIVATE_KEY_OWNER",
                    password: keystorePassword
                }
            ),
            ethers.provider
        )
        console.log("   NeonEVM OWNER address:", wallets.owner.address)
    } catch (error) {
        // Do nothing
    }

    try{
        wallets.user1 = new ethers.Wallet(
            await hre.tasks.getTask("keystore").subtasks.get("decrypt").run(
                {
                    key: "PRIVATE_KEY_USER_1",
                    password: keystorePassword
                }
            ),
            ethers.provider
        )
        console.log("   NeonEVM USER_1 address:", wallets.user1.address)
    } catch (error) {
        // Do nothing
    }

    try{
        wallets.user2 = new ethers.Wallet(
            await hre.tasks.getTask("keystore").subtasks.get("decrypt").run(
                {
                    key: "PRIVATE_KEY_USER_2",
                    password: keystorePassword
                }
            ),
            ethers.provider
        )
        console.log("   NeonEVM USER_2 address:", wallets.user2.address)
    } catch (error) {
        // Do nothing
    }

    try{
        wallets.user3 = new ethers.Wallet(
            await hre.tasks.getTask("keystore").subtasks.get("decrypt").run(
                {
                    key: "PRIVATE_KEY_USER_3",
                    password: keystorePassword
                }
            ),
            ethers.provider
        )
        console.log("   NeonEVM USER_3 address:", wallets.user3.address)
    } catch (error) {
        // Do nothing
    }

    try{
        wallets.solanaUser1 = web3.Keypair.fromSecretKey(bs58.decode(
            await hre.tasks.getTask("keystore").subtasks.get("decrypt").run(
                {
                    key: "PRIVATE_KEY_SOLANA",
                    password: keystorePassword
                }
            )
        ))
        console.log("   Solana USER_1 address:", wallets.solanaUser1.publicKey.toBase58())
    } catch (error) {
        // Do nothing
    }

    try{
        wallets.solanaUser2 = web3.Keypair.fromSecretKey(bs58.decode(
            await hre.tasks.getTask("keystore").subtasks.get("decrypt").run(
                {
                    key: "PRIVATE_KEY_SOLANA_2",
                    password: keystorePassword
                }
            )
        ))
        console.log("   Solana USER_2 address:", wallets.solanaUser2.publicKey.toBase58())
    } catch (error) {
        // Do nothing
    }

    try{
        wallets.solanaUser3 = web3.Keypair.fromSecretKey(bs58.decode(
            await hre.tasks.getTask("keystore").subtasks.get("decrypt").run(
                {
                    key: "PRIVATE_KEY_SOLANA_3",
                    password: keystorePassword
                }
            )
        ))
        console.log("   Solana USER_3 address:", wallets.solanaUser3.publicKey.toBase58())
    } catch (error) {
        // Do nothing
    }

    try{
        wallets.solanaUser4 = web3.Keypair.fromSecretKey(bs58.decode(
            await hre.tasks.getTask("keystore").subtasks.get("decrypt").run(
                {
                    key: "PRIVATE_KEY_SOLANA_4",
                    password: keystorePassword
                }
            )
        ))
        console.log("   Solana USER_4 address:", wallets.solanaUser4.publicKey.toBase58())
    } catch (error) {
        // Do nothing
    }

    console.log("\n ", "\u{1F513} \x1b[36mSuccessfully decrypted keystore secrets!\x1b[0m\n")

    return wallets
}