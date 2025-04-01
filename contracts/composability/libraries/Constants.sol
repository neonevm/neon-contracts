// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title Constants
/// @notice Helper library providing values used for interactions with Solana programs
/// @author maxpolizzo@gmail.com
library Constants {
    bytes32 public constant SYSTEM_PROGRAM_ID = bytes32(0);
    bytes32 public constant TOKEN_PROGRAM_ID = 0x06ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9;
    bytes32 public constant ASSOCIATED_TOKEN_PROGRAM_ID = 0x8c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f859;
    bytes32 public constant TOKEN_PROGRAM_2022_ID = 0x06ddf6e1ee758fde18425dbce46ccddab61afc4d83b90d27febdf928d8a18bfc;
    bytes32 public constant NEON_EVM_PROGRAM_ID = 0x09a4b472d9f2c537175e526beeedaab6768c80800edbf73b4410f48a91d651c1;
    bytes32 public constant METAPLEX_PROGRAM_ID = 0x0b7065b1e3d17c45389d527f6b04c3cd58b86c731aa0fdb549b6d1bc03f82946;
    bytes32 public constant MEMO_PROGRAM_V2_ID = 0x054a535a992921064d24e87160da387c7c35b5ddbc92bb81e41fa8404105448d;
    bytes32 public constant CREATE_CPMM_POOL_PROGRAM_ID = 0xa92a311a8898864d2063c8fccb536e1e8a304d8d53984c0a4eb3c14407d674e7;
    bytes32 public constant LOCK_CPMM_POOL_PROGRAM_ID = 0xb75efce9ea62e768edd9aa8e7e44b86dd3ebf9594bf7fc98f48048180c01db85;
    bytes32 public constant SYSVAR_RENT_PUBKEY = 0x06a7d517192c5c51218cc94c3d4af17f58daee089ba1fd44e3dbd98a00000000;
    bytes32 public constant CREATE_CPMM_POOL_FEE_ACC_PUBKEY = 0xdedf953b2e71837bb572ab091421997463fa9f21967cc2f503201e8415b3e4bf;
    bytes32 public constant LOCK_CPMM_POOL_AUTH_PUBKEY = 0x5b84b7b4bd6b01e36118873168e4ffbcb9afd2c18ac15440bb3b790f4ca279d1;
    bytes32 public constant CREATE_CPMM_POOL_AUTH = 0x65cd985f02a93c6a9d0c1c82c037ba621e302f4a5666f5af6be37f50a37c1406;
}
