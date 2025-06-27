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

    /// @notice Returns the user metadata PDA used for init obligation instruction
    /// @param user The instruction signer account
    function getUserMetadataPda(bytes32 user) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.getKaminoLendingProgramId(),
            abi.encodePacked(
                hex"757365725f6d657461", // "user_meta"
                user
            )
        );
    }

    /// @notice Returns the obligation account
    /// @param user The instruction signer account
    /// @param lendingMarket The lending market account
    /// @param obligationTypeTag ObligationTypeTag:
        /// Vanilla = 0
        /// Multiply = 1
        /// Lending = 2
        /// Leverage = 3
    /// @param obligationId uint8 ID
    /// @param seed1 bytes32 format seed
        /// Vanilla - bytes32(0)
        /// Multiply - collToken
        /// Lending - token ( equal to seed1 )
        /// Leverage - collToken
    /// @param seed2 bytes32 format seed
        /// Vanilla - bytes32(0)
        /// Multiply - debtToken
        /// Lending - token ( equal to seed2 )
        /// Leverage - debtToken
    function getObligationPda(
        bytes32 user,
        bytes32 lendingMarket,
        uint8 obligationTypeTag, 
        uint8 obligationId, 
        bytes32 seed1, 
        bytes32 seed2
    ) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.getKaminoLendingProgramId(),
            abi.encodePacked(
                obligationTypeTag,
                obligationId,
                user,
                lendingMarket,
                seed1,
                seed2
            )
        );
    }

    /// @notice Returns the Farms Accounts Obligation Farm User State
    /// @param farm The Farm Collateral account
    /// @param obligation The user's obligation account
    function obligationFarmStatePda(
        bytes32 farm,
        bytes32 obligation
    ) internal view returns(bytes32) {
        return CALL_SOLANA.getSolanaPDA(
            Constants.getKaminoFarmsProgramId(),
            abi.encodePacked(
                hex"75736572", // "user"
                farm,
                obligation
            )
        );
    }

    /// @notice Returns the Deposit Accounts Lending Market Authority account
    /// @param lendingMarket The lending market account
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

    /// @notice Returns the Deposit Accounts Reserve Liquidity Supply account
    /// @param lendingMarket The lending market account
    /// @param tokenMint The Mint account of the collateral
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

    /// @notice Returns the Deposit Accounts Reserve Collateral Mint account
    /// @param lendingMarket The lending market account
    /// @param tokenMint The Mint account of the collateral
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

    /// @notice Returns the reserve data. ( See struct ReserveData )
    /// @param reserve The reserve account
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

    /// @notice Returns the reserve liquidity data. ( See struct ReserveLiquidity )
    /// @param reserve The reserve account
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

    /// @notice Returns the reserve collateral data. ( See struct ReserveCollateral )
    /// @param reserve The reserve account
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

    /// @notice Returns the reserve config data. ( See struct ReserveConfig )
    /// @param reserve The reserve account
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

    // Kamino Farm data - JAvnB9AKtgPsTEoKmn24Bq64UMoYcrtWtq42HHBdsPkh
}