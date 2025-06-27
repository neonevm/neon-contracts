// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Constants} from "../Constants.sol";
import {ICallSolana} from "../../../precompiles/ICallSolana.sol";
import {LibAssociatedTokenData} from "../associated-token-program/LibAssociatedTokenData.sol";
import {LibKaminoData} from "./LibKaminoData.sol";
import {LibKaminoErrors} from "./LibKaminoErrors.sol";
import {LibSPLTokenData} from "../spl-token-program/LibSPLTokenData.sol";
import {LibSystemData} from "../system-program/LibSystemData.sol";
import {SolanaDataConverterLib} from "../../../utils/SolanaDataConverterLib.sol";


/// @title LibKamino
/// @author https://twitter.com/mnedelchev_
/// @notice Helper library for interactions with Solana's Kamino program
library LibKaminoProgram {
    using SolanaDataConverterLib for uint64;
    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    /// @notice Returns formatted Solana instruction of supplying collateral to Kamino
    /// @param tokenMint The Mint account of the collateral
    /// @param lendingMarket The account of the Kamino's lending market
    /// @param amount The amount of tokenMint to be supplied
    /// @param returnData Bool value defining whether the method should also build the instruction data
    /// @param premadeAccounts List of already calculated Solana accounts ( used for optimizations )
    function depositReserveLiquidityInstruction(
        bytes32 tokenMint,
        bytes32 reserve, // ??? CHECK IF THIS CAN BE DERIVED FROM lendingMarket by knowing the tokenMint ???
        bytes32 lendingMarket,
        uint64 amount,
        bool returnData,
        bytes32[] memory premadeAccounts
    ) internal view returns (
        bytes32[] memory accounts,
        bool[] memory isSigner,
        bool[] memory isWritable,
        bytes memory data
    ) {
        accounts = new bytes32[](12);
        if (premadeAccounts.length == 0) {
            premadeAccounts = new bytes32[](accounts.length);
        }
        accounts[0] = (premadeAccounts[0] != bytes32(0)) ? premadeAccounts[0] : CALL_SOLANA.getPayer();
        accounts[1] = reserve;
        accounts[2] = lendingMarket;
        accounts[3] = LibKaminoData.getLendingMarketAuthPda(lendingMarket);
        accounts[4] = tokenMint;
        accounts[5] = LibKaminoData.getReserveLiqSupplyPda(lendingMarket, tokenMint);
        accounts[6] = LibKaminoData.getReserveCollateralMintPda(lendingMarket, tokenMint);
        accounts[7] = (premadeAccounts[7] != bytes32(0)) ? premadeAccounts[7] : LibAssociatedTokenData.getAssociatedTokenAccount(tokenMint, accounts[0]);
        accounts[8] = (premadeAccounts[8] != bytes32(0)) ? premadeAccounts[8] : LibAssociatedTokenData.getAssociatedTokenAccount(accounts[6], accounts[0]);
        accounts[9] = LibSystemData.getOwner(accounts[6]);
        accounts[10] = LibSystemData.getOwner(tokenMint);
        accounts[11] = Constants.getSysvarRentPubkey();

        isSigner = new bool[](12);
        isSigner[0] = true;

        isWritable = new bool[](12);
        isWritable[0] = true;
        isWritable[1] = true;
        isWritable[4] = true;
        isWritable[5] = true;
        isWritable[6] = true;
        isWritable[7] = true;
        isWritable[8] = true;

        if (returnData) {
            data = buildDepositInstructionData(
                hex"a9c91e7e06cd6644", // [169, 201, 30, 126, 6, 205, 102, 68]
                amount
            );
        }
    }

    /// @notice Returns formatted Solana instruction of creating obligation. Obligations are needed in order to request loans.
    /// @param lendingMarket The account of the Kamino's lending market
    /// @param obligationTypeTag ObligationTypeTag:
        /// Vanilla = 0
        /// Multiply = 1
        /// Lending = 2
        /// Leverage = 3
    /// @param obligationId uint8 ID
    /// @param returnData Bool value defining whether the method should also build the instruction data
    /// @param premadeAccounts List of already calculated Solana accounts ( used for optimizations )
    function initObligationInstruction(
        bytes32 lendingMarket,
        uint8 obligationTypeTag,
        uint8 obligationId,
        bool returnData,
        bytes32[] memory premadeAccounts
    ) internal view returns (
        uint64 lamports,
        bytes32[] memory accounts,
        bool[] memory isSigner,
        bool[] memory isWritable,
        bytes memory data
    ) {
        accounts = new bytes32[](9);
        if (premadeAccounts.length == 0) {
            premadeAccounts = new bytes32[](accounts.length);
        }
        accounts[0] = (premadeAccounts[0] != bytes32(0)) ? premadeAccounts[0] : CALL_SOLANA.getPayer();
        accounts[1] = accounts[0];
        accounts[2] = LibKaminoData.getObligationPda(
            accounts[0], 
            lendingMarket, 
            obligationTypeTag, 
            obligationId, 
            Constants.getSystemProgramId(), 
            Constants.getSystemProgramId()
        );
        accounts[3] = lendingMarket;
        accounts[4] = Constants.getSystemProgramId();
        accounts[5] = Constants.getSystemProgramId();
        accounts[6] = LibKaminoData.getUserMetadataPda(accounts[0]);
        accounts[7] = Constants.getSysvarRentPubkey();
        accounts[8] = Constants.getSystemProgramId();

        isSigner = new bool[](9);
        isSigner[0] = true;
        isSigner[1] = true;

        isWritable = new bool[](9);
        isWritable[0] = true;
        isWritable[1] = true;
        isWritable[2] = true;

        /// @dev LibSystemData.getRentExemptionBalance(3472, rentDataBytes) - lamports needed for obligation account creation:
            /// 3344 bytes for the obligation's account
            /// 1x 128 bytes ACCOUNT_STORAGE_OVERHEAD
        lamports = LibSystemData.getRentExemptionBalance(
            3472,
            LibSystemData.getSystemAccountData(
                Constants.getSysvarRentPubkey(),
                LibSystemData.getSpace(Constants.getSysvarRentPubkey())
            )
        );
        
        if (returnData) {
            data = buildInitObligationData(obligationTypeTag, obligationId);
        }
    }

    function buildInitObligationData(uint8 tag, uint8 id) internal pure returns (bytes memory) {
        return abi.encodePacked(
            hex"fb0ae74c1b0b9f60", // [251, 10, 231, 76, 27, 11, 159, 96]
            tag,
            id
        );
    }

    // initObligationFarmsForReserve
    // https://github.com/Kamino-Finance/klend-sdk/blob/672239f9c06ff492ecc22ab0d89d5ea4f02a0bfb/src/idl_codegen/instructions/initObligationFarmsForReserve.ts#L27

    /// @notice Returns formatted Solana instruction of supplying collateral to Kamino which could be used into obligation in order to take loans.
    /// @notice Before this instruction there has to be obligation created through method initObligationInstruction
    /// @param tokenMint The Mint account of the collateral
    /// @param lendingMarket The account of the Kamino's lending market
    /// @param obligation The account of the user's obligation for this lendingMarket
    /// @param amount The amount of tokenMint to be supplied
    /// @param returnData Bool value defining whether the method should also build the instruction data
    /// @param premadeAccounts List of already calculated Solana accounts ( used for optimizations )
    function depositReserveLiquidityAndObligationCollateralV2Instruction(
        bytes32 tokenMint,
        bytes32 reserve, // ??? CHECK IF THIS CAN BE DERIVED FROM lendingMarket by knowing the tokenMint ???
        bytes32 lendingMarket,
        bytes32 obligation,
        uint64 amount,
        bool returnData,
        bytes32[] memory premadeAccounts
    ) internal view returns (
        bytes32[] memory accounts,
        bool[] memory isSigner,
        bool[] memory isWritable,
        bytes memory data
    ) {
        LibKaminoData.ReserveData memory reserveData = LibKaminoData.getReserveData(reserve);

        accounts = new bytes32[](17);
        if (premadeAccounts.length == 0) {
            premadeAccounts = new bytes32[](accounts.length);
        }
        accounts[0] = (premadeAccounts[0] != bytes32(0)) ? premadeAccounts[0] : CALL_SOLANA.getPayer();
        accounts[1] = obligation;
        accounts[2] = lendingMarket;
        accounts[3] = LibKaminoData.getLendingMarketAuthPda(lendingMarket);
        accounts[4] = reserve;
        accounts[5] = tokenMint;
        accounts[6] = LibKaminoData.getReserveLiqSupplyPda(lendingMarket, tokenMint);
        accounts[7] = LibKaminoData.getReserveCollateralMintPda(lendingMarket, tokenMint);
        accounts[8] = (premadeAccounts[8] != bytes32(0)) ? premadeAccounts[8] : LibAssociatedTokenData.getAssociatedTokenAccount(accounts[7], accounts[3]);
        accounts[9] = (premadeAccounts[9] != bytes32(0)) ? premadeAccounts[9] : LibAssociatedTokenData.getAssociatedTokenAccount(tokenMint, accounts[0]);
        accounts[10] = Constants.getKaminoLendingProgramId();
        accounts[11] = LibSystemData.getOwner(accounts[6]);
        accounts[12] = LibSystemData.getOwner(tokenMint);
        accounts[13] = Constants.getSysvarRentPubkey();
        accounts[14] = LibKaminoData.obligationFarmStatePda(reserveData.farmCollateral, obligation);
        accounts[15] = reserveData.farmCollateral;
        accounts[16] = Constants.getKaminoFarmsProgramId();

        isSigner = new bool[](17);
        isSigner[0] = true;

        isWritable = new bool[](17);
        isWritable[0] = true;
        isWritable[1] = true;
        isWritable[4] = true;
        isWritable[6] = true;
        isWritable[7] = true;
        isWritable[8] = true;
        isWritable[9] = true;
        isWritable[14] = true;
        isWritable[15] = true;

        if (returnData) {
            data = buildDepositInstructionData(
                hex"d8e0bf1bcc9766af", // [216, 224, 191, 27, 204, 151, 102, 175]
                amount
            );
        }
    }

    /// @notice Building instruction data for supplying collateral
    function buildDepositInstructionData(bytes memory instructionPrefix, uint64 amount) internal pure returns (bytes memory) {
        require(amount > 0, LibKaminoErrors.InsufficientInputAmount());
        return abi.encodePacked(
            instructionPrefix,
            amount.readLittleEndianUnsigned64()
        );
    }

    /// @notice Returns formatted Solana instruction of withdrawing collateral from Kamino
    /// @param tokenMint The Mint account of the collateral
    /// @param lendingMarket The account of the Kamino's lending market
    /// @param amount The amount of tokenMint to be supplied
    /// @param returnData Bool value defining whether the method should also build the instruction data
    /// @param premadeAccounts List of already calculated Solana accounts ( used for optimizations )
    function redeemReserveCollateralInstruction(
        bytes32 tokenMint,
        bytes32 reserve, // ??? CHECK IF THIS CAN BE DERIVED FROM lendingMarket by knowing the tokenMint ???
        bytes32 lendingMarket,
        uint64 amount,
        bool returnData,
        bytes32[] memory premadeAccounts
    ) internal view returns (
        bytes32[] memory accounts,
        bool[] memory isSigner,
        bool[] memory isWritable,
        bytes memory data
    ) {
        accounts = new bytes32[](12);
        if (premadeAccounts.length == 0) {
            premadeAccounts = new bytes32[](accounts.length);
        }
        accounts[0] = (premadeAccounts[0] != bytes32(0)) ? premadeAccounts[0] : CALL_SOLANA.getPayer();
        accounts[1] = lendingMarket;
        accounts[2] = reserve;
        accounts[3] = LibKaminoData.getLendingMarketAuthPda(lendingMarket);
        accounts[4] = tokenMint;
        accounts[5] = LibKaminoData.getReserveCollateralMintPda(lendingMarket, tokenMint);
        accounts[6] = LibKaminoData.getReserveLiqSupplyPda(lendingMarket, tokenMint);
        accounts[7] = (premadeAccounts[7] != bytes32(0)) ? premadeAccounts[7] : LibAssociatedTokenData.getAssociatedTokenAccount(accounts[5], accounts[0]);
        accounts[8] = (premadeAccounts[8] != bytes32(0)) ? premadeAccounts[8] : LibAssociatedTokenData.getAssociatedTokenAccount(tokenMint, accounts[0]);
        accounts[9] = LibSystemData.getOwner(accounts[5]);
        accounts[10] = LibSystemData.getOwner(tokenMint);
        accounts[11] = Constants.getSysvarRentPubkey();

        isSigner = new bool[](12);
        isSigner[0] = true;

        isWritable = new bool[](12);
        isWritable[0] = true;
        isWritable[2] = true;
        isWritable[4] = true;
        isWritable[5] = true;
        isWritable[6] = true;
        isWritable[7] = true;
        isWritable[8] = true;

        if (returnData) {
            data = buildRedeemReserveCollateralData(amount);
        }
    }

    /// @notice Building instruction data for withdrawing collateral
    function buildRedeemReserveCollateralData(uint64 amount) internal pure returns (bytes memory) {
        require(amount > 0, LibKaminoErrors.InsufficientInputAmount());
        return abi.encodePacked(
            hex"ea75b57db98edc1d", // [234, 117, 181, 125, 185, 142, 220, 29]
            amount.readLittleEndianUnsigned64()
        );
    }
}