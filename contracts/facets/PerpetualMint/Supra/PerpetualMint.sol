// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMint } from "../IPerpetualMint.sol";
import { PerpetualMint } from "../PerpetualMint.sol";

/// @title PerpetualMintSupra
/// @dev Supra VRF-specific overrides for PerpetualMint
contract PerpetualMintSupra is PerpetualMint {
    /// @dev number of words used in mints for $MINT
    uint8 private constant ONE_WORD = 1;

    /// @dev number of words used in mints for collections
    uint8 private constant TWO_WORDS = 2;

    constructor(address vrf) PerpetualMint(vrf) {}

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintForMintWithEth(
        address referrer,
        uint32 numberOfMints
    ) external payable virtual override whenNotPaused {
        _attemptBatchMintForMintWithEthSupra(
            msg.sender,
            referrer,
            uint8(numberOfMints),
            ONE_WORD
        );
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintForMintWithMint(
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external virtual override whenNotPaused {
        _attemptBatchMintForMintWithMintSupra(
            msg.sender,
            referrer,
            pricePerMint,
            uint8(numberOfMints),
            ONE_WORD
        );
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintWithEth(
        address collection,
        address referrer,
        uint32 numberOfMints,
        uint256 collectionFloorPrice
    ) external payable virtual override whenNotPaused {
        _attemptBatchMintWithEthSupra(
            msg.sender,
            collection,
            referrer,
            uint8(numberOfMints),
            TWO_WORDS,
            collectionFloorPrice
        );
    }

    /// @inheritdoc IPerpetualMint
    function attemptBatchMintWithMint(
        address collection,
        address referrer,
        uint256 pricePerMint,
        uint256 collectionFloorPrice,
        uint32 numberOfMints
    ) external virtual override whenNotPaused {
        _attemptBatchMintWithMintSupra(
            msg.sender,
            collection,
            referrer,
            pricePerMint,
            collectionFloorPrice,
            uint8(numberOfMints),
            TWO_WORDS
        );
    }
}
