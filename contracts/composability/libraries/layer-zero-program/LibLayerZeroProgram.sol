// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Constants} from "../Constants.sol";
import {ICallSolana} from "../../../precompiles/ICallSolana.sol";
import {LibAssociatedTokenData} from "../associated-token-program/LibAssociatedTokenData.sol";
import {LibLayerZeroData} from "./LibLayerZeroData.sol";
import {LibSPLTokenData} from "../spl-token-program/LibSPLTokenData.sol";
import {LibSystemData} from "../system-program/LibSystemData.sol";
import {LibMetaplexData} from "../metaplex-program/LibMetaplexData.sol";
import {SolanaDataConverterLib} from "../../../utils/SolanaDataConverterLib.sol";


/// @title LibLayerZero
/// @author https://twitter.com/mnedelchev_
/// @notice XYZ
library LibLayerZeroProgram {
    using SolanaDataConverterLib for *;

    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    struct MessagingFee {
        uint64 nativeFee;
        uint64 lzTokenFee;
    }

    function lzSend(
        bytes32 peer, // optimize this
        uint32 _dstEid, 
        bytes memory _message, 
        bytes memory _options, 
        MessagingFee memory _fee,
        bool returnData
    ) internal view returns (
        bytes32[] memory accounts,
        bool[] memory isSigner,
        bool[] memory isWritable,
        bytes memory data
    ) {
        accounts = new bytes32[](25);
        accounts[0] = CALL_SOLANA.getPayer();
        accounts[1] = LibLayerZeroData.L0_ULN302_PROGRAM;
        accounts[2] = LibLayerZeroData.sendLibraryConfig(accounts[0], _dstEid);
        accounts[3] = LibLayerZeroData.defaultSendLibraryConfig(_dstEid);
        accounts[4] = LibLayerZeroData.sendLibraryInfo(accounts[2]);
        accounts[5] = LibLayerZeroData.endpoint();
        accounts[6] = LibLayerZeroData.nonce(accounts[0], _dstEid, peer);
        accounts[7] = LibLayerZeroData.eventAuthorityEndpoint();
        accounts[8] = LibLayerZeroData.L0_ENDPOINT_SOLANA;
        accounts[9] = LibLayerZeroData.ulnSettingsAddress();
        accounts[10] = LibLayerZeroData.sendConfig(accounts[0], _dstEid);
        accounts[11] = LibLayerZeroData.sendDefaultConfig(_dstEid);
        accounts[12] = accounts[0];
        accounts[13] = LibLayerZeroData.L0_ULN302_PROGRAM;
        accounts[14] = Constants.getSystemProgramId();
        accounts[15] = LibLayerZeroData.eventAuthorityULN();
        accounts[16] = LibLayerZeroData.L0_ULN302_PROGRAM;
        accounts[17] = LibLayerZeroData.L0_EXECUTOR_PROGRAM;
        accounts[18] = LibLayerZeroData.L0_EXECUTOR_PDA;
        accounts[19] = LibLayerZeroData.L0_PRICE_FEED;
        accounts[20] = LibLayerZeroData.L0_PRICE_FEED_CONFIG;
        accounts[21] = LibLayerZeroData.L0_DVN;
        accounts[22] = LibLayerZeroData.dvnConfig();
        accounts[23] = LibLayerZeroData.L0_PRICE_FEED;
        accounts[24] = LibLayerZeroData.L0_PRICE_FEED_CONFIG;

        isSigner = new bool[](25);
        isSigner[12] = true;

        isWritable = new bool[](25);
        isWritable[0] = true;
        isWritable[6] = true;
        isWritable[12] = true;
        isWritable[18] = true;
        isWritable[22] = true;

        if (returnData) {
            data = buildLzSendData(_dstEid, peer, _message, _options, _fee);
        }
    }

    function buildLzSendData(
        uint32 _dstEid, 
        bytes32 peer, // optimize this
        bytes memory _message, 
        bytes memory _options, 
        MessagingFee memory _fee
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            hex"66fb14bb414b0c45", // [102, 251, 20, 187, 65, 75, 12, 69]
            _dstEid.readLittleEndianUnsigned32(),
            peer,
            _message,
            _options,
            _fee.nativeFee.readLittleEndianUnsigned64(),
            _fee.lzTokenFee.readLittleEndianUnsigned64()
        );
    }
}