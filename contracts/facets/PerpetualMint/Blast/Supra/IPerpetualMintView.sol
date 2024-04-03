// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintViewBlast } from "../IPerpetualMintView.sol";
import { MintResultDataBlast } from "../../Storage.sol";

/// @title IPerpetualMintViewSupraBlast
/// @dev Extension interface of the PerpetualMintViewSupraBlast facet
interface IPerpetualMintViewSupraBlast is IPerpetualMintViewBlast {
    /// @notice calculates the Blast Supra VRF-specific mint result of a given number of mint attempts for a given collection using given signature as randomness
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    /// @param signature signature value to use as randomness in calculation
    /// @param pricePerMint price paid per mint for collection (denominated in units of wei)
    function calculateMintResultSupraBlast(
        address collection,
        uint8 numberOfMints,
        uint256[2] calldata signature,
        uint256 pricePerMint
    ) external view returns (MintResultDataBlast memory result);
}
