// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { CallSolana } from './CallSolana.sol';

import { LibCallSolana } from './libraries/LibCallSolana.sol';
import { LibSystemProgram } from "./libraries/system-program/LibSystemProgram.sol";

/// @title CallSystemProgram
/// @notice Example contract showing how to use LibSystemProgram library to interact with Solana's System program
/// @author maxpolizzo@gmail.com
contract CallSystemProgram is CallSolana {

    function getCreateWithSeedAccount(
        bytes32 basePubKey,
        bytes32 programId,
        bytes memory seed
    ) public pure returns(bytes32) {
        return LibSystemProgram.getCreateWithSeedAccount(basePubKey, programId, seed);
    }

    function createAccountWithSeed(
        bytes32 programId,
        bytes memory seed,
        uint64 accountSize,
        uint64 rentExemptBalance
    ) external {
        bytes32 payer = CALL_SOLANA.getPayer();
        bytes32 basePubKey = CALL_SOLANA.getNeonAddress(address(this));

        // Format createAccountWithSeed instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSystemProgram.formatCreateAccountWithSeedInstruction(
            payer,
            basePubKey,
            programId,
            seed,
            accountSize,
            rentExemptBalance
        );
        // Prepare createAccountWithSeed instruction
        bytes memory createAccountWithSeedIx = LibCallSolana.prepareSolanaInstruction(
            LibSystemProgram.SYSTEM_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute createAccountWithSeed instruction, sending rentExemptBalance lamports
        CALL_SOLANA.execute(rentExemptBalance, createAccountWithSeedIx);
    }
}
