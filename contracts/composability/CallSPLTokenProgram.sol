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

    function mint(
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

    function transfer(
        bytes32 tokenMint,
        bytes32 recipientATA,
        uint64 amount
    ) external {
        // Authentication: sender's Solana account is derived from msg.sender
        bytes32 senderPubKey = CALL_SOLANA.getNeonAddress(msg.sender);
        // Authentication: we derive the sender's associated token account from the sender account and the token mint account
        bytes32 senderATA = getAssociatedTokenAccount(tokenMint, senderPubKey);
        // This contract owns the sender's associated token account
        bytes32 thisContractPubKey = CALL_SOLANA.getNeonAddress(address(this));
        // Format transfer instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatTransferInstruction(
            senderATA,
            recipientATA,
            thisContractPubKey, // ATA owner
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

    function claim(
        bytes32 senderATA,
        bytes32 recipientATA,
        uint64 amount
    ) external {
        // Authentication: spender's Solana account is derived from msg.sender
        bytes32 spenderPubKey = CALL_SOLANA.getNeonAddress(msg.sender);
        // Authentication: we verify that the sender ATA has been delegated to the spender account and that delegated
        // amount is larger than or equal to claimed amount
        bytes32 senderATADelegate = getSPLTokenAccountDelegate(senderATA);
        require(senderATADelegate == spenderPubKey, 'CallSPLTokenProgram.claim: msg.sender is not approved to spend from ata');
        uint64 senderATADelegatedAmount = getSPLTokenAccountDelegatedAmount(senderATA);
        require(senderATADelegatedAmount >= amount, 'CallSPLTokenProgram.claim: insufficient amount delegated to msg.sender');
        // This contract owns the sender associated token account
        bytes32 thisContractPubKey = CALL_SOLANA.getNeonAddress(address(this));
        // Format transfer instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatTransferInstruction(
            senderATA,
            recipientATA,
            thisContractPubKey, // ATA owner
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

    function updateTokenMintAuthority(
        bytes memory seed, // Seed that was used to create the token mint of which we want to update authority
        LibSPLTokenProgram.AuthorityType authorityType, // MINT or FREEZE authority
        bytes32 newAuthority
    ) external {
        // Authentication: we derive the token mint account from msg.sender and seed
        bytes32 tokenMint = getTokenMintAccount(msg.sender, seed);
        // Check current authority
        bytes32 thisContractPubKey = CALL_SOLANA.getNeonAddress(address(this));
        if (authorityType == LibSPLTokenProgram.AuthorityType.MINT) {
            // Check that this contract is the current token mint's MINT authority (only token mint's MINT authority can
            // update token mint's MINT authority)
            // See: https://github.com/solana-program/token/blob/08aa3ccecb30692bca18d6f927804337de82d5ff/program/src/processor.rs#L486
            require(
                thisContractPubKey == LibSPLTokenData.getSPLTokenMintAuthority(tokenMint),
                "CallSPLTokenProgram.updateTokenMintAuthority: only token mint's mint authority can update mint authority"
            );
        } else if (authorityType == LibSPLTokenProgram.AuthorityType.FREEZE) {
            // Check that this contract is the current token mint's FREEZE authority (only token mint's FREEZE authority
            // can update token mint's FREEZE authority)
            // See: https://github.com/solana-program/token/blob/08aa3ccecb30692bca18d6f927804337de82d5ff/program/src/processor.rs#L500
            require(
                thisContractPubKey == LibSPLTokenData.getSPLTokenFreezeAuthority(tokenMint),
                "CallSPLTokenProgram.updateTokenMintAuthority: only token mint's freeze authority can update freeze authority"
            );
        } else {
            revert('CallSPLTokenProgram.updateTokenMintAuthority: authority type must be MINT or FREEZE');
        }
        // Format setAuthority instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatSetAuthorityInstruction(
            tokenMint, // account of which we want to update authority
            authorityType,
            thisContractPubKey, // current authority
            newAuthority
        );
        // Prepare setAuthority instruction
        bytes memory setAuthorityIx = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSPLTokenData.TOKEN_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute setAuthority instruction
        CALL_SOLANA.execute(0, setAuthorityIx);
    }

    function updateTokenAccountAuthority(
        bytes32 tokenMint, // SPL token mint associated with the SPL token account of which we want to update authority
        LibSPLTokenProgram.AuthorityType authorityType, // OWNER or CLOSE authority
        bytes32 newAuthority
    ) external {
        // Authentication: user's Solana account is derived from msg.sender
        bytes32 userPubKey = CALL_SOLANA.getNeonAddress(msg.sender);
        // Authentication: we derive the user's associated token account from the user account and the token mint account
        bytes32 userATA = getAssociatedTokenAccount(tokenMint, userPubKey);
        // Check current authority
        bytes32 thisContractPubKey = CALL_SOLANA.getNeonAddress(address(this));
        if (authorityType == LibSPLTokenProgram.AuthorityType.OWNER) {
            // Check that this contract is the current token account OWNER (only token account OWNER can update token
            // account OWNER)
            // See: https://github.com/solana-program/token/blob/08aa3ccecb30692bca18d6f927804337de82d5ff/program/src/processor.rs#L446
            require(
                thisContractPubKey == LibSPLTokenData.getSPLTokenAccountOwner(userATA),
                'CallSPLTokenProgram.updateTokenAccountAuthority: only token account owner can update owner authority'
            );
        } else if (authorityType == LibSPLTokenProgram.AuthorityType.CLOSE) {
            // Check that this contract is the current token account OWNER or the current token account's CLOSE authority
            // (only token account OWNER or CLOSE authority can update token account's CLOSE authority)
            // See: https://github.com/solana-program/token/blob/08aa3ccecb30692bca18d6f927804337de82d5ff/program/src/processor.rs#L465
            if (thisContractPubKey != LibSPLTokenData.getSPLTokenAccountOwner(userATA)) {
                require(
                    thisContractPubKey == LibSPLTokenData.getSPLTokenAccountCloseAuthority(userATA),
                    'CallSPLTokenProgram.updateTokenAccountAuthority: only token account owner or close authority can update close authority'
                );
            }
        } else {
            revert('CallSPLTokenProgram.updateTokenAccountAuthority: authority type must be OWNER or CLOSE');
        }
        // Format setAuthority instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatSetAuthorityInstruction(
            userATA, // account of which we want to update authority
            authorityType,
            thisContractPubKey, // current authority
            newAuthority
        );
        // Prepare setAuthority instruction
        bytes memory setAuthorityIx = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSPLTokenData.TOKEN_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute setAuthority instruction
        CALL_SOLANA.execute(0, setAuthorityIx);
    }

    function approve(bytes32 tokenMint, bytes32 delegate, uint64 amount) external {
        // Authentication: user's Solana account is derived from msg.sender
        bytes32 userPubKey = CALL_SOLANA.getNeonAddress(msg.sender);
        // Authentication: we derive the user's associated token account from the user account and the token mint account
        bytes32 userATA = getAssociatedTokenAccount(tokenMint, userPubKey);
        // This contract owns the user's associated token account
        bytes32 thisContractPubKey = CALL_SOLANA.getNeonAddress(address(this));

        // Format approve instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatApproveInstruction(
            userATA,
            delegate,
            thisContractPubKey, // ATA owner
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
        bytes32 thisContractPubKey = CALL_SOLANA.getNeonAddress(address(this));
        // Format revoke instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatRevokeInstruction(
            userATA,
            thisContractPubKey // ATA owner
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

    function burn(bytes32 tokenMint, uint64 amount) external {
        // Authentication: user's Solana account is derived from msg.sender
        bytes32 userPubKey = CALL_SOLANA.getNeonAddress(msg.sender);
        // Authentication: we derive the user's associated token account from the user account and the token mint account
        bytes32 userATA = getAssociatedTokenAccount(tokenMint, userPubKey);
        // This contract owns the user's associated token account
        bytes32 thisContractPubKey = CALL_SOLANA.getNeonAddress(address(this));

        // Format burn instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatBurnInstruction(
            userATA,
            tokenMint,
            thisContractPubKey, // ATA owner
            amount
        );
        // Prepare burn instruction
        bytes memory burnIx = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSPLTokenData.TOKEN_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute approve instruction
        CALL_SOLANA.execute(0, burnIx);
    }

    function closeTokenAccount(bytes32 tokenMint, bytes32 destination) external {
        // Authentication: user's Solana account is derived from msg.sender
        bytes32 userPubKey = CALL_SOLANA.getNeonAddress(msg.sender);
        // Authentication: we derive the user's associated token account from the user account and the token mint account
        bytes32 userATA = getAssociatedTokenAccount(tokenMint, userPubKey);
        // This contract owns the user's associated token account
        bytes32 thisContractPubKey = CALL_SOLANA.getNeonAddress(address(this));
        // Format closeAccount instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatCloseAccountInstruction(
            userATA,
            destination, // The account which will receive the closed token account's SOL balance
            thisContractPubKey // ATA owner
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

    /// @notice Function to execute a `syncNative` instruction in order to sync a Wrapped SOL token account's
    // balance
    /// @param tokenAccount The Wrapped SOL token account that we want to sync
    function syncWrappedSOLAccount(bytes32 tokenAccount) external {
        // No authentication: anyone can sync any Wrapped SOL token account
        // Format syncNative instruction
        (   bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibSPLTokenProgram.formatSyncNativeInstruction(
            tokenAccount
        );
        // Prepare syncNative instruction
        bytes memory syncNativeIx = CallSolanaHelperLib.prepareSolanaInstruction(
            LibSPLTokenData.TOKEN_PROGRAM_ID,
            accounts,
            isSigner,
            isWritable,
            data
        );
        // Execute syncNative instruction
        CALL_SOLANA.execute(0, syncNativeIx);
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

    function getSPLTokenDecimals(bytes32 tokenMint) external view returns(uint8) {
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
