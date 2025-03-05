// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { QueryAccountLib } from "../../../utils/QueryAccountLib.sol";
import { SolanaDataConverterLib } from "../../../utils/SolanaDataConverterLib.sol";

library LibSPLTokenData {
    using SolanaDataConverterLib for bytes;
    using SolanaDataConverterLib for uint64;

    uint8 public constant SPL_TOKEN_ACCOUNT_DATA_LEN = 165;

    struct SPLTokenAccountData {
        bytes32 mint;
        bytes32 owner;
        uint64 balance;
        bytes4 delegateOption;
        bytes32 delegate;
        bytes1 state;
        bytes4 isNativeOption;
        bytes8 isNative;
        uint64 delegatedAmount;
        bytes4 closeAuthorityOption;
        bytes32 closeAuthority;
    }

    function getSPLTokenAccountBalance(bytes32 tokenAccount) internal view returns(uint64) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenAccount),
            64,
            8
        );
        require(success, "LibSPLTokenData.getSPLTokenAccountBalance: failed to query SPL Token account data");

        return (data.toUint64(0)).readLittleEndianUnsigned64();
    }

    function getSPLTokenAccountOwner(bytes32 tokenAccount) internal view returns(bytes32) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenAccount),
            32,
            32
        );
        require(success, "LibSPLTokenData.getSPLTokenAccountOwner: failed to query SPL Token account data");

        return data.toBytes32(0);
    }

    function getSPLTokenAccountMint(bytes32 tokenAccount) internal view returns(bytes32) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenAccount),
            0,
            32
        );
        require(success, "LibSPLTokenData.getSPLTokenAccountMint: failed to query SPL Token account data");

        return data.toBytes32(0);
    }

    function getSPLTokenAccountDelegate(bytes32 tokenAccount) internal view returns(bytes32) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenAccount),
            76,
            32
        );
        require(success, "LibSPLTokenData.getSPLTokenAccountDelegate: failed to query SPL Token account data");

        return data.toBytes32(0);
    }

    function getSPLTokenAccountDelegatedAmount(bytes32 tokenAccount) internal view returns(uint64) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenAccount),
            121,
            8
        );
        require(success, "LibSPLTokenData.getSPLTokenAccountDelegatedAmount: failed to query SPL Token account data");

        return (data.toUint64(0)).readLittleEndianUnsigned64();
    }

    function getSPLTokenAccountIsInitialized(bytes32 tokenAccount) internal view returns(bytes1) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenAccount),
            108,
            1
        );
        require(success, "LibSPLTokenData.getSPLTokenAccountIsInitialized: failed to query SPL Token account data");

        return bytes1(data.toUint8(0));
    }

    function getSPLTokenAccountIsNative(bytes32 tokenAccount) internal view returns(bytes8) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenAccount),
            113,
            8
        );
        require(success, "LibSPLTokenData.getSPLTokenAccountIsNative: failed to query SPL Token account data");

        return bytes8(data.toUint64(0));
    }

    function getSPLTokenAccountCloseAuthority(bytes32 tokenAccount) internal view returns(bytes32) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenAccount),
            133,
            32
        );
        require(success, "LibSPLTokenData.getSPLTokenAccountCloseAuthority: failed to query SPL Token account data");

        return data.toBytes32(0);
    }

    function getSPLTokenAccountData(bytes32 tokenAccount) internal view returns(SPLTokenAccountData memory) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenAccount),
            0,
            SPL_TOKEN_ACCOUNT_DATA_LEN
        );
        require(success, "LibSPLTokenData: failed to query SPL Token account data");

        return SPLTokenAccountData (
            data.toBytes32(0), // 32 bytes token mint
            data.toBytes32(32), // 32 bytes token account owner
            (data.toUint64(64)).readLittleEndianUnsigned64(), // 8 bytes token account balance
            bytes4(data.toUint32(72)), // 4 bytes delegateOption
            data.toBytes32(76), // 32 bytes delegate
            bytes1(data.toUint8(108)), // 1 byte state
            bytes4(data.toUint32(109)), // 4 bytes isNativeOption
            bytes8(data.toUint64(113)), // 8 bytes isNative
            (data.toUint64(121)).readLittleEndianUnsigned64(), // 8 bytes delegated amount
            bytes4(data.toUint32(129)), // 4 bytes closeAuthorityOption
            data.toBytes32(133) // 32 bytes closeAuthority
        );
    }
}
