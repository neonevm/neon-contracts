// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { QueryAccountLib } from "../../../utils/QueryAccountLib.sol";
import { SolanaDataConverterLib } from "../../../utils/SolanaDataConverterLib.sol";

import { ICallSolana } from '../../../precompiles/ICallSolana.sol';

library LibSPLTokenData {
    using SolanaDataConverterLib for bytes;
    using SolanaDataConverterLib for uint64;

    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    bytes32 public constant TOKEN_PROGRAM_ID = 0x06ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9;
    bytes32 public constant ASSOCIATED_TOKEN_PROGRAM_ID = 0x8c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f859;
    uint8 public constant SPL_TOKEN_ACCOUNT_SIZE = 165;
    uint8 public constant SPL_TOKEN_MINT_SIZE = 82;

    struct SPLTokenAccountData {
        bytes32 mint;
        bytes32 owner;
        uint64 balance;
        bytes4 delegateOption;
        bytes32 delegate;
        bytes1 isInitialized;
        bytes4 isNativeOption;
        bytes8 isNative;
        uint64 delegatedAmount;
        bytes4 closeAuthorityOption;
        bytes32 closeAuthority;
    }

    struct SPLTokenMintData {
        bytes4 mintAuthorityOption;
        bytes32 mintAuthority;
        uint64 supply;
        bytes1 decimals;
        bytes1 isInitialized;
        bytes4 freezeAuthorityOption;
        bytes32 freezeAuthority;
    }

    // SPL token mint data getters

    function getSPLTokenMintIsInitialized(bytes32 tokenMint) internal view returns(bytes1) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenMint),
            45,
            1
        );
        require(success, "LibSPLTokenData.getSPLTokenMintIsInitialized: failed to query SPL Token account data");

        return bytes1(data.toUint8(0));
    }

    function getSPLTokenSupply(bytes32 tokenMint) internal view returns(uint64) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenMint),
            36,
            8
        );
        require(success, "LibSPLTokenData.getSPLTokenSupply: failed to query SPL Token mint data");

        return (data.toUint64(0)).readLittleEndianUnsigned64();
    }

    function getSPLTokenDecimals(bytes32 tokenMint) internal view returns(bytes1) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenMint),
            44,
            1
        );
        require(success, "LibSPLTokenData.getSPLTokenDecimals: failed to query SPL Token mint data");

        return bytes1(data.toUint8(0));
    }

    function getSPLTokenMintAuthority(bytes32 tokenMint) internal view returns(bytes32) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenMint),
            4,
            32
        );
        require(success, "LibSPLTokenData.getSPLTokenMintAuthority: failed to query SPL Token mint data");

        return data.toBytes32(0);
    }

    function getSPLTokenFreezeAuthority(bytes32 tokenMint) internal view returns(bytes32) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenMint),
            50,
            32
        );
        require(success, "LibSPLTokenData.getSPLTokenFreezeAuthority: failed to query SPL Token mint data");

        return data.toBytes32(0);
    }

    function getSPLTokenMintData(bytes32 tokenMint) internal view returns(SPLTokenMintData memory) {
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(tokenMint),
            0,
            SPL_TOKEN_MINT_SIZE
        );
        require(success, "LibSPLTokenData: failed to query SPL Token mint data");

        return SPLTokenMintData (
            bytes4(data.toUint32(0)), // 4 bytes mintAuthorityOption
            data.toBytes32(4), // 32 bytes mintAuthority
            (data.toUint64(36)).readLittleEndianUnsigned64(), // 8 bytes token supply
            bytes1(data.toUint8(44)), // 1 byte token decimals
            bytes1(data.toUint8(45)), // 1 byte isInitialized
            bytes4(data.toUint32(46)), // 4 bytes freezeAuthorityOption
            data.toBytes32(50) // 32 bytes freezeAuthority
        );
    }

    // SPL token account data getters

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
            SPL_TOKEN_ACCOUNT_SIZE
        );
        require(success, "LibSPLTokenData: failed to query SPL Token account data");

        return SPLTokenAccountData (
            data.toBytes32(0), // 32 bytes token mint
            data.toBytes32(32), // 32 bytes token account owner
            (data.toUint64(64)).readLittleEndianUnsigned64(), // 8 bytes token account balance
            bytes4(data.toUint32(72)), // 4 bytes delegateOption
            data.toBytes32(76), // 32 bytes delegate
            bytes1(data.toUint8(108)), // 1 byte isInitialized
            bytes4(data.toUint32(109)), // 4 bytes isNativeOption
            bytes8(data.toUint64(113)), // 8 bytes isNative
            (data.toUint64(121)).readLittleEndianUnsigned64(), // 8 bytes delegated amount
            bytes4(data.toUint32(129)), // 4 bytes closeAuthorityOption
            data.toBytes32(133) // 32 bytes closeAuthority
        );
    }

    function getAssociatedTokenAccount(
        bytes32 tokenMint,
        bytes32 userPubKey,
        uint8 nonce
    ) internal view returns(bytes32) {
        return _getAssociatedTokenAccount(tokenMint, userPubKey, nonce);
    }

    function _getAssociatedTokenAccount(
        bytes32 tokenMint,
        bytes32 userPubKey,
        uint8 nonce
    ) private view returns(bytes32) {
        return CALL_SOLANA.getResourceAddress(sha256(abi.encodePacked(
            userPubKey,
            TOKEN_PROGRAM_ID,
            tokenMint,
            nonce,
            ASSOCIATED_TOKEN_PROGRAM_ID
        )));
    }
}

