const createAccountWithSeed = require("./create-account-with-seed")
const createInitTokenMint = require("./create-init-token-mint")
const createInitATA = require("./create-init-ata")
const mintTokens = require("./mint-tokens")
const transferTokens = require("./transfer-tokens")
const updateMintAuthority = require("./update-mint-authority")
const revokeApproval = require("./revoke-approval")
const approve = require("./approve")
const splTokenData = require("./spl-token-data")

async function main() {
    // Add TestComposability contract address to config.js to re-used already deployed contract, otherwise a new
    // TestComposability contract is deployed
    // await createAccountWithSeed.main()
    const callSPLTokenProgramContractAddress = await createInitTokenMint.main()
    await createInitATA.main(callSPLTokenProgramContractAddress)
    await mintTokens.main(callSPLTokenProgramContractAddress)
    await approve.main(callSPLTokenProgramContractAddress)
    await splTokenData.main(callSPLTokenProgramContractAddress)
    // await transferTokens.main(callSPLTokenProgramContractAddress)
    // await revokeApproval.main(callSPLTokenProgramContractAddress)
    // await updateMintAuthority.main(callSPLTokenProgramContractAddress)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })