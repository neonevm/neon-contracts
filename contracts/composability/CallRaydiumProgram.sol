// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Constants} from "./libraries/Constants.sol";
import {CallSolanaHelperLib} from "../utils/CallSolanaHelperLib.sol";
import {ICallSolana} from "../precompiles/ICallSolana.sol";
import {LibRaydium} from "./libraries/raydium/LibRaydium.sol";
import {LibRaydiumData} from "./libraries/raydium/LibRaydiumData.sol";
import {LibSPLTokenData} from "./libraries/spl-token-program/LibSPLTokenData.sol";
import {SolanaDataConverterLib} from "../utils/SolanaDataConverterLib.sol";


/// @title CallRaydiumProgram
/// @author https://twitter.com/mnedelchev_
/// @notice XYZ
contract CallRaydiumProgram {
    using SolanaDataConverterLib for uint64;
    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    function createPool(
        bytes32 tokenA,
        bytes32 tokenB,
        uint64 mintAAmount,
        uint64 mintBAmount,
        uint64 startTime
    ) public returns(bytes32) {
        (
            uint64 lamports,
            bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibRaydium.createPool(tokenA, tokenB, mintAAmount, mintBAmount, startTime, true);

        CALL_SOLANA.execute(
            lamports,
            CallSolanaHelperLib.prepareSolanaInstruction(
                Constants.CREATE_CPMM_POOL_PROGRAM_ID,
                accounts,
                isSigner,
                isWritable,
                data
            )
        );

        return accounts[3]; // poolId
    }

    function addLiquidity(
        bytes32 poolId,
        uint64 inputAmount,
        bool baseIn,
        uint8 slippage
    ) public {
        (
            uint64 lamports,
            bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibRaydium.addLiquidity(poolId, inputAmount, baseIn, slippage, true);

        CALL_SOLANA.execute(
            lamports,
            CallSolanaHelperLib.prepareSolanaInstruction(
                Constants.CREATE_CPMM_POOL_PROGRAM_ID,
                accounts,
                isSigner,
                isWritable,
                data
            )
        );
    }

    function withdrawLiquidity(
        bytes32 poolId,
        uint64 lpAmount,
        uint8 slippage
    ) public {
        (
            uint64 lamports,
            bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibRaydium.withdrawLiquidity(poolId, lpAmount, slippage, true);

        CALL_SOLANA.execute(
            lamports,
            CallSolanaHelperLib.prepareSolanaInstruction(
                Constants.CREATE_CPMM_POOL_PROGRAM_ID,
                accounts,
                isSigner,
                isWritable,
                data
            )
        );
    }

    function lockLiquidity(
        bytes32 poolId,
        uint64 lpAmount,
        bool withMetadata,
        bytes32 salt
    ) public returns(bytes32) {
        (
            uint64 lamports,
            bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibRaydium.lockLiquidity(
            poolId, 
            lpAmount, 
            withMetadata, 
            salt, 
            true,
            new bytes32[](0)
        );

        CALL_SOLANA.executeWithSeed(
            lamports,
            salt,
            CallSolanaHelperLib.prepareSolanaInstruction(
                Constants.LOCK_CPMM_POOL_PROGRAM_ID,
                accounts,
                isSigner,
                isWritable,
                data
            )
        );
        
        return accounts[4]; // NFT Mint account
    }

    function collectFees(
        bytes32 poolId,
        uint64 lpFeeAmount,
        bytes32 salt
    ) public {
        (
            uint64 lamports,
            bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibRaydium.collectFees(poolId, lpFeeAmount, salt, true);

        CALL_SOLANA.execute(
            lamports,
            CallSolanaHelperLib.prepareSolanaInstruction(
                Constants.LOCK_CPMM_POOL_PROGRAM_ID,
                accounts,
                isSigner,
                isWritable,
                data
            )
        );
    }

    function swapInput(
        bytes32 poolId,
        bytes32 inputToken,
        uint64 amountIn,
        uint8 slippage
    ) public {
        (
            uint64 lamports,
            bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibRaydium.swapInput(poolId, inputToken, amountIn, slippage, true);

        CALL_SOLANA.execute(
            lamports,
            CallSolanaHelperLib.prepareSolanaInstruction(
                Constants.CREATE_CPMM_POOL_PROGRAM_ID,
                accounts,
                isSigner,
                isWritable,
                data
            )
        );
    }

    function swapOutput(
        bytes32 poolId,
        bytes32 inputToken,
        uint64 amountOut,
        uint8 slippage
    ) public {
        (
            uint64 lamports,
            bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibRaydium.swapOutput(poolId, inputToken, amountOut, slippage, true);

        CALL_SOLANA.execute(
            lamports,
            CallSolanaHelperLib.prepareSolanaInstruction(
                Constants.CREATE_CPMM_POOL_PROGRAM_ID,
                accounts,
                isSigner,
                isWritable,
                data
            )
        );
    }

    function createPoolAndLockLP(
        bytes32 tokenA,
        bytes32 tokenB,
        uint64 mintAAmount,
        uint64 mintBAmount,
        uint64 startTime,
        bytes32 salt,
        bool withMetadata
    ) public returns (bytes32, uint64, bytes32) {
        // build instruction #1 - Creation of a pool
        (
            uint64 lamports,
            bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibRaydium.createPool(tokenA, tokenB, mintAAmount, mintBAmount, startTime, true);
        bytes32 poolId = accounts[3];
        if (salt == bytes32(0)) {
            salt = poolId;
        }

        // Semi-build instruction #2 - Locking of LP
        bytes32[] memory premadeLockLPAccounts = new bytes32[](19);
        premadeLockLPAccounts[8] = accounts[6];
        premadeLockLPAccounts[9] = accounts[9];
        premadeLockLPAccounts[11] = accounts[10];
        premadeLockLPAccounts[12] = accounts[11];
        (
            uint64 lamportsLock,
            bytes32[] memory accountsLock,
            bool[] memory isSignerLock,
            bool[] memory isWritableLock,
            bytes memory dataLock
        ) = LibRaydium.lockLiquidity(poolId, 0, false, salt, false, premadeLockLPAccounts);

        bytes memory lockInstruction = CallSolanaHelperLib.prepareSolanaInstruction(
            Constants.LOCK_CPMM_POOL_PROGRAM_ID,
            accountsLock,
            isSignerLock,
            isWritableLock,
            dataLock
        );

        // First composability request to Solana - no more iterative execution
        CALL_SOLANA.execute(
            lamports,
            CallSolanaHelperLib.prepareSolanaInstruction(
                Constants.CREATE_CPMM_POOL_PROGRAM_ID,
                accounts,
                isSigner,
                isWritable,
                data
            )
        );

        uint64 lpBalance = LibSPLTokenData.getSPLTokenAccountBalance(accountsLock[9]);
        bytes memory lockInstructionData = LibRaydium.buildLockLiquidityData(
            lpBalance,
            withMetadata
        );

        CALL_SOLANA.executeWithSeed(
            lamportsLock,
            salt,
            abi.encodePacked(
                lockInstruction,
                uint64(lockInstructionData.length).readLittleEndianUnsigned64(),
                lockInstructionData
            )
        );

        return (
            poolId,
            lpBalance,
            accounts[4] // NFT Mint account
        );
    }

    function getNeonAddress(address evm_address) public view returns(bytes32) {
        return CALL_SOLANA.getNeonAddress(evm_address);
    }

    function getPayer() public view returns(bytes32) {
        return CALL_SOLANA.getPayer();
    }

    function getExtAuthority(bytes32 salt) external view returns (bytes32) {
        return CALL_SOLANA.getExtAuthority(salt);
    }

    function getTokenReserve(bytes32 poolId, bytes32 tokenMint) public view returns(uint64) {
        return LibRaydiumData.getTokenReserve(poolId, tokenMint);
    }

    function getPoolLpAmount(bytes32 poolId) public view returns(uint64) {
        return LibRaydiumData.getPoolLpAmount(poolId);
    }

    function getPdaLpMint(bytes32 poolId) public view returns(bytes32) {
        return LibRaydiumData.getPdaLpMint(poolId);  
    }

    function lpToAmount(
        uint64 lp,
        uint64 poolAmountA,
        uint64 poolAmountB,
        uint64 supply
    ) public pure returns(uint64, uint64) {
        return LibRaydiumData.lpToAmount(lp, poolAmountA, poolAmountB, supply);
    }

    function getConfigData() public view returns(LibRaydiumData.ConfigData memory) {
        return LibRaydiumData.getConfigData(LibRaydiumData.getConfigAccount(0));
    }

    function getPoolData(
        bytes32 tokenA,
        bytes32 tokenB
    ) public view returns(LibRaydiumData.PoolData memory) {
        return LibRaydiumData.getPoolData(LibRaydiumData.getCpmmPdaPoolId(LibRaydiumData.getConfigAccount(0), tokenA, tokenB));
    }

    function getSwapOutput(
        bytes32 poolId,
        bytes32 configAccount,
        bytes32 inputToken,
        bytes32 outputToken,
        uint64 sourceAmount
    ) public view returns(uint64) {
        return LibRaydiumData.getSwapOutput(poolId, configAccount, inputToken, outputToken, sourceAmount);
    }

    function getSwapInput(
        bytes32 poolId,
        bytes32 configAccount,
        bytes32 inputToken,
        bytes32 outputToken,
        uint64 outputAmount
    ) public view returns(uint64) {
        return LibRaydiumData.getSwapInput(poolId, configAccount, inputToken, outputToken, outputAmount);
    }
}