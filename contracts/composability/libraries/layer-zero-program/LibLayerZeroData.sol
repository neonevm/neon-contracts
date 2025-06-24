// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {QueryAccount} from "../../../precompiles/QueryAccount.sol";
import {SolanaDataConverterLib} from "../../../utils/SolanaDataConverterLib.sol";
import {ICallSolana} from "../../../precompiles/ICallSolana.sol";


/// @title LibLayerZeroData
/// @author https://twitter.com/mnedelchev_
/// @notice XYZ
library LibLayerZeroData {
    using SolanaDataConverterLib for *;

    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);
    bytes32 public constant L0_ENDPOINT_SOLANA = 0x5aad76da514b6e1dcf11037e904dac3d375f525c9fbafcb19507b78907d8c18b;
    bytes32 public constant L0_ULN302_PROGRAM = 0x619e429a1de67854bd455ee6643f568d6236cde8e9442a3abf029f016faae630;
    bytes32 public constant L0_EXECUTOR_PROGRAM = 0x53b82142f29732a56fb6c88fa402fd18a1ddca13741d6ba73d3fcf9ae81021c1;
    bytes32 public constant L0_EXECUTOR_PDA = 0x93c69e71c758b9a308dd542e1c7f6edbf4b2342a6b74a0ce955ea97675f85528;
    bytes32 public constant L0_PRICE_FEED = 0x70a3a32bf0513da92b05bed7ded97b739207b454ec7511f70803effbd7ca7ed6;
    bytes32 public constant L0_PRICE_FEED_CONFIG = 0xa9e8e3f0cc7faf9e3d83bbc89f2a3ee83997cb1d181a51c09e8fe565c7c0d755;
    bytes32 public constant L0_DVN = 0xfadaeccd4478463214d9a94537bfa687a1e9176e12a48888491d9502f7dace21;

    function sendLibraryConfig(bytes32 sender, uint32 _dstEid) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            L0_ENDPOINT_SOLANA,
            abi.encodePacked(
                hex"53656E644C696272617279436F6E666967", // "SendLibraryConfig"
                sender,
                _dstEid.readLittleEndianUnsigned32()
            )
        );
    }

    function defaultSendLibraryConfig(uint32 _dstEid) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            L0_ENDPOINT_SOLANA,
            abi.encodePacked(
                hex"53656E644C696272617279436F6E666967", // "SendLibraryConfig"
                _dstEid.readLittleEndianUnsigned32()
            )
        );
    }

    function sendLibraryInfo(bytes32 sendLibraryConfig) internal view returns(bytes32) {
        (bool success, bytes memory data) = QueryAccount.data(
            uint256(sendLibraryConfig),
            8,
            40
        );
        require(success, "ERROR: sendLibraryInfo");

        return CALL_SOLANA.getSolanaPDA(
            L0_ENDPOINT_SOLANA,
            abi.encodePacked(
                hex"4D6573736167654C6962", // "MessageLib"
                data.toBytes32(0)
            )
        );
    }

    function endpoint() internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            L0_ENDPOINT_SOLANA,
            abi.encodePacked(
                hex"456E64706F696E74" // "Endpoint"
            )
        );
    }

    function nonce(bytes32 sender, uint32 _dstEid, bytes32 receiver) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            L0_ENDPOINT_SOLANA,
            abi.encodePacked(
                hex"4E6F6E6365", // "Nonce"
                sender,
                _dstEid.readLittleEndianUnsigned32(),
                receiver
            )
        );
    }

    function eventAuthorityEndpoint() internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            L0_ENDPOINT_SOLANA,
            abi.encodePacked(
                hex"5F5F6576656E745F617574686F72697479" // "__event_authority"
            )
        );
    }

    function eventAuthorityULN() internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            L0_ULN302_PROGRAM,
            abi.encodePacked(
                hex"5F5F6576656E745F617574686F72697479" // "__event_authority"
            )
        );
    }

    function ulnSettingsAddress() internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            L0_ULN302_PROGRAM,
            abi.encodePacked(
                hex"4D6573736167654C6962" // "MessageLib"
            )
        );
    }

    function sendConfig(bytes32 sender, uint32 _dstEid) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            L0_ULN302_PROGRAM,
            abi.encodePacked(
                hex"53656E64436F6E666967", // "SendConfig"
                _dstEid.readLittleEndianUnsigned32(),
                sender
            )
        );
    }

    function sendDefaultConfig(uint32 _dstEid) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            L0_ULN302_PROGRAM,
            abi.encodePacked(
                hex"53656E64436F6E666967", // "SendConfig"
                _dstEid.readLittleEndianUnsigned32()
            )
        );
    }

    function dvnConfig() internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            L0_DVN,
            abi.encodePacked(
                hex"44766E436F6E666967" // "DvnConfig"
            )
        );
    }
}