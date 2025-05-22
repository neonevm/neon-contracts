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
        bytes32 reserve, // ??? OPTIMIZE AND REMOVE THIS ???
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
            data = buildDepositReserveLiquidityData(amount);
        }
    }

    /// @notice Building instruction data for supplying collateral
    function buildDepositReserveLiquidityData(uint64 amount) internal pure returns (bytes memory) {
        require(amount > 0, LibKaminoErrors.InsufficientInputAmount());
        return abi.encodePacked(
            hex"a9c91e7e06cd6644", // [169, 201, 30, 126, 6, 205, 102, 68]
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
        bytes32 reserve, // ??? OPTIMIZE AND REMOVE THIS ???
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