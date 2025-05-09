// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { CallSolanaHelperLib } from '../utils/CallSolanaHelperLib.sol';
import { Constants } from "./libraries/Constants.sol";
import { LibSPLTokenData } from "./libraries/spl-token-program/LibSPLTokenData.sol";
import { LibSystemData } from "./libraries/system-program/LibSystemData.sol";
import { LibSPLTokenProgram } from "./libraries/spl-token-program/LibSPLTokenProgram.sol";
import { ICallSolana } from '../precompiles/ICallSolana.sol';
import { ISolanaNative } from '../precompiles/ISolanaNative.sol';
import { IERC20ForSpl } from './interfaces/IERC20ForSpl.sol';

contract ExampleTransferSOLs {
    /// @dev Instance of NeonEVM's CallSolana precompiled smart contract
    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);
    /// @dev Instance of NeonEVM's SolanaNative precompiled smart contract
    ISolanaNative public constant SOLANA_NATIVE = ISolanaNative(0xfF00000000000000000000000000000000000007);

    address public immutable wsolAddress;
    constructor(address _wsolAddress) {
        wsolAddress = _wsolAddress;
    }

    function transferSOLorWSOL(
        uint64 amount,
        address user
    ) external {
        // fake some wSOL balance inside the contract
        IERC20ForSpl(wsolAddress).transferFrom(msg.sender, address(this), amount);
        
        // check if user is Solana or Neon EVM user
        bytes32 solanaAddress = SOLANA_NATIVE.solanaAddress(user);
        if (solanaAddress != bytes32(0)) {
            /// Case 1 - send SOL to standard Solana user
            bytes32 tokenMint = IERC20ForSpl(wsolAddress).tokenMint();
            bytes32 thisContractAccount = CALL_SOLANA.getNeonAddress(address(this));
            
            // Creation of the arbitrary token account ( in this step the account is still not initialized, we will be doing this in our first instruction request to the 006 precompile )
            bytes32 tokenAccount = CALL_SOLANA.createResource(
                keccak256(abi.encodePacked(
                    user
                )),
                LibSPLTokenData.SPL_TOKEN_ACCOUNT_SIZE, // space
                LibSystemData.getRentExemptionBalance(
                    LibSPLTokenData.SPL_TOKEN_ACCOUNT_SIZE,
                    LibSystemData.getSystemAccountData(
                        Constants.getSysvarRentPubkey(),
                        LibSystemData.getSpace(Constants.getSysvarRentPubkey())
                    )
                ), // rent-exempt lamports value for the arbitrary token account
                Constants.getTokenProgramId()
            );

            // Building instruction #1 - initializing the arbitrary token account instruction
            (
                bytes32[] memory accounts,
                bool[] memory isSigner,
                bool[] memory isWritable,
                bytes memory data
            ) = LibSPLTokenProgram.formatInitializeAccount2Instruction(
                tokenAccount,
                tokenMint,
                thisContractAccount
            );
            bytes memory initializeAccount2Ix = CallSolanaHelperLib.prepareSolanaInstruction(
                Constants.getTokenProgramId(),
                accounts,
                isSigner,
                isWritable,
                data
            );

            // Building instruction #2 - closing the arbitrary token account instruction
            (   bytes32[] memory accountsCloseAccount,
                bool[] memory isSignerCloseAccount,
                bool[] memory isWritableCloseAccount,
                bytes memory dataCloseAccount
            ) = LibSPLTokenProgram.formatCloseAccountInstruction(
                tokenAccount,
                solanaAddress, // The account which will receive the closed token account's SOL balance
                thisContractAccount // token accounttoken account owner
            );
            bytes memory closeAccountIx = CallSolanaHelperLib.prepareSolanaInstruction(
                Constants.getTokenProgramId(),
                accountsCloseAccount,
                isSignerCloseAccount,
                isWritableCloseAccount,
                dataCloseAccount
            );

            // execute instruction #1
            CALL_SOLANA.execute(0, initializeAccount2Ix); // stop iterative mode

            // erc20forspl transferSolana to fund the arbitrary token account with some wSOLs
            IERC20ForSpl(wsolAddress).transferSolana(tokenAccount, amount);

            // execute instruction #2
            CALL_SOLANA.execute(0, closeAccountIx);
        } else {
            /// Case 2 - send WSOL to standard Neon EVM user
            IERC20ForSpl(wsolAddress).transfer(user, amount);
        }
    }

    function isSolanaUser(address user) public view returns(bytes32) {
        return SOLANA_NATIVE.solanaAddress(user);
    }
}
