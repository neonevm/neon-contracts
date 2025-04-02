// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Constants} from "../Constants.sol";
import {ICallSolana} from "../../../precompiles/ICallSolana.sol";
import {LibRaydiumData} from "./LibRaydiumData.sol";
import {LibRaydiumErrors} from "./LibRaydiumErrors.sol";
import {LibSPLTokenData} from "../spl-token-program/LibSPLTokenData.sol";
import {LibSystemData} from "../system-program/LibSystemData.sol";
import {SolanaDataConverterLib} from "../../../utils/SolanaDataConverterLib.sol";


/// @title LibRaydium
/// @author https://twitter.com/mnedelchev_
/// @notice This library serve as a helper to abstract away Solana's specifications for Solidity developers
library LibRaydium {
    using SolanaDataConverterLib for uint64;
    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    /// @notice Creation of a CPMM pool in Raydium
    /// @param tokenA The Mint account of tokenA
    /// @param tokenB The Mint account of tokenB
    /// @param mintAAmount The tokenA's amount provided as initial liquidity inside the pool
    /// @param mintBAmount The tokenB's amount provided as initial liquidity inside the pool
    /// @param startTime The pool's start time
    /// @param configIndex The index of the config account to be used for the pool creation
    /// @param returnData Bool value defining whether the method should also build the instruction data
    /// @param premadeAccounts List of already calculated Solana accounts ( used for optimizations )
    function createPool(
        bytes32 tokenA,
        bytes32 tokenB,
        uint64 mintAAmount,
        uint64 mintBAmount,
        uint64 startTime,
        uint16 configIndex,
        bool returnData,
        bytes32[] memory premadeAccounts
    ) internal view returns (
        uint64 lamports,
        bytes32[] memory accounts,
        bool[] memory isSigner,
        bool[] memory isWritable,
        bytes memory data
    ) {
        // set chai id
        require(tokenA != tokenB, LibRaydiumErrors.IdenticalTokenAddresses());
        require(tokenA != bytes32(0) && tokenB != bytes32(0), LibRaydiumErrors.EmptyTokenAddress());
        bytes32 configAccount = LibRaydiumData.getConfigAccount(configIndex);
        bytes32 poolId = LibRaydiumData.getCpmmPdaPoolId(configAccount, tokenA, tokenB);
        require(LibSystemData.getSpace(poolId) == 0, LibRaydiumErrors.AlreadyExistingPool(poolId));

        accounts = new bytes32[](20);
        if (premadeAccounts.length == 0) {
            premadeAccounts = new bytes32[](accounts.length);
        }
        accounts[0] = (premadeAccounts[0] != bytes32(0)) ? premadeAccounts[0] : CALL_SOLANA.getPayer();
        accounts[1] = configAccount;
        accounts[2] = LibRaydiumData.getPdaPoolAuthority();
        accounts[3] = poolId;
        accounts[4] = tokenA;
        accounts[5] = tokenB;
        accounts[6] = LibRaydiumData.getPdaLpMint(accounts[3]);
        accounts[7] = (premadeAccounts[7] != bytes32(0)) ? premadeAccounts[7] : LibSPLTokenData.getAssociatedTokenAccount(tokenA, accounts[0]);
        accounts[8] = (premadeAccounts[8] != bytes32(0)) ? premadeAccounts[8] : LibSPLTokenData.getAssociatedTokenAccount(tokenB, accounts[0]);
        accounts[9] = (premadeAccounts[9] != bytes32(0)) ? premadeAccounts[9] : LibSPLTokenData.getAssociatedTokenAccount(accounts[6], accounts[0]);
        accounts[10] = LibRaydiumData.getPdaVault(accounts[3], tokenA);
        accounts[11] = LibRaydiumData.getPdaVault(accounts[3], tokenB);
        accounts[12] = Constants.getCreateCPMMPoolFeeAccPubkey();
        accounts[13] = LibRaydiumData.getPdaObservationId(accounts[3]);
        accounts[14] = Constants.getTokenProgramId();
        accounts[15] = LibSystemData.getOwner(tokenA);
        accounts[16] = LibSystemData.getOwner(tokenB);
        accounts[17] = Constants.getAssociatedTokenProgramId();
        accounts[18] = Constants.getSystemProgramId();
        accounts[19] = Constants.getSysvarRentPubkey();

        isSigner = new bool[](20);
        isSigner[0] = true;
        for (uint i = 1; i < isSigner.length - 1; ++i) {
            isSigner[i] = false;
        }

        isWritable = new bool[](20);
        isWritable[0] = true;
        isWritable[1] = false;
        isWritable[2] = false;
        isWritable[3] = true;
        isWritable[4] = false;
        isWritable[5] = false;
        isWritable[6] = true;
        isWritable[7] = true;
        isWritable[8] = true;
        isWritable[9] = true;
        isWritable[10] = true;
        isWritable[11] = true;
        isWritable[12] = true;
        isWritable[13] = true;
        isWritable[14] = false;
        isWritable[15] = false;
        isWritable[16] = false;
        isWritable[17] = false;
        isWritable[18] = false;
        isWritable[19] = false;

        LibRaydiumData.ConfigData memory configData = LibRaydiumData.getConfigData(accounts[1]);
        lamports = configData.createPoolFee + 42156720; // CPMM's pool creation fee plus lamports needed for all the accounts creations

        if (returnData) {
            data = buildCreatePoolData(
                mintAAmount,
                mintBAmount,
                startTime
            );
        }
    }

    /// @notice Building instruction data for creation of a pool
    function buildCreatePoolData(uint64 amountMaxA, uint64 amountMaxB, uint64 startTime) internal pure returns (bytes memory) {
        require(amountMaxA > 0 && amountMaxB > 0, LibRaydiumErrors.InsufficientInputAmount());
        return abi.encodePacked(
            hex"afaf6d1f0d989bed", // initialize: [175, 175, 109, 31, 13, 152, 155, 237]
            abi.encodePacked(
                amountMaxA.readLittleEndianUnsigned64(),
                amountMaxB.readLittleEndianUnsigned64(),
                startTime.readLittleEndianUnsigned64()
            )
        );
    }

    /// @notice Adding LP to CPMM pool in Raydium
    /// @param poolId The pool's account
    /// @param inputAmount The amount of LP to be added
    /// @param baseIn Bool that defines whether tokenA or tokenB should be used for the LP amount calculcation
    /// @param slippage Percent value from 0 to 100
    /// @param returnData Bool value defining whether the method should also build the instruction data
    /// @param premadeAccounts List of already calculated Solana accounts ( used for optimizations )
    function addLiquidity(
        bytes32 poolId,
        uint64 inputAmount,
        bool baseIn,
        uint8 slippage,
        bool returnData,
        bytes32[] memory premadeAccounts
    ) internal view returns (
        uint64 lamports,
        bytes32[] memory accounts,
        bool[] memory isSigner,
        bool[] memory isWritable,
        bytes memory data
    ) {
        LibRaydiumData.PoolData memory poolData = LibRaydiumData.getPoolData(poolId);

        accounts = new bytes32[](13);
        if (premadeAccounts.length == 0) {
            premadeAccounts = new bytes32[](accounts.length);
        }

        accounts[0] = (premadeAccounts[0] != bytes32(0)) ? premadeAccounts[0] : CALL_SOLANA.getPayer();
        accounts[1] = (premadeAccounts[1] != bytes32(0)) ? premadeAccounts[1] : LibRaydiumData.getPdaPoolAuthority();
        accounts[2] = poolId;
        accounts[3] = (premadeAccounts[3] != bytes32(0)) ? premadeAccounts[3] : LibSPLTokenData.getAssociatedTokenAccount(poolData.lpMint, accounts[0]);
        accounts[4] = (premadeAccounts[4] != bytes32(0)) ? premadeAccounts[4] : LibSPLTokenData.getAssociatedTokenAccount(poolData.tokenA, accounts[0]);
        accounts[5] = (premadeAccounts[5] != bytes32(0)) ? premadeAccounts[5] : LibSPLTokenData.getAssociatedTokenAccount(poolData.tokenB, accounts[0]);
        accounts[6] = poolData.tokenAVault;
        accounts[7] = poolData.tokenBVault;
        accounts[8] = Constants.getTokenProgramId();
        accounts[9] = Constants.getTokenProgram2022Id();
        accounts[10] = poolData.tokenA;
        accounts[11] = poolData.tokenB;
        accounts[12] = poolData.lpMint;

        isSigner = new bool[](13);
        isSigner[0] = true;
        for (uint i = 1; i < isSigner.length - 1; ++i) {
            isSigner[i] = false;
        }

        isWritable = new bool[](13);
        isWritable[0] = true;
        isWritable[1] = false;
        isWritable[2] = true;
        isWritable[3] = true;
        isWritable[4] = true;
        isWritable[5] = true;
        isWritable[6] = true;
        isWritable[7] = true;
        isWritable[8] = false;
        isWritable[9] = false;
        isWritable[10] = false;
        isWritable[11] = false;
        isWritable[12] = true;

        if (returnData) {
            uint64 tokenAReserve = LibRaydiumData.getTokenReserve(poolId, poolData.tokenA);
            uint64 tokenBReserve = LibRaydiumData.getTokenReserve(poolId, poolData.tokenB);
            uint64 poolLpAmount = LibRaydiumData.getPoolLpAmount(poolId);
            uint64 lpAmount = (inputAmount * poolLpAmount) / ((baseIn) ? tokenAReserve : tokenBReserve);
            (uint64 amountA, uint64 amountB) = LibRaydiumData.lpToAmount(
                lpAmount,
                tokenAReserve, 
                tokenBReserve,
                poolLpAmount
            );
            slippage = (slippage > 100) ? 100 : slippage;
            
            data = buildAddLiquidityData(
                lpAmount, 
                (((baseIn) ? inputAmount : amountA) * (100 + slippage)) / 100,
                (((baseIn) ? amountB : inputAmount) * (100 + slippage)) / 100
            );
        }
    }

    /// @notice Building instruction data for adding LP to a pool
    function buildAddLiquidityData(uint64 lpAmount, uint64 amountMaxA, uint64 amountMaxB) internal pure returns (bytes memory) {
        require(lpAmount > 0, LibRaydiumErrors.InsufficientInputAmount());
        return abi.encodePacked(
            hex"f223c68952e1f2b6", // deposit: [242, 35, 198, 137, 82, 225, 242, 182]
            abi.encodePacked(
                lpAmount.readLittleEndianUnsigned64(),
                amountMaxA.readLittleEndianUnsigned64(),
                amountMaxB.readLittleEndianUnsigned64()
            )
        );
    }

    /// @notice Withdrawing LP from CPMM pool in Raydium
    /// @param poolId The pool's account
    /// @param lpAmount The amount of LP to be withdrawn
    /// @param slippage Percent value from 0 to 100
    /// @param returnData Bool value defining whether the method should also build the instruction data
    /// @param premadeAccounts List of already calculated Solana accounts ( used for optimizations )
    function withdrawLiquidity(
        bytes32 poolId,
        uint64 lpAmount,
        uint8 slippage,
        bool returnData,
        bytes32[] memory premadeAccounts
    ) internal view returns (
        uint64 lamports,
        bytes32[] memory accounts,
        bool[] memory isSigner,
        bool[] memory isWritable,
        bytes memory data
    ) {
        LibRaydiumData.PoolData memory poolData = LibRaydiumData.getPoolData(poolId);

        accounts = new bytes32[](14);
        if (premadeAccounts.length == 0) {
            premadeAccounts = new bytes32[](accounts.length);
        }
        accounts[0] = (premadeAccounts[0] != bytes32(0)) ? premadeAccounts[0] : CALL_SOLANA.getPayer();
        accounts[1] = (premadeAccounts[1] != bytes32(0)) ? premadeAccounts[1] : LibRaydiumData.getPdaPoolAuthority();
        accounts[2] = poolId;
        accounts[3] = (premadeAccounts[3] != bytes32(0)) ? premadeAccounts[3] : LibSPLTokenData.getAssociatedTokenAccount(poolData.lpMint, accounts[0]);
        accounts[4] = (premadeAccounts[4] != bytes32(0)) ? premadeAccounts[4] : LibSPLTokenData.getAssociatedTokenAccount(poolData.tokenA, accounts[0]);
        accounts[5] = (premadeAccounts[5] != bytes32(0)) ? premadeAccounts[5] : LibSPLTokenData.getAssociatedTokenAccount(poolData.tokenB, accounts[0]);
        accounts[6] = poolData.tokenAVault;
        accounts[7] = poolData.tokenBVault;
        accounts[8] = Constants.getTokenProgramId();
        accounts[9] = Constants.getTokenProgram2022Id();
        accounts[10] = poolData.tokenA;
        accounts[11] = poolData.tokenB;
        accounts[12] = poolData.lpMint;
        accounts[13] = Constants.getMemoProgramId();

        isSigner = new bool[](14);
        isSigner[0] = true;
        for (uint i = 1; i < isSigner.length - 1; ++i) {
            isSigner[i] = false;
        }

        isWritable = new bool[](14);
        isWritable[0] = true;
        isWritable[1] = false;
        isWritable[2] = true;
        isWritable[3] = true;
        isWritable[4] = true;
        isWritable[5] = true;
        isWritable[6] = true;
        isWritable[7] = true;
        isWritable[8] = false;
        isWritable[9] = false;
        isWritable[10] = false;
        isWritable[11] = false;
        isWritable[12] = true;
        isWritable[13] = true;

        if (returnData) {
            uint64 poolLpAmount = LibRaydiumData.getPoolLpAmount(poolId);
            slippage = (slippage > 100) ? 100 : slippage;
            data = buildWithdrawLiquidityData(
                lpAmount, 
                (((lpAmount * LibRaydiumData.getTokenReserve(poolId, poolData.tokenA)) / poolLpAmount) * (100 - slippage)) / 100, 
                (((lpAmount * LibRaydiumData.getTokenReserve(poolId, poolData.tokenB)) / poolLpAmount) * (100 - slippage)) / 100
            );
        }
    }

    /// @notice Building instruction data for withdrawing LP from a pool
    function buildWithdrawLiquidityData(uint64 lpAmount, uint64 amountMinA, uint64 amountMinB) internal pure returns (bytes memory) {
        require(lpAmount > 0, LibRaydiumErrors.InsufficientInputAmount());
        return abi.encodePacked(
            hex"b712469c946da122", // withdraw: [183, 18, 70, 156, 148, 109, 161, 34],
            abi.encodePacked(
                lpAmount.readLittleEndianUnsigned64(),
                amountMinA.readLittleEndianUnsigned64(),
                amountMinB.readLittleEndianUnsigned64()
            )
        );
    }

    /// @notice Locking LP in CPMM pool in Raydium
    /// @param poolId The pool's account
    /// @param lpAmount The amount of LP to be locked
    /// @param withMetadata Bool value whether metadata should be included or not
    /// @param salt bytes32 value used for the calculation of the external authority ( the nft owner )
    /// @param returnData Bool value defining whether the method should also build the instruction data
    /// @param premadeAccounts List of already calculated Solana accounts ( used for optimizations )
    function lockLiquidity(
        bytes32 poolId,
        uint64 lpAmount,
        bool withMetadata,
        bytes32 salt,
        bool returnData,
        bytes32[] memory premadeAccounts
    ) internal view returns (
        uint64 lamports,
        bytes32[] memory accounts,
        bool[] memory isSigner,
        bool[] memory isWritable,
        bytes memory data
    ) {
        accounts = new bytes32[](19);
        if (premadeAccounts.length == 0) {
            premadeAccounts = new bytes32[](accounts.length);
        }

        LibRaydiumData.PoolData memory poolData;
        if (LibSystemData.getSpace(poolId) != 0 && (premadeAccounts[8] == bytes32(0) || premadeAccounts[11] == bytes32(0) || premadeAccounts[12] == bytes32(0))) {
            poolData = LibRaydiumData.getPoolData(poolId);
        }
        lamports = 23328400;

        accounts[0] = Constants.getLockCPMMPoolAuthPubkey();
        accounts[1] = (premadeAccounts[1] != bytes32(0)) ? premadeAccounts[1] : CALL_SOLANA.getPayer();
        accounts[2] = accounts[1];
        accounts[3] = accounts[1];
        accounts[4] = (premadeAccounts[4] != bytes32(0)) ? premadeAccounts[4] : CALL_SOLANA.getExtAuthority(salt);
        accounts[5] = (premadeAccounts[5] != bytes32(0)) ? premadeAccounts[5] : LibSPLTokenData.getAssociatedTokenAccount(accounts[4], accounts[1]);
        accounts[6] = poolId;
        accounts[7] = (premadeAccounts[7] != bytes32(0)) ? premadeAccounts[7] : LibRaydiumData.getCpLockPda(accounts[4]);
        accounts[8] = (premadeAccounts[8] != bytes32(0)) ? premadeAccounts[8] : poolData.lpMint;
        accounts[9] = (premadeAccounts[9] != bytes32(0)) ? premadeAccounts[9] : LibSPLTokenData.getAssociatedTokenAccount(accounts[8], accounts[1]);
        accounts[10] = (premadeAccounts[10] != bytes32(0)) ? premadeAccounts[10] : LibSPLTokenData.getAssociatedTokenAccount(accounts[8], accounts[0]);
        accounts[11] = (premadeAccounts[11] != bytes32(0)) ? premadeAccounts[11] : poolData.tokenAVault;
        accounts[12] = (premadeAccounts[12] != bytes32(0)) ? premadeAccounts[12] : poolData.tokenBVault;
        accounts[13] = (premadeAccounts[13] != bytes32(0)) ? premadeAccounts[13] : LibRaydiumData.getPdaMetadataKey(accounts[4]);
        accounts[14] = Constants.getSysvarRentPubkey();
        accounts[15] = Constants.getSystemProgramId();
        accounts[16] = Constants.getTokenProgramId();
        accounts[17] = Constants.getAssociatedTokenProgramId();
        accounts[18] = Constants.getMetaplexProgramId();

        isSigner = new bool[](19);
        isSigner[0] = false;
        isSigner[1] = true;
        isSigner[2] = true;
        isSigner[3] = true;
        isSigner[4] = true;
        isSigner[5] = false;
        isSigner[6] = false;
        isSigner[7] = false;
        isSigner[8] = false;
        isSigner[9] = false;
        isSigner[10] = false;
        isSigner[11] = false;
        isSigner[12] = false;
        isSigner[13] = false;
        isSigner[14] = false;
        isSigner[15] = false;
        isSigner[16] = false;
        isSigner[17] = false;
        isSigner[18] = false;

        isWritable = new bool[](19);
        isWritable[0] = false;
        isWritable[1] = true;
        isWritable[2] = true;
        isWritable[3] = true;
        isWritable[4] = true;
        isWritable[5] = true;
        isWritable[6] = false;
        isWritable[7] = true;
        isWritable[8] = false;
        isWritable[9] = true;
        isWritable[10] = true;
        isWritable[11] = true;
        isWritable[12] = true;
        isWritable[13] = true;
        isWritable[14] = false;
        isWritable[15] = false;
        isWritable[16] = false;
        isWritable[17] = false;
        isWritable[18] = false;

        if (returnData) {
            data = buildLockLiquidityData(lpAmount, withMetadata);
        }
    }

    /// @notice Building instruction data for locking LP in a pool
    function buildLockLiquidityData(uint64 lpAmount, bool withMetadata) internal pure returns (bytes memory) {
        require(lpAmount > 0, LibRaydiumErrors.InsufficientInputAmount());
        return abi.encodePacked(
            hex"d89d1d4e26331f1a", // lockCpLiquidity: [216, 157, 29, 78, 38, 51, 31, 26]
            abi.encodePacked(
                lpAmount.readLittleEndianUnsigned64(),
                withMetadata
            )
        );
    }

    /// @notice Collecting fees from locked LP position in CPMM pool in Raydium
    /// @param poolId The pool's account
    /// @param lpFeeAmount The amount of fees to be collected
    /// @param salt bytes32 value used for the calculation of the external authority ( the nft owner )
    /// @param returnData Bool value defining whether the method should also build the instruction data
    /// @param premadeAccounts List of already calculated Solana accounts ( used for optimizations )
    function collectFees(
        bytes32 poolId,
        uint64 lpFeeAmount,
        bytes32 salt,
        bool returnData,
        bytes32[] memory premadeAccounts
    ) internal view returns (
        uint64 lamports,
        bytes32[] memory accounts,
        bool[] memory isSigner,
        bool[] memory isWritable,
        bytes memory data
    ) {
        LibRaydiumData.PoolData memory poolData = LibRaydiumData.getPoolData(poolId);
        bytes32 nftMintAccount = CALL_SOLANA.getExtAuthority(salt);

        accounts = new bytes32[](18);
        if (premadeAccounts.length == 0) {
            premadeAccounts = new bytes32[](accounts.length);
        }
        accounts[0] = Constants.getLockCPMMPoolAuthPubkey();
        accounts[1] = (premadeAccounts[1] != bytes32(0)) ? premadeAccounts[1] : CALL_SOLANA.getPayer();
        accounts[2] = (premadeAccounts[2] != bytes32(0)) ? premadeAccounts[2] : LibSPLTokenData.getAssociatedTokenAccount(nftMintAccount, accounts[1]);
        accounts[3] = (premadeAccounts[3] != bytes32(0)) ? premadeAccounts[3] : LibRaydiumData.getCpLockPda(nftMintAccount);
        accounts[4] = Constants.getCreateCPMMPoolProgramId();
        accounts[5] = Constants.getCreateCPMMPoolAuth();
        accounts[6] = poolId;
        accounts[7] = poolData.lpMint;
        accounts[8] = (premadeAccounts[8] != bytes32(0)) ? premadeAccounts[8] : LibSPLTokenData.getAssociatedTokenAccount(poolData.tokenA, accounts[1]);
        accounts[9] = (premadeAccounts[9] != bytes32(0)) ? premadeAccounts[9] : LibSPLTokenData.getAssociatedTokenAccount(poolData.tokenB, accounts[1]);
        accounts[10] = poolData.tokenAVault;
        accounts[11] = poolData.tokenBVault;
        accounts[12] = poolData.tokenA;
        accounts[13] = poolData.tokenB;
        accounts[14] = (premadeAccounts[14] != bytes32(0)) ? premadeAccounts[14] : LibSPLTokenData.getAssociatedTokenAccount(accounts[7], accounts[0]);
        accounts[15] = Constants.getTokenProgramId();
        accounts[16] = Constants.getTokenProgram2022Id();
        accounts[17] = Constants.getMemoProgramId();

        isSigner = new bool[](18);
        isSigner[0] = false;
        isSigner[1] = true;
        isSigner[2] = false;
        isSigner[3] = false;
        isSigner[4] = false;
        isSigner[5] = false;
        isSigner[6] = false;
        isSigner[7] = false;
        isSigner[8] = false;
        isSigner[9] = false;
        isSigner[10] = false;
        isSigner[11] = false;
        isSigner[12] = false;
        isSigner[13] = false;
        isSigner[14] = false;
        isSigner[15] = false;
        isSigner[16] = false;
        isSigner[17] = false;

        isWritable = new bool[](18);
        isWritable[0] = false;
        isWritable[1] = false;
        isWritable[2] = true;
        isWritable[3] = true;
        isWritable[4] = false;
        isWritable[5] = false;
        isWritable[6] = true;
        isWritable[7] = true;
        isWritable[8] = true;
        isWritable[9] = true;
        isWritable[10] = true;
        isWritable[11] = true;
        isWritable[12] = false;
        isWritable[13] = false;
        isWritable[14] = true;
        isWritable[15] = false;
        isWritable[16] = false;
        isWritable[17] = false;

        if (returnData) {
            data = buildCollectFeesData(lpFeeAmount);
        }
    }

    /// @notice Building instruction data for collecting fees from locked LP position
    function buildCollectFeesData(uint64 lpFeeAmount) internal pure returns (bytes memory) {
        require(lpFeeAmount > 0, LibRaydiumErrors.InsufficientInputAmount());
        return abi.encodePacked(
            hex"081e33c7d1b8f785", // collectCpFee: [8, 30, 51, 199, 209, 184, 247, 133]
            abi.encodePacked(
                lpFeeAmount.readLittleEndianUnsigned64()
            )
        );
    }

    /// @notice Swap input to CPMM pool in Raydium
    /// @param poolId The pool's account
    /// @param inputToken The token mint account of the input token
    /// @param amountIn The amount of the input token to be swapped
    /// @param slippage Percent value from 0 to 100
    /// @param returnData Bool value defining whether the method should also build the instruction data
    /// @param premadeAccounts List of already calculated Solana accounts ( used for optimizations )
    function swapInput(
        bytes32 poolId,
        bytes32 inputToken,
        uint64 amountIn,
        uint8 slippage,
        bool returnData,
        bytes32[] memory premadeAccounts
    ) internal view returns (
        uint64 lamports,
        bytes32[] memory accounts,
        bool[] memory isSigner,
        bool[] memory isWritable,
        bytes memory data
    ) {
        LibRaydiumData.PoolData memory poolData = LibRaydiumData.getPoolData(poolId);
        bytes32 outputToken = (inputToken == poolData.tokenA) ? poolData.tokenB : poolData.tokenA;
        (
            accounts,
            isSigner,
            isWritable
        ) = _swap(poolId, inputToken, outputToken, poolData, premadeAccounts);

        if (returnData) {
            uint64 amounOutMin = LibRaydiumData.getSwapOutput(poolId, poolData.ammConfig, inputToken, outputToken, amountIn);
            slippage = (slippage > 100) ? 100 : slippage;
            amounOutMin = (slippage != 0) ? (amounOutMin * (100 - slippage)) / 100 : amounOutMin;
            data = buildSwapInputData(amountIn, amounOutMin);
        }
    }

    /// @notice Building instruction data for swap input action
    function buildSwapInputData(uint64 amountIn, uint64 amounOutMin) internal pure returns (bytes memory) {
        require(amountIn > 0, LibRaydiumErrors.InsufficientInputAmount());
        return abi.encodePacked(
            hex"8fbe5adac41e33de", // swapBaseInput: [143, 190, 90, 218, 196, 30, 51, 222]
            abi.encodePacked(
                amountIn.readLittleEndianUnsigned64(),
                amounOutMin.readLittleEndianUnsigned64()
            )
        );
    }

    /// @notice Swap output to CPMM pool in Raydium
    /// @param poolId The pool's account
    /// @param inputToken The token mint account of the input token
    /// @param amountOut The amount of the output token to be received
    /// @param slippage Percent value from 0 to 100
    /// @param returnData Bool value defining whether the method should also build the instruction data
    /// @param premadeAccounts List of already calculated Solana accounts ( used for optimizations )
    function swapOutput(
        bytes32 poolId,
        bytes32 inputToken,
        uint64 amountOut,
        uint8 slippage,
        bool returnData,
        bytes32[] memory premadeAccounts
    ) internal view returns (
        uint64 lamports,
        bytes32[] memory accounts,
        bool[] memory isSigner,
        bool[] memory isWritable,
        bytes memory data
    ) {
        LibRaydiumData.PoolData memory poolData = LibRaydiumData.getPoolData(poolId);
        bytes32 outputToken = (inputToken == poolData.tokenA) ? poolData.tokenB : poolData.tokenA;
        (
            accounts,
            isSigner,
            isWritable
        ) = _swap(poolId, inputToken, outputToken, poolData, premadeAccounts);

        if (returnData) {
            uint64 amountInMax = LibRaydiumData.getSwapInput(poolId, poolData.ammConfig, inputToken, outputToken, amountOut);
            slippage = (slippage > 100) ? 100 : slippage;
            amountInMax = (slippage != 0) ? (amountInMax * (100 + slippage)) / 100 : amountInMax;
            data = buildSwapOutputData(amountInMax, amountOut);
        }
    }

    /// @notice Building instruction data for swap output action
    function buildSwapOutputData(uint64 amountInMax, uint64 amountOut) internal pure returns (bytes memory) {
        require(amountOut > 0, LibRaydiumErrors.InsufficientOutputAmount());
        return abi.encodePacked(
            hex"37d96256a34ab4ad", // swapBaseOutput: [55, 217, 98, 86, 163, 74, 180, 173]
            abi.encodePacked(
                amountInMax.readLittleEndianUnsigned64(),
                amountOut.readLittleEndianUnsigned64()
            )
        );
    }

    function _swap(
        bytes32 poolId,
        bytes32 inputToken,
        bytes32 outputToken,
        LibRaydiumData.PoolData memory poolData,
        bytes32[] memory premadeAccounts
    ) private view returns(
        bytes32[] memory accounts,
        bool[] memory isSigner,
        bool[] memory isWritable
    ) {
        accounts = new bytes32[](13);
        if (premadeAccounts.length == 0) {
            premadeAccounts = new bytes32[](accounts.length);
        }
        accounts[0] = (premadeAccounts[0] != bytes32(0)) ? premadeAccounts[0] : CALL_SOLANA.getPayer();
        accounts[1] = (premadeAccounts[1] != bytes32(0)) ? premadeAccounts[1] : LibRaydiumData.getPdaPoolAuthority();
        accounts[2] = poolData.ammConfig;
        accounts[3] = poolId;
        accounts[4] = (premadeAccounts[4] != bytes32(0)) ? premadeAccounts[4] : LibSPLTokenData.getAssociatedTokenAccount(inputToken, accounts[0]);
        accounts[5] = (premadeAccounts[5] != bytes32(0)) ? premadeAccounts[5] : LibSPLTokenData.getAssociatedTokenAccount(outputToken, accounts[0]);
        accounts[6] = (inputToken == poolData.tokenA) ? poolData.tokenAVault : poolData.tokenBVault;
        accounts[7] = (inputToken == poolData.tokenA) ? poolData.tokenBVault : poolData.tokenAVault;
        accounts[8] = (inputToken == poolData.tokenA) ? poolData.tokenAProgram : poolData.tokenBProgram;
        accounts[9] = (inputToken == poolData.tokenA) ? poolData.tokenBProgram : poolData.tokenAProgram;
        accounts[10] = inputToken;
        accounts[11] = outputToken;
        accounts[12] = poolData.observationKey;

        isSigner = new bool[](13);
        isSigner[0] = true;
        for (uint i = 1; i < isSigner.length - 1; ++i) {
            isSigner[i] = false;
        }

        isWritable = new bool[](13);
        isWritable[0] = false;
        isWritable[1] = false;
        isWritable[2] = false;
        isWritable[3] = true;
        isWritable[4] = true;
        isWritable[5] = true;
        isWritable[6] = true;
        isWritable[7] = true;
        isWritable[8] = false;
        isWritable[9] = false;
        isWritable[10] = false;
        isWritable[11] = false;
        isWritable[12] = true;
    }
}