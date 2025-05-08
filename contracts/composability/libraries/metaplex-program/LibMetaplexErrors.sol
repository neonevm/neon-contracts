// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title LibMetaplexErrors
/// @notice Custom errors library for interactions with Solana's Metaplex program
/// @author maxpolizzo@gmail.com
library LibMetaplexErrors {
    // Invalid authority errors
    error InvalidMintAuthority(bytes32 tokenMint, bytes32 mintAuthority, bytes32 invalidAuthority, string message);
    error InvalidUpdateAuthority(bytes32 metadataPDA, bytes32 updateAuthority, bytes32 invalidAuthority, string message);

    // Metadata account already created error
    error MetadataAlreadyExists(bytes32 tokenMint, bytes32 metadataPDA, string message);

    // Immutable metadata account error
    error ImmutableMetadata(bytes32 tokenMint, string message);

    // Metadata validation error
    error InvalidTokenMetadata(string message);

    // Metadata account data query error
    error AccountDataQuery();
    error BytesSliceOutOfBounds();
}
