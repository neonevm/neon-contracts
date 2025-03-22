// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Constants} from "../Constants.sol";
import {QueryAccount} from "../../../precompiles/QueryAccount.sol";
import {SolanaDataConverterLib} from "../../../utils/SolanaDataConverterLib.sol";
import {ICallSolana} from "../../../precompiles/ICallSolana.sol";
import {LibSPLTokenData} from "../spl-token-program/LibSPLTokenData.sol";
import {LibRaydiumErrors} from "./LibRaydiumErrors.sol";

/// @title LibRaydiumData
/// @author https://twitter.com/mnedelchev_
/// @notice XYZ
library LibRaydiumData {
    using SolanaDataConverterLib for bytes;
    using SolanaDataConverterLib for uint16;
    using SolanaDataConverterLib for uint64;

    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    struct PoolData {
        bytes32 ammConfig;
        bytes32 poolCreator;
        bytes32 tokenAVault;
        bytes32 tokenBVault;
        bytes32 lpMint;
        bytes32 tokenA;
        bytes32 tokenB;
        bytes32 tokenAProgram;
        bytes32 tokenBProgram;
        bytes32 observationKey;
    }

    struct ConfigData {
        bool disableCreatePool;
        uint16 index;
        uint64 tradeFeeRate;
        uint64 protocolFeeRate;
        uint64 fundFeeRate;
        uint64 createPoolFee;
        bytes32 protocolOwner;
        bytes32 fundOwner;
    }

    function getConfigAccount(uint16 index) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.CREATE_CPMM_POOL_PROGRAM_ID,
            abi.encodePacked(
                hex"616d6d5f636f6e666967", // "amm_config"
                abi.encodePacked(index)
            )
        );
    }

    function getCpmmPdaPoolId(
        bytes32 ammConfigId,
        bytes32 tokenA,
        bytes32 tokenB
    ) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.CREATE_CPMM_POOL_PROGRAM_ID,
            abi.encodePacked(
                hex"706f6f6c", // "pool"
                ammConfigId,
                tokenA,
                tokenB
            )
        );
    }

    function getPdaObservationId(
        bytes32 poolId
    ) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.CREATE_CPMM_POOL_PROGRAM_ID,
            abi.encodePacked(
                hex"6f62736572766174696f6e", // "observation"
                poolId
            )
        );
    }

    function getPdaLpMint(
        bytes32 poolId
    ) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.CREATE_CPMM_POOL_PROGRAM_ID,
            abi.encodePacked(
                hex"706f6f6c5f6c705f6d696e74", // "pool_lp_mint"
                poolId
            )
        );
    }

    function getPdaVault(
        bytes32 poolId,
        bytes32 tokenMint
    ) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.CREATE_CPMM_POOL_PROGRAM_ID,
            abi.encodePacked(
                hex"706f6f6c5f7661756c74", // "pool_vault"
                poolId,
                tokenMint
            )
        );
    }

    function getPdaPoolAuthority() internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.CREATE_CPMM_POOL_PROGRAM_ID,
            abi.encodePacked(
                hex"7661756c745f616e645f6c705f6d696e745f617574685f73656564" // "vault_and_lp_mint_auth_seed"
            )
        );
    }

    function getCpLockPda(bytes32 tokenMint) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.LOCK_CPMM_POOL_PROGRAM_ID,
            abi.encodePacked(
                hex"6c6f636b65645f6c6971756964697479", // "locked_liquidity"
                tokenMint
            )
        );
    }

    function getPdaMetadataKey(bytes32 tokenMint) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.METAPLEX_PROGRAM_ID,
            abi.encodePacked(
                hex"6d65746164617461", // "metadata"
                Constants.METAPLEX_PROGRAM_ID,
                tokenMint
            )
        );
    }

    function getPoolData(bytes32 poolId) internal view returns(PoolData memory) {
        (bool success, bytes memory data) = QueryAccount.data(
            uint256(poolId),
            0,
            328
        );
        require(success, LibRaydiumErrors.InvalidPool(poolId));

        return PoolData(
            data.toBytes32(8),
            data.toBytes32(40),
            data.toBytes32(72),
            data.toBytes32(104),
            data.toBytes32(136),
            data.toBytes32(168),
            data.toBytes32(200),
            data.toBytes32(232),
            data.toBytes32(264),
            data.toBytes32(296)
        );
    }

    function getConfigData(bytes32 configAccount) internal view returns(ConfigData memory) {
        (bool success, bytes memory data) = QueryAccount.data(
            uint256(configAccount),
            0,
            108
        );
        require(success, LibRaydiumErrors.InvalidConfig(configAccount));

        return ConfigData(
            data.toBool(9),
            (data.toUint16(10)).readLittleEndianUnsigned16(),
            (data.toUint64(12)).readLittleEndianUnsigned64(),
            (data.toUint64(20)).readLittleEndianUnsigned64(),
            (data.toUint64(28)).readLittleEndianUnsigned64(),
            (data.toUint64(36)).readLittleEndianUnsigned64(),
            data.toBytes32(44),
            data.toBytes32(76)
        );
    }

    function getTokenReserve(bytes32 poolId, bytes32 tokenMint) internal view returns(uint64) {
        return LibSPLTokenData.getSPLTokenAccountBalance(getPdaVault(poolId, tokenMint));
    }

    function getPoolLpAmount(bytes32 poolId) internal view returns(uint64) {
        return LibSPLTokenData.getSPLTokenSupply(getPdaLpMint(poolId));
    }

    function lpToAmount(
        uint64 lp,
        uint64 poolAmountA,
        uint64 poolAmountB,
        uint64 supply
    ) internal pure returns (uint64 amountA, uint64 amountB) {
        require(supply > 0, LibRaydiumErrors.ZeroSupply());

        amountA = (lp * poolAmountA) / supply;
        if (amountA > 0 && (lp * poolAmountA) % supply > 0) {
            amountA+=1;
        }

        amountB = (lp * poolAmountB) / supply;
        if (amountB > 0 && (lp * poolAmountB) % supply > 0) {
            amountB+=1;
        }
    }

    function getSwapOutput(
        bytes32 poolId,
        bytes32 configAccount,
        bytes32 inputToken,
        bytes32 outputToken,
        uint64 sourceAmount
    ) internal view returns(uint64) {
        LibRaydiumData.ConfigData memory configData = LibRaydiumData.getConfigData(configAccount);
        uint64 reserveInAmount = LibRaydiumData.getTokenReserve(poolId, inputToken);
        uint64 reserveOutAmount = LibRaydiumData.getTokenReserve(poolId, outputToken);

        uint64 tradeFee = ((sourceAmount * configData.tradeFeeRate) + 1000000 - 1) / 1000000;
        return reserveOutAmount - ((reserveInAmount * reserveOutAmount) / (reserveInAmount + sourceAmount - tradeFee));
    }

    function getSwapInput(
        bytes32 poolId,
        bytes32 configAccount,
        bytes32 inputToken,
        bytes32 outputToken,
        uint64 outputAmount
    ) internal view returns(uint64) {
        LibRaydiumData.ConfigData memory configData = LibRaydiumData.getConfigData(configAccount);
        uint64 reserveInAmount = LibRaydiumData.getTokenReserve(poolId, inputToken);
        uint64 reserveOutAmount = LibRaydiumData.getTokenReserve(poolId, outputToken);

        uint64 amountRealOut = (outputAmount > reserveOutAmount) ? reserveOutAmount - 1 : outputAmount;
        uint64 denominator = reserveOutAmount - amountRealOut;
        uint64 amountInWithoutFee = (reserveInAmount * amountRealOut) / denominator;
        return ((amountInWithoutFee * 1000000) / (1000000 - configData.tradeFeeRate));
    }
}