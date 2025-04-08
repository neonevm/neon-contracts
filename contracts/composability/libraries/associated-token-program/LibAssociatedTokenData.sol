// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Constants } from "../Constants.sol";
import { ICallSolana } from '../../../precompiles/ICallSolana.sol';

/// @title LibAssociatedTokenData
/// @notice Helper library for getting data related to Solana's Associated Token program
/// @author maxpolizzo@gmail.com
library LibAssociatedTokenData {

    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    uint8 public constant ASSOCIATED_TOKEN_ACCOUNT_SIZE = 165;

    /// @notice Function to get the 32 bytes canonical associated token account public key derived from a token mint
    /// account public key and a user public key
    /// @param tokenMint The 32 bytes public key of the token mint associated with the token account we want to get
    /// @param ownerPubKey The 32 bytes public key of the owner of the associated token account
    /// @return the 32 bytes token account public key derived from the token mint account public key, the user public
    /// key and the nonce
    function getAssociatedTokenAccount(
        bytes32 tokenMint,
        bytes32 ownerPubKey
    ) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.getAssociatedTokenProgramId(),
            abi.encodePacked(
                ownerPubKey,
                Constants.getTokenProgramId(),
                tokenMint
            )
        );
    }
}
