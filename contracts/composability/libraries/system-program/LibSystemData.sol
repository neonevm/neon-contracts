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

    struct AccountInfo {
        bytes32 pubkey;
        uint64 lamports;
        bytes32 owner;
        bool executable;
        uint64 rent_epoch;
    }

    // System account data getters

    /// @param accountPubKey The 32 bytes Solana account public key
    /// @return lamport balance of the account as uint64
    function getBalance(bytes32 accountPubKey) internal view returns(uint64) {
        (bool success,  uint256 lamports) = QueryAccountLib.lamports(uint256(accountPubKey));
        require(success, "LibSystemData.getBalance: failed to query Solana account balance");

        return uint64(lamports);
    }

    /// @param accountPubKey The 32 bytes Solana account public key
    /// @return The 32 bytes public key of the account's owner
    function getOwner(bytes32 accountPubKey) internal view returns(bytes32) {
        (bool success,  bytes memory result) = QueryAccountLib.owner(uint256(accountPubKey));
        require(success, "LibSystemData.getOwner: failed to query Solana account owner");

        return result.toBytes32(0);
    }

    /// @param accountPubKey The 32 bytes Solana account public key
    /// @return true if the token mint is a program account, false otherwise
    function getIsExecutable(bytes32 accountPubKey) internal view returns(bool) {
        (bool success,  bool result) = QueryAccountLib.executable(uint256(accountPubKey));
        require(success, "LibSystemData.getIsExecutable: failed to query Solana account executable");

        return result;
    }

    /// @param accountPubKey The 32 bytes Solana account public key
    /// @return account's rent epoch as uint64
    function getRentEpoch(bytes32 accountPubKey) internal view returns(uint64) {
        (bool success,  uint256 result) = QueryAccountLib.rent_epoch(uint256(accountPubKey));
        require(success, "LibSystemData.getIsExecutable: failed to query Solana account executable");

        return uint64(result);
    }

    /// @param accountPubKey The 32 bytes Solana account public key
    /// @return account's allocated storage space in bytes as uint64
    function getSpace(bytes32 accountPubKey) internal view returns(uint64) {
        (bool success,  uint256 result) = QueryAccountLib.length(uint256(accountPubKey));
        require(success, "LibSystemData.getSpace: failed to query Solana account storage space");

        return uint64(result);
    }

    /// @param accountPubKey The 32 bytes Solana account public key
    /// @param size The uint8 bytes size of the data we want to get
    /// @return the account data bytes
    function getSystemAccountData(bytes32 accountPubKey, uint8 size) internal view returns(bytes memory) {
        if (size == 0) {
            return new bytes(0);
        }
        (bool success, bytes memory data) = QueryAccountLib.data(
            uint256(accountPubKey),
            0,
            size
        );
        require(success, "LibSystemData.getSystemAccountData: failed to query System account data");

        return data;
    }

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
