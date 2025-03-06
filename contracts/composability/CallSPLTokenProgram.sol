// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { CallSolanaHelperLib } from '../utils/CallSolanaHelperLib.sol';
import { LibSPLTokenData } from "./libraries/spl-token-program/LibSPLTokenData.sol";
import { LibSPLTokenProgram } from "./libraries/spl-token-program/LibSPLTokenProgram.sol";

import { ICallSolana } from '../precompiles/ICallSolana.sol';

/// @title CallSPLTokenProgram
/// @notice Example contract showing how to use LibSPLTokenProgram library to interact with Solana's SPL Token program
/// @author maxpolizzo@gmail.com
contract CallSPLTokenProgram {
    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    uint64 public constant MINT_RENT_EXEMPT_BALANCE = 1461600;
    uint64 public constant ATA_RENT_EXEMPT_BALANCE = 2039280;

    function createInitializeTokenMint(bytes memory seed, uint8 decimals) external {
        // Create SPL token mint account: msg.sender and a seed are used to calculate the salt used to derive the token
        // mint account, allowing for future authentication when interacting with this token mint. Note that it is
        // entirely possible to calculate the salt in a different manner and to use a different approach for
        // authentication
        bytes32 tokenMint = CALL_SOLANA.createResource(
            sha256(abi.encodePacked(
                msg.sender, // msg.sender is included here for future authentication
                seed // using different seeds allows msg.sender to create different token mint accounts
            )), // salt
            LibSPLTokenData.SPL_TOKEN_MINT_SIZE, // space
            MINT_RENT_EXEMPT_BALANCE, // lamports
            LibSPLTokenData.TOKEN_PROGRAM_ID // Owner must be SPL Token program
        );

        // This contract is mint/freeze authority
        bytes32 authority = CALL_SOLANA.getNeonAddress(address(this));
        // Format initializeMint2 instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatInitializeMint2Instruction(
            decimals,
            tokenMint,
            authority,
            authority
        );

        // Prepare initializeMint2 instruction
        bytes memory initializeMint2Ix = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSPLTokenData.TOKEN_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );

        // Execute initializeMint2 instruction
        CALL_SOLANA.execute(0, initializeMint2Ix);
    }

    function createInitializeATA(bytes32 tokenMint, bytes32 owner, bytes32 tokenOwner) external {
        /// @dev If the ATA is to be used by `msg.sender` to send tokens through this contract the `owner` field should
        /// be left empty.
        /// @dev If the ATA is to be used by a third party `user` NeonEVM account to send tokens through this contract
        /// the `owner` field should be `CALL_SOLANA.getNeonAddress(user)` and the `tokenOwner` field should be left
        /// empty.
        /// @dev If the ATA is to be used by a third party `solanaUser` Solana account to send tokens directly on Solana
        /// without interacting with this contract, both the `owner` field and the `tokenOwner` field should be the
        /// `solanaUser` account.
        if (owner == bytes32(0)) {
            // If owner is empty, account owner is derived from msg.sender
            owner =  CALL_SOLANA.getNeonAddress(msg.sender);
            // If owner is empty, token owner is this contract
            tokenOwner = CALL_SOLANA.getNeonAddress(address(this));
        } else if (tokenOwner == bytes32(0)) {
            // If tokenOwner is empty, token owner is this contract
            tokenOwner = CALL_SOLANA.getNeonAddress(address(this));
        }
        // Create SPL associated token account: the owner account is used to derive the ATA, allowing for future
        // authentication when interacting with this ATA
        bytes32 ata = CALL_SOLANA.createResource(
            sha256(abi.encodePacked(
                owner,
                LibSPLTokenData.TOKEN_PROGRAM_ID,
                tokenMint,
                uint8(0), // Here we use nonce == 0 by default, however nonce can be incremented te create different ATAs for the same owner
                LibSPLTokenData.ASSOCIATED_TOKEN_PROGRAM_ID
            )), // salt
            LibSPLTokenData.SPL_TOKEN_ACCOUNT_SIZE, // space
            ATA_RENT_EXEMPT_BALANCE, // lamports
            LibSPLTokenData.TOKEN_PROGRAM_ID // Owner must be SPL Token program
        );
        // Format initializeAccount2 instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatInitializeAccount2Instruction(
            ata,
            tokenMint,
            tokenOwner  // account which owns the ATA and can spend from it
        );
        // Prepare initializeAccount2 instruction
        bytes memory initializeAccount2Ix = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSPLTokenData.TOKEN_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute initializeAccount2 instruction
        CALL_SOLANA.execute(0, initializeAccount2Ix);
    }

    function mintTokens(
        bytes memory seed,
        bytes32 recipientATA,
        uint64 amount
    ) external {
        // Authentication: we derive the token mint account from msg.sender and seed
        bytes32 tokenMint = getTokenMintAccount(msg.sender, seed);
        // This contract is mint/freeze authority
        bytes32 mintAuthority = CALL_SOLANA.getNeonAddress(address(this));
        // Format mintTo instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatMintToInstruction(
            tokenMint,
            mintAuthority,
            recipientATA,
            amount
        );
        // Prepare mintTo instruction
        bytes memory mintToIx = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSPLTokenData.TOKEN_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute mintTo instruction
        CALL_SOLANA.execute(0, mintToIx);
    }

    function transferTokens(
        bytes32 tokenMint,
        bytes32 recipientATA,
        uint64 amount
    ) external {
        // Authentication: sender's Solana account is derived from msg.sender
        bytes32 senderPubKey = CALL_SOLANA.getNeonAddress(msg.sender);
        // Authentication: we derive the sender's associated token account from the sender account and the token mint account
        bytes32 senderATA = getAssociatedTokenAccount(tokenMint, senderPubKey);
        // This contract owns the sender's associated token account
        bytes32 thisContract = CALL_SOLANA.getNeonAddress(address(this));
        // Format transfer instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatTransferInstruction(
            senderATA,
            recipientATA,
            thisContract, // ATA owner
            amount
        );
        // Prepare transfer instruction
        bytes memory transferIx = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSPLTokenData.TOKEN_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute transfer instruction
        CALL_SOLANA.execute(0, transferIx);
    }

    function claimTokens(
        bytes32 senderATA,
        bytes32 recipientATA,
        uint64 amount
    ) external {
        // Authentication: spender's Solana account is derived from msg.sender
        bytes32 spenderPubKey = CALL_SOLANA.getNeonAddress(msg.sender);
        // Authentication: we verify that the sender ATA has been delegated to the spender account and that delegated
        // amount is larger than or equal to claimed amount
        bytes32 senderATADelegate = getSPLTokenAccountDelegate(senderATA);
        require(senderATADelegate == spenderPubKey, 'CallSPLTokenProgram.claimTokens: msg.sender is not approved to spend from ata');
        uint64 senderATADelegatedAmount = getSPLTokenAccountDelegatedAmount(senderATA);
        require(senderATADelegatedAmount >= amount, 'CallSPLTokenProgram.claimTokens: insufficient amount delegated to msg.sender');
        // This contract owns the sender associated token account
        bytes32 thisContract = CALL_SOLANA.getNeonAddress(address(this));
        // Format transfer instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatTransferInstruction(
            senderATA,
            recipientATA,
            thisContract, // ATA owner
            amount
        );
        // Prepare transfer instruction
        bytes memory transferIx = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSPLTokenData.TOKEN_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute transfer instruction
        CALL_SOLANA.execute(0, transferIx);
    }

    function updateMintAuthority(
        bytes memory seed,
        bytes32 newAuthority
    ) external {
        // Authentication: we derive the token mint account from msg.sender and seed
        bytes32 tokenMint = getTokenMintAccount(msg.sender, seed);
        // This contract is the current mint authority
        bytes32 currentAuthority = CALL_SOLANA.getNeonAddress(address(this));
        // Format createSetAuthority instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatUpdateMintAuthorityInstruction(
            tokenMint,
            currentAuthority,
            newAuthority
        );
        // Prepare createSetAuthority instruction
        bytes memory createSetAuthorityIx = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSPLTokenData.TOKEN_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute createSetAuthority instruction
        CALL_SOLANA.execute(0, createSetAuthorityIx);
    }

    function approve(bytes32 tokenMint, bytes32 delegate, uint64 amount) external {
        // Authentication: user's Solana account is derived from msg.sender
        bytes32 userPubKey = CALL_SOLANA.getNeonAddress(msg.sender);
        // Authentication: we derive the user's associated token account from the user account and the token mint account
        bytes32 userATA = getAssociatedTokenAccount(tokenMint, userPubKey);
        // This contract owns the user's associated token account
        bytes32 thisContract = CALL_SOLANA.getNeonAddress(address(this));

        // Format approve instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatApproveInstruction(
            userATA,
            delegate,
            thisContract, // ATA owner
            amount
        );
        // Prepare approve instruction
        bytes memory approveIx = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSPLTokenData.TOKEN_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute approve instruction
        CALL_SOLANA.execute(0, approveIx);
    }

    function revokeApproval(bytes32 tokenMint) external {
        // Authentication: user's Solana account is derived from msg.sender
        bytes32 userPubKey = CALL_SOLANA.getNeonAddress(msg.sender);
        // Authentication: we derive the user's associated token account from the user account and the token mint account
        bytes32 userATA = getAssociatedTokenAccount(tokenMint, userPubKey);
        // This contract owns the user's associated token account
        bytes32 thisContract = CALL_SOLANA.getNeonAddress(address(this));
        // Format revoke instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatRevokeInstruction(
            userATA,
            thisContract // ATA owner
        );
        // Prepare revoke instruction
        bytes memory revokeIx = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSPLTokenData.TOKEN_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute revoke instruction
        CALL_SOLANA.execute(0, revokeIx);
    }


    // Returns Solana public key for NeonEVM address
    function getNeonAddress(address user) external view returns (bytes32) {
        return CALL_SOLANA.getNeonAddress(user);
    }

    // SPL Token mint data getters

    function getTokenMintAccount(address owner, bytes memory seed) public view returns(bytes32) {
        // Returns the token mint account derived from from msg.sender and seed
        return CALL_SOLANA.getResourceAddress(sha256(abi.encodePacked(
            owner, // account that created and owns the token mint
            seed // Seed that has been used to create token mint
        )));
    }

    function getSPLTokenMintIsInitialized(bytes32 tokenMint) external view returns(bytes1) {
        return LibSPLTokenData.getSPLTokenMintIsInitialized(tokenMint);
    }

    function getSPLTokenSupply(bytes32 tokenMint) external view returns(uint64) {
        return LibSPLTokenData.getSPLTokenSupply(tokenMint);
    }

    function getSPLTokenDecimals(bytes32 tokenMint) external view returns(bytes1) {
        return LibSPLTokenData.getSPLTokenDecimals(tokenMint);
    }

    function getSPLTokenMintAuthority(bytes32 tokenMint) external view returns(bytes32) {
        return LibSPLTokenData.getSPLTokenMintAuthority(tokenMint);
    }

    function getSPLTokenFreezeAuthority(bytes32 tokenMint) external view returns(bytes32) {
        return LibSPLTokenData.getSPLTokenFreezeAuthority(tokenMint);
    }

    function getSPLTokenMintData(bytes32 tokenMint) external view returns(LibSPLTokenData.SPLTokenMintData memory) {
        return LibSPLTokenData.getSPLTokenMintData(tokenMint);
    }

    // SPL Token account data getters

    function getAssociatedTokenAccount(
        bytes32 _tokenMint,
        bytes32 userPubKey
    ) public view returns(bytes32) {
        // Returns ATA derived with nonce == 0 by default
        return LibSPLTokenData.getAssociatedTokenAccount(_tokenMint, userPubKey, 0);
    }

    function getSPLTokenAccountIsInitialized(bytes32 tokenAccount) external view returns(bytes1) {
        return LibSPLTokenData.getSPLTokenAccountIsInitialized(tokenAccount);
    }

    function getSPLTokenAccountIsNative(bytes32 tokenAccount) external view returns(bytes8) {
        return LibSPLTokenData.getSPLTokenAccountIsNative(tokenAccount);
    }

    function getSPLTokenAccountBalance(bytes32 tokenAccount) external view returns(uint64) {
        return LibSPLTokenData.getSPLTokenAccountBalance(tokenAccount);
    }

    function getSPLTokenAccountOwner(bytes32 tokenAccount) external view returns(bytes32) {
        return LibSPLTokenData.getSPLTokenAccountOwner(tokenAccount);
    }

    function getSPLTokenAccountMint(bytes32 tokenAccount) external view returns(bytes32) {
        return LibSPLTokenData.getSPLTokenAccountMint(tokenAccount);
    }

    function getSPLTokenAccountDelegate(bytes32 tokenAccount) public view returns(bytes32) {
        return LibSPLTokenData.getSPLTokenAccountDelegate(tokenAccount);
    }

    function getSPLTokenAccountDelegatedAmount(bytes32 tokenAccount) public view returns(uint64) {
        return LibSPLTokenData.getSPLTokenAccountDelegatedAmount(tokenAccount);
    }

    function getSPLTokenAccountCloseAuthority(bytes32 tokenAccount) external view returns(bytes32) {
        return LibSPLTokenData.getSPLTokenAccountCloseAuthority(tokenAccount);
    }

    function getSPLTokenAccountData(bytes32 tokenAccount) external view returns(LibSPLTokenData.SPLTokenAccountData memory) {
        return LibSPLTokenData.getSPLTokenAccountData(tokenAccount);
    }
}
