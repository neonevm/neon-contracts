module.exports = {
    neon_faucet: {
        curvestand: {
            url: "https://curve-stand.neontest.xyz/request_neon",
            min_balance: "10000",
        },
        neondevnet: {
            url: "https://api.neonfaucet.org/request_neon",
            min_balance: "100",
        },
        neonmainnet: {
            url: "",
            min_balance: "0",
        },
    },
    evm_sol_node: {
        curvestand: "https://curve-stand.neontest.xyz/SOL",
        neondevnet: "https://devnet.neonevm.org/SOL",
        neonmainnet: "https://neonevm.org/SOL",
    },
    svm_node: {
        curvestand: "https://curve-stand.neontest.xyz/solana",
        neondevnet: "https://api.devnet.solana.com",
        neonmainnet: "https://api.mainnet-beta.solana.com",
    },
    composability: {
        CallSystemProgram: {
            curvestand: "",
            neondevnet: "",
            neonmainnet: "",
        },
        MockCallSystemProgram: {
            curvestand: "",
            neondevnet: "",
            neonmainnet: "",
        },
        CallSPLTokenProgram: {
            curvestand: "",
            neondevnet: "",
            neonmainnet: "",
        },
        CallAssociatedTokenProgram: {
            curvestand: "",
            neondevnet: "",
            neonmainnet: "",
        },
        CallRaydiumProgram: {
            curvestand: "",
            neondevnet: "",
            neonmainnet: "",
        },
        tokenMintSeed: {
            curvestand: "myTokenMintSeed",
            neondevnet: "myTokenMintSeed",
            neonmainnet: "myTokenMintSeed",
        },
        tokenMintDecimals: {
            curvestand: 9,
            neondevnet: 9,
            neonmainnet: 9,
        }
    },
    token: {
        ERC20ForSplFactory: {
            curvestand: "",
            neondevnet: "",
            neonmainnet: "",
        },
        ERC20ForSpl: {
            curvestand: "",
            neondevnet: "",
            neonmainnet: "",
        },
        ERC20ForSplTokenMint: {
            curvestand: "7tJqfMmvXaeg8cv26n6imvqT6bZJu6yseUkU3DSkupxL",
            neondevnet: "",
            neonmainnet: "",
        },
        MockVault: {
            curvestand: "",
            neondevnet: "",
            neonmainnet: "",
        }
    }
}

