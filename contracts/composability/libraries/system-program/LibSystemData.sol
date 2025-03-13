// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { QueryAccountLib } from "../../../utils/QueryAccountLib.sol";
import { SolanaDataConverterLib } from "../../../utils/SolanaDataConverterLib.sol";

import { ICallSolana } from '../../../precompiles/ICallSolana.sol';

/// @title LibSystemData
/// @notice Helper library for getting data from Solana's System program
/// @author maxpolizzo@gmail.com
library LibSystemData {
    using SolanaDataConverterLib for bytes;
    using SolanaDataConverterLib for uint64;

    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    

    /// @notice Helper function to derive the address of the Solana account which would be created by executing a
    /// `createAccountWithSeed` instruction formatted with the same parameters
    /// @param basePubKey The base public key used to derive the newly created account
    /// @param programId The id of the Solana program which would be granted permission to write data to the newly
    /// created account
    /// @param seed The bytes seed used to derive the newly created account
    function getCreateWithSeedAccount(
        bytes32 basePubKey,
        bytes32 programId,
        bytes memory seed
    ) internal pure returns(bytes32) {
        return sha256(abi.encodePacked(basePubKey, seed, programId));
    }
}
