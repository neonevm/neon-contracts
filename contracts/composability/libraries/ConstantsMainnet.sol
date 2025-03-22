// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

abstract contract Constants {
    bytes32 public constant SYSTEM_PROGRAM_ID = bytes32(0);
    bytes32 public constant TOKEN_PROGRAM_ID = 0x06ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9;
    bytes32 public constant ASSOCIATED_TOKEN_PROGRAM_ID = 0x8c97258f4e2489f1bb3d1029148e0d830b5a1399daff1084048e7bd8dbe9f859;
    bytes32 public constant TOKEN_PROGRAM_2022_ID = 0x06ddf6e1ee758fde18425dbce46ccddab61afc4d83b90d27febdf928d8a18bfc;
    bytes32 public constant METAPLEX_PROGRAM_ID = 0x0b7065b1e3d17c45389d527f6b04c3cd58b86c731aa0fdb549b6d1bc03f82946;
    bytes32 public constant MEMO_PROGRAM_V2_ID = 0x054a535a992921064d24e87160da387c7c35b5ddbc92bb81e41fa8404105448d;
    bytes32 public constant SYSVAR_RENT_PUBKEY = 0x06a7d517192c5c51218cc94c3d4af17f58daee089ba1fd44e3dbd98a00000000;
    bytes32 public immutable CREATE_CPMM_POOL_PROGRAM_ID;
    bytes32 public immutable CREATE_CPMM_POOL_AUTH;
    bytes32 public immutable CREATE_CPMM_POOL_FEE_ACC_PUBKEY;
    bytes32 public immutable LOCK_CPMM_POOL_PROGRAM_ID;
    bytes32 public immutable LOCK_CPMM_POOL_AUTH_PUBKEY;

    error InvalidChain(uint chainId);

    constructor() {
        uint chainId = getChainId();
        if (chainId == 245022926) {
            CREATE_CPMM_POOL_PROGRAM_ID = 0xa92a311a8898864d2063c8fccb536e1e8a304d8d53984c0a4eb3c14407d674e7;
            CREATE_CPMM_POOL_AUTH = 0x65cd985f02a93c6a9d0c1c82c037ba621e302f4a5666f5af6be37f50a37c1406;
            CREATE_CPMM_POOL_FEE_ACC_PUBKEY = 0xdedf953b2e71837bb572ab091421997463fa9f21967cc2f503201e8415b3e4bf;
            LOCK_CPMM_POOL_PROGRAM_ID = 0xb75efce9ea62e768edd9aa8e7e44b86dd3ebf9594bf7fc98f48048180c01db85;
            LOCK_CPMM_POOL_AUTH_PUBKEY = 0x5b84b7b4bd6b01e36118873168e4ffbcb9afd2c18ac15440bb3b790f4ca279d1;
        } else if (chainId == 245022934) {
            CREATE_CPMM_POOL_PROGRAM_ID = 0xa92a5a8b4f295952842550aa93fd5b95b5ace6a8eb920c93942e43690c20ec73;
            CREATE_CPMM_POOL_AUTH = 0xeb00d9f5b292b4214ac7d037b4d6f06450b964600df373052bb5e84f2f8e9a67;
            CREATE_CPMM_POOL_FEE_ACC_PUBKEY = 0xb7d0225254ac07e3b2bd3f86c1f0f1103fc0708cc15aef14073aa6453f55ea69;
            LOCK_CPMM_POOL_PROGRAM_ID = 0x0512beab2ce8df4ae4df3ef1c99125715ba425970925ebb5dc062e6fd34bb681;
            LOCK_CPMM_POOL_AUTH_PUBKEY = 0x277a887bf474290c61129a6baadc699798c2628291c926d2433624d9a79a601a;
        } else {
            revert InvalidChain(chainId);
        }
    }

    function getChainId() internal view returns(uint chainId) {
        assembly {
            chainId := chainid()
        }
    }
}