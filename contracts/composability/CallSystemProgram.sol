// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { CallSolanaHelperLib } from '../utils/CallSolanaHelperLib.sol';
import { Constants } from "./libraries/Constants.sol";
import { LibSystemData } from "./libraries/system-program/LibSystemData.sol";
import { LibSystemProgram } from "./libraries/system-program/LibSystemProgram.sol";

import { ICallSolana } from '../precompiles/ICallSolana.sol';

/// @title CallSystemProgram
/// @notice Example contract showing how to use LibSystemProgram library to interact with Solana's System program
/// @author maxpolizzo@gmail.com
contract CallSystemProgram {
    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    function getNeonAddress(address user) external view returns (bytes32) {
        return CALL_SOLANA.getNeonAddress(user);
    }

    function getCreateWithSeedAccount(
        bytes32 basePubKey,
        bytes32 programId,
        bytes memory seed
    ) public pure returns(bytes32) {
        return LibSystemData.getCreateWithSeedAccount(basePubKey, programId, seed);
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
        bytes memory createAccountWithSeedIx = CallSolanaHelperLib.prepareSolanaInstruction(
            Constants.SYSTEM_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute createAccountWithSeed instruction, sending rentExemptBalance lamports
        CALL_SOLANA.execute(rentExemptBalance, createAccountWithSeedIx);
    }

    function transfer(
        bytes32 recipient,
        uint64 amount
    ) external {
        // Payer account will pay the SOL amount while msg.sender will pay gas fees covering that amount plus
        // transaction fees
        bytes32 payer = CALL_SOLANA.getPayer();

        // Format transfer instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSystemProgram.formatTransferInstruction(
            payer,
            recipient,
            amount
        );
        // Prepare transfer instruction
        bytes memory transferIx = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSystemProgram.SYSTEM_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute transfer instruction, sending amount lamports
        CALL_SOLANA.execute(amount, transferIx);
    }

    function assign(
        bytes32 programId,
        bytes memory seed
    ) external {
        bytes32 basePubKey = CALL_SOLANA.getNeonAddress(address(this));

        // Format assignWithSeed instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSystemProgram.formatAssignWithSeedInstruction(
            basePubKey,
            programId,
            seed
        );
        // Prepare assignWithSeed instruction
        bytes memory assignWithSeedIx = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSystemProgram.SYSTEM_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute assignWithSeed instruction
        CALL_SOLANA.execute(0, assignWithSeedIx);
    }

    function allocate(
        bytes32 programId,
        bytes memory seed,
        uint64 accountSize
    ) external {
        bytes32 basePubKey = CALL_SOLANA.getNeonAddress(address(this));

        // Format allocateWithSeed instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSystemProgram.formatAllocateWithSeedInstruction(
            basePubKey,
            programId,
            seed,
            accountSize
        );
        // Prepare allocateWithSeed instruction
        bytes memory allocateWithSeedIx = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSystemProgram.SYSTEM_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute allocateWithSeed instruction
        CALL_SOLANA.execute(0, allocateWithSeedIx);
    }
}
