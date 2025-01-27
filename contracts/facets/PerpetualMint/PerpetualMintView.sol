// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { Pausable } from "@solidstate/contracts/security/pausable/Pausable.sol";

import { PerpetualMintInternal } from "./PerpetualMintInternal.sol";
import { IPerpetualMintView } from "./IPerpetualMintView.sol";
import { MintResultData, MintTokenTiersData, PerpetualMintStorage as Storage, TiersData, VRFConfig } from "./Storage.sol";

/// @title PerpetualMintView
/// @dev PerpetualMintView facet contract containing all externally called view functions
contract PerpetualMintView is
    Pausable,
    PerpetualMintInternal,
    IPerpetualMintView
{
    constructor(address vrf) PerpetualMintInternal(vrf) {}

    /// @inheritdoc IPerpetualMintView
    function accruedConsolationFees()
        external
        view
        returns (uint256 accruedFees)
    {
        accruedFees = _accruedConsolationFees();
    }

    /// @inheritdoc IPerpetualMintView
    function accruedMintEarnings()
        external
        view
        returns (uint256 accruedEarnings)
    {
        accruedEarnings = _accruedMintEarnings();
    }

    /// @inheritdoc IPerpetualMintView
    function accruedProtocolFees() external view returns (uint256 accruedFees) {
        accruedFees = _accruedProtocolFees();
    }

    /// @inheritdoc IPerpetualMintView
    function BASIS() external pure returns (uint32 value) {
        value = _BASIS();
    }

    /// @inheritdoc IPerpetualMintView
    function calculateMintResult(
        address collection,
        uint32 numberOfMints,
        uint256 randomness,
        uint256 pricePerMint,
        uint256 prizeValueInWei
    ) external view returns (MintResultData memory result) {
        result = _calculateMintResult(
            collection,
            numberOfMints,
            randomness,
            pricePerMint,
            prizeValueInWei
        );
    }

    /// @inheritdoc IPerpetualMintView
    function collectionMintFeeDistributionRatioBP(
        address collection
    ) external view returns (uint32 ratioBP) {
        ratioBP = _collectionMintFeeDistributionRatioBP(collection);
    }

    /// @inheritdoc IPerpetualMintView
    function collectionMintMultiplier(
        address collection
    ) external view returns (uint256 multiplier) {
        multiplier = _collectionMintMultiplier(
            Storage.layout().collections[collection]
        );
    }

    /// @inheritdoc IPerpetualMintView
    function collectionMintPrice(
        address collection
    ) external view returns (uint256 mintPrice) {
        mintPrice = _collectionMintPrice(
            Storage.layout().collections[collection]
        );
    }

    /// @inheritdoc IPerpetualMintView
    function collectionReferralFeeBP(
        address collection
    ) external view returns (uint32 referralFeeBP) {
        referralFeeBP = _collectionReferralFeeBP(
            Storage.layout().collections[collection]
        );
    }

    /// @inheritdoc IPerpetualMintView
    function collectionRisk(
        address collection
    ) external view returns (uint32 risk) {
        risk = _collectionRisk(Storage.layout().collections[collection]);
    }

    /// @inheritdoc IPerpetualMintView
    function collectionConsolationFeeBP()
        external
        view
        returns (uint32 collectionConsolationFeeBasisPoints)
    {
        collectionConsolationFeeBasisPoints = _collectionConsolationFeeBP();
    }

    /// @inheritdoc IPerpetualMintView
    function defaultCollectionMintPrice()
        external
        pure
        returns (uint256 mintPrice)
    {
        mintPrice = _defaultCollectionMintPrice();
    }

    /// @inheritdoc IPerpetualMintView
    function defaultCollectionReferralFeeBP()
        external
        view
        returns (uint32 referralFeeBP)
    {
        referralFeeBP = _defaultCollectionReferralFeeBP();
    }

    /// @inheritdoc IPerpetualMintView
    function defaultCollectionRisk() external pure returns (uint32 risk) {
        risk = _defaultCollectionRisk();
    }

    /// @inheritdoc IPerpetualMintView
    function defaultEthToMintRatio() external pure returns (uint32 ratio) {
        ratio = _defaultEthToMintRatio();
    }

    /// @inheritdoc IPerpetualMintView
    function ethToMintRatio() external view returns (uint256 ratio) {
        ratio = _ethToMintRatio(Storage.layout());
    }

    /// @inheritdoc IPerpetualMintView
    function mintEarningsBufferBP()
        external
        view
        returns (uint32 mintEarningsBufferBasisPoints)
    {
        mintEarningsBufferBasisPoints = _mintEarningsBufferBP();
    }

    /// @inheritdoc IPerpetualMintView
    function mintFeeBP() external view returns (uint32 mintFeeBasisPoints) {
        mintFeeBasisPoints = _mintFeeBP();
    }

    /// @inheritdoc IPerpetualMintView
    function mintForEthConsolationFeeBP()
        external
        view
        returns (uint32 mintForEthConsolationFeeBasisPoints)
    {
        mintForEthConsolationFeeBasisPoints = _mintForEthConsolationFeeBP();
    }

    /// @inheritdoc IPerpetualMintView
    function mintToken() external view returns (address token) {
        token = _mintToken();
    }

    /// @inheritdoc IPerpetualMintView
    function mintTokenConsolationFeeBP()
        external
        view
        returns (uint32 mintTokenConsolationFeeBasisPoints)
    {
        mintTokenConsolationFeeBasisPoints = _mintTokenConsolationFeeBP();
    }

    /// @inheritdoc IPerpetualMintView
    function mintTokenTiers()
        external
        view
        returns (MintTokenTiersData memory mintTokenTiersData)
    {
        mintTokenTiersData = _mintTokenTiers();
    }

    /// @inheritdoc IPerpetualMintView
    function redemptionFeeBP() external view returns (uint32 feeBP) {
        feeBP = _redemptionFeeBP();
    }

    /// @inheritdoc IPerpetualMintView
    function redeemPaused() external view returns (bool status) {
        status = _redeemPaused();
    }

    /// @inheritdoc IPerpetualMintView
    function SCALE() external pure returns (uint256 value) {
        value = _SCALE();
    }

    /// @inheritdoc IPerpetualMintView
    function tiers() external view returns (TiersData memory tiersData) {
        tiersData = _tiers();
    }

    /// @inheritdoc IPerpetualMintView
    function vrfConfig() external view returns (VRFConfig memory config) {
        config = _vrfConfig();
    }

    /// @inheritdoc IPerpetualMintView
    function vrfSubscriptionBalanceThreshold()
        external
        view
        returns (uint96 threshold)
    {
        threshold = _vrfSubscriptionBalanceThreshold();
    }

    /// @notice Chainlink VRF Coordinator callback
    /// @param requestId id of request for random values
    /// @param randomWords random values returned from Chainlink VRF coordination
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        _fulfillRandomWords(requestId, randomWords);
    }
}
