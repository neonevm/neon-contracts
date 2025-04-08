// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Constants } from "../Constants.sol";
import { LibAssociatedTokenData } from "./LibAssociatedTokenData.sol";
import { LibSystemData } from "../system-program/LibSystemData.sol";

/// @title LibAssociatedTokenProgram
/// @notice Helper library for interactions with Solana's Associated Token program
/// @author maxpolizzo@gmail.com
library LibAssociatedTokenProgram {
    /// @notice Helper function to format a `create` instruction in order to create and initialize a canonical
    /// associated token account (ATA)
    /// @param payer The payer account which will fund the newly created account
    /// @param ata The canonical associated token account to be created and initialized
    /// @param owner The account owning the associated token account
    /// @param tokenMint The token mint account to which the new token account will be associated
    function formatCreateInstruction(
        bytes32 payer,
        bytes32 ata,
        bytes32 owner,
        bytes32 tokenMint
    ) internal view returns (
        bytes32[] memory accounts,
        bool[] memory isSigner,
        bool[] memory isWritable,
        bytes memory data,
        uint64 rentExemptionBalance
    ) {
        accounts = new bytes32[](6);
        accounts[0] = payer;
        accounts[1] = ata;
        accounts[2] = owner;
        accounts[3] = tokenMint;
        accounts[4] = Constants.getSystemProgramId();
        accounts[5] = Constants.getTokenProgramId();

        isSigner = new bool[](6);
        isSigner[0] = true;
        isSigner[1] = false;
        isSigner[2] = false;
        isSigner[3] = false;
        isSigner[4] = false;
        isSigner[5] = false;

        isWritable = new bool[](6);
        isWritable[0] = true;
        isWritable[1] = true;
        isWritable[2] = false;
        isWritable[3] = false;
        isWritable[4] = false;
        isWritable[5] = false;

        // Calculate rent exemption balance for created ata
        rentExemptionBalance = LibSystemData.getRentExemptionBalance(
            LibAssociatedTokenData.ASSOCIATED_TOKEN_ACCOUNT_SIZE,
            LibSystemData.getSystemAccountData(
                Constants.getSysvarRentPubkey(),
                LibSystemData.getSpace(Constants.getSysvarRentPubkey())
            )
        );

        data = new bytes(0); // data is left empty (see: https://github.com/solana-program/associated-token-account/blob/ea3b78b46187cd545b9ba0902b7c221ef9d5d223/program/src/processor.rs#L44)
    }
}
