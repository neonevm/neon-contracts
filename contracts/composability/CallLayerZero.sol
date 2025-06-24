// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { CallSolanaHelperLib } from '../utils/CallSolanaHelperLib.sol';
import { LibLayerZeroProgram } from "./libraries/layer-zero-program/LibLayerZeroProgram.sol";
import { LibLayerZeroData } from "./libraries/layer-zero-program/LibLayerZeroData.sol";
import { ICallSolana } from '../precompiles/ICallSolana.sol';


contract CallLayerZero {
    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    function lzSend(
        uint64 lamports,
        bytes32 peer, // optimize this
        uint32 _dstEid, 
        bytes memory _message, 
        bytes memory _options, 
        LibLayerZeroProgram.MessagingFee memory _fee
    ) external {
        (
            bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibLayerZeroProgram.lzSend(peer, _dstEid, _message, _options, _fee, true);

        CALL_SOLANA.execute(
            lamports,
            CallSolanaHelperLib.prepareSolanaInstruction(
                LibLayerZeroData.L0_ENDPOINT_SOLANA,
                accounts,
                isSigner,
                isWritable,
                data
            )
        );
    }
}
