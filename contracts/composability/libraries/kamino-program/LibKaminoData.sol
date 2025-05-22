// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Constants} from "../Constants.sol";
import {QueryAccount} from "../../../precompiles/QueryAccount.sol";
import {SolanaDataConverterLib} from "../../../utils/SolanaDataConverterLib.sol";
import {ICallSolana} from "../../../precompiles/ICallSolana.sol";
import {LibSPLTokenData} from "../spl-token-program/LibSPLTokenData.sol";
import {LibKaminoErrors} from "./LibKaminoErrors.sol";


/// @title LibKaminoData
/// @author https://twitter.com/mnedelchev_
/// @notice Helper library for getting data about Kamino Program
library LibKaminoData {
    using SolanaDataConverterLib for *;
    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    struct ReserveData {
        bytes32 lendingMarket;
        bytes32 farmCollateral;
        bytes32 farmDebt;
    }

    struct ReserveLiquidity {
        bytes32 mintPubkey;
        bytes32 supplyVault;
        bytes32 feeVault;
        uint64 availableAmount;
        uint128 borrowedAmountSf;
        uint128 marketPriceSf;
        uint64 marketPriceLastUpdatedTs;
        uint64 mintDecimals;
        uint64 depositLimitCrossedTimestamp;
        uint64 borrowLimitCrossedTimestamp;
    }

    struct ReserveCollateral {
        bytes32 mintPubkey;
        uint64 mintTotalSupply;
        bytes32 supplyVault;
    }

    struct ReserveConfig {
        uint8 status;
        uint8 assetTier;
        uint16 hostFixedInterestRateBps;
        uint8 protocolTakeRatePct;
        uint8 protocolLiquidationFeePct;
        uint8 loanToValuePct;
        uint8 liquidationThresholdPct;
        uint16 minLiquidationBonusBps;
        uint16 maxLiquidationBonusBps;
        uint16 badDebtLiquidationBonusBps;
        uint64 deleveragingMarginCallPeriodSecs;
        uint64 deleveragingThresholdDecreaseBpsPerDay;
        uint64 borrowFactorPct;
        uint64 depositLimit;
        uint64 borrowLimit;
    }

    function getLendingMarketAuthPda(
        bytes32 lendingMarket
    ) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.getKaminoLendingProgramId(),
            abi.encodePacked(
                hex"6c6d61", // "lma"
                lendingMarket
            )
        );
    }

    function getReserveLiqSupplyPda(
        bytes32 lendingMarket,
        bytes32 tokenMint
    ) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.getKaminoLendingProgramId(),
            abi.encodePacked(
                hex"726573657276655f6c69715f737570706C79", // "reserve_liq_supply"
                lendingMarket,
                tokenMint
            )
        );
    }

    function getReserveCollateralMintPda(
        bytes32 lendingMarket,
        bytes32 tokenMint
    ) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.getKaminoLendingProgramId(),
            abi.encodePacked(
                hex"726573657276655f636f6c6c5f6d696e74", // "reserve_coll_mint"
                lendingMarket,
                tokenMint
            )
        );
    }

    function getReserveData(
        bytes32 reserve
    ) internal view returns(ReserveData memory) {
        (bool success, bytes memory data) = QueryAccount.data(
            uint256(reserve),
            0,
            128
        );
        require(success, "ERR");

        return ReserveData(
            data.toBytes32(32),
            data.toBytes32(64),
            data.toBytes32(96)
        );
    }

    function getReserveLiquidity(
        bytes32 reserve
    ) internal view returns(ReserveLiquidity memory) {
        (bool success, bytes memory data) = QueryAccount.data(
            uint256(reserve),
            0,
            296
        );
        require(success, "ERR");

        return ReserveLiquidity(
            data.toBytes32(128),
            data.toBytes32(160),
            data.toBytes32(192),
            (data.toUint64(224)).readLittleEndianUnsigned64(),
            (data.toUint128(232)).readLittleEndianUnsigned128(),
            (data.toUint128(248)).readLittleEndianUnsigned128(),
            (data.toUint64(264)).readLittleEndianUnsigned64(),
            (data.toUint64(272)).readLittleEndianUnsigned64(),
            (data.toUint64(280)).readLittleEndianUnsigned64(),
            (data.toUint64(288)).readLittleEndianUnsigned64()
        );
    }

    function getReserveCollateral(
        bytes32 reserve
    ) internal view returns(ReserveCollateral memory) {
        (bool success, bytes memory data) = QueryAccount.data(
            uint256(reserve),
            0,
            2632
        );
        require(success, "ERR");

        return ReserveCollateral(
            data.toBytes32(2560),
            (data.toUint64(2592)).readLittleEndianUnsigned64(),
            data.toBytes32(2600)
        );
    }

    function getReserveConfig(
        bytes32 reserve
    ) internal view returns(ReserveConfig memory) {
        (bool success, bytes memory data) = QueryAccount.data(
            uint256(reserve),
            0,
            4878
        );
        require(success, "ERR");

        return ReserveConfig(
            data.toUint8(4856),
            data.toUint8(4857),
            (data.toUint16(4858)).readLittleEndianUnsigned16(),
            data.toUint8(4870),
            data.toUint8(4871),
            data.toUint8(4872),
            data.toUint8(4873),
            (data.toUint16(4874)).readLittleEndianUnsigned16(),
            (data.toUint16(4876)).readLittleEndianUnsigned16(),
            (data.toUint16(4878)).readLittleEndianUnsigned16(),
            (data.toUint64(4880)).readLittleEndianUnsigned64(),
            (data.toUint64(4888)).readLittleEndianUnsigned64(),
            (data.toUint64(5008)).readLittleEndianUnsigned64(),
            (data.toUint64(5016)).readLittleEndianUnsigned64(),
            (data.toUint64(5024)).readLittleEndianUnsigned64()
        );
    }

    function getReserveApy(
        bytes32 lendingMarket,
        bytes32 tokenMint
    ) internal view returns(bytes32) {
        //https://github.com/Kamino-Finance/klend-sdk/blob/master/examples/example_reserve_apy.ts#L9
        //supplyApy
        //borrowApy
        //rewardApys
    }

    function getReserveRewardApys(
        bytes32 lendingMarket,
        bytes32 tokenMint
    ) internal view returns(bytes32) {
        //https://github.com/Kamino-Finance/klend-sdk/blob/master/examples/example_reserve_apy.ts#L9
        //supplyApy
        //supplyApr
        //borrowApy
        //borrowApr
        //rewardApys
    }

    // getSwapCollateralSimulation

    // getReserveTotalSupplyAndBorrow

    // getReserveCaps
}