// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../Token/Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { CoreTest } from "../../../diamonds/Core/Core.t.sol";
import { TokenProxyTest } from "../../../diamonds/TokenProxy.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_resolveMintsForMint
/// @dev PerpetualMint test contract for testing expected behavior of the _resolveMintsForMint function
contract PerpetualMint_resolveMintsForMint is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest,
    TokenTest
{
    /// @dev mimics random values sent by Chainlink VRF
    uint256[] randomWords;

    /// @dev for now, mints for $MINT are treated as address(0) collections
    address COLLECTION = address(0);

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev sets up the context for the test cases
    function setUp() public override(PerpetualMintTest, TokenTest) {
        PerpetualMintTest.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        token.addMintingContract(address(perpetualMint));
    }

    /// @dev tests that _resolveMintsForMint applies mint adjustment factor correctly when paying a multiple of the set $MINT mint price.
    function test_resolveMintsForMintAppliesMintAdjustmentFactorCorrectlyWhenPaidWithMoreThanMintPrice()
        external
    {
        // expected lowest tier mint resolution
        randomWords.push(2);

        // assert that the minter currently has no $MINT tokens
        assert(token.balanceOf(minter) == 0);

        // pay 10 times the $MINT mint price per spin
        MINT_PRICE = perpetualMint.collectionMintPrice(COLLECTION) * 10;

        uint256 scaledPricePerSpin = MINT_PRICE * perpetualMint.SCALE();

        // calculate the mint price adjustment factor & scale back down
        TEST_ADJUSTMENT_FACTOR =
            ((scaledPricePerSpin /
                perpetualMint.collectionMintPrice(COLLECTION)) *
                perpetualMint.BASIS()) /
            perpetualMint.SCALE();

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMint(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );

        uint256 totalMintedAmount = ((testMintTokenTiersData.tierMultipliers[
            0
        ] *
            perpetualMint.ethToMintRatio() *
            perpetualMint.collectionMintPrice(COLLECTION) *
            perpetualMint.collectionMintMultiplier(COLLECTION) *
            TEST_ADJUSTMENT_FACTOR) /
            (uint256(perpetualMint.BASIS()) *
                perpetualMint.BASIS() *
                perpetualMint.BASIS()));

        uint256 distributionTokenAmount = (totalMintedAmount *
            token.distributionFractionBP()) / perpetualMint.BASIS();

        assert(
            token.balanceOf(minter) ==
                totalMintedAmount - distributionTokenAmount
        );
    }

    /// @dev tests that _resolveMintsForMint applies mint adjustment factor correctly when paying a fraction of the set $MINT mint price.
    function test_resolveMintsForMintAppliesMintAdjustmentFactorCorrectlyWhenPaidWithPartialMintPrice()
        external
    {
        // expected lowest tier mint resolution
        randomWords.push(2);

        // assert that the minter currently has no $MINT tokens
        assert(token.balanceOf(minter) == 0);

        // pay 1/4th of the $MINT mint price per spin
        MINT_PRICE = perpetualMint.collectionMintPrice(COLLECTION) / 4;

        uint256 scaledPricePerSpin = MINT_PRICE * perpetualMint.SCALE();

        // calculate the mint price adjustment factor & scale back down
        TEST_ADJUSTMENT_FACTOR =
            ((scaledPricePerSpin /
                perpetualMint.collectionMintPrice(COLLECTION)) *
                perpetualMint.BASIS()) /
            perpetualMint.SCALE();

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMint(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );

        uint256 totalMintedAmount = ((testMintTokenTiersData.tierMultipliers[
            0
        ] *
            perpetualMint.ethToMintRatio() *
            perpetualMint.collectionMintPrice(COLLECTION) *
            perpetualMint.collectionMintMultiplier(COLLECTION) *
            TEST_ADJUSTMENT_FACTOR) /
            (uint256(perpetualMint.BASIS()) *
                perpetualMint.BASIS() *
                perpetualMint.BASIS()));

        uint256 distributionTokenAmount = (totalMintedAmount *
            token.distributionFractionBP()) / perpetualMint.BASIS();

        assert(
            token.balanceOf(minter) ==
                totalMintedAmount - distributionTokenAmount
        );
    }

    /// @dev tests that _resolveMintsForMint applies mint for $MINT multipliers correctly
    function test_resolveMintsForMintAppliesMintForMintMultipliersCorrectly()
        external
    {
        // expected lowest tier mint resolution
        randomWords.push(2);

        // assert that the minter currently has no $MINT tokens
        assert(token.balanceOf(minter) == 0);

        perpetualMint.setCollectionMintMultiplier(COLLECTION, 1e10); // 10x multiplier

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMint(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );

        uint256 totalMintedAmount = ((testMintTokenTiersData.tierMultipliers[
            0
        ] *
            perpetualMint.ethToMintRatio() *
            perpetualMint.collectionMintPrice(COLLECTION) *
            perpetualMint.collectionMintMultiplier(COLLECTION) *
            TEST_ADJUSTMENT_FACTOR) /
            (uint256(perpetualMint.BASIS()) *
                perpetualMint.BASIS() *
                perpetualMint.BASIS()));

        uint256 distributionTokenAmount = (totalMintedAmount *
            token.distributionFractionBP()) / perpetualMint.BASIS();

        assert(
            token.balanceOf(minter) ==
                totalMintedAmount - distributionTokenAmount
        );
    }

    /// @dev tests that the MintResult event is emitted when successfully resolving a mint
    function test_resolveMintsForMintEmitsMintResult() external {
        // expected lowest tier mint resolutions
        randomWords.push(2);

        uint256 totalMintedAmount = ((testMintTokenTiersData.tierMultipliers[
            0
        ] *
            perpetualMint.ethToMintRatio() *
            perpetualMint.collectionMintPrice(COLLECTION) *
            perpetualMint.collectionMintMultiplier(COLLECTION) *
            TEST_ADJUSTMENT_FACTOR) /
            (uint256(perpetualMint.BASIS()) *
                perpetualMint.BASIS() *
                perpetualMint.BASIS()));

        vm.expectEmit();
        emit MintResult(minter, COLLECTION, 1, totalMintedAmount, 0);

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMint(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );
    }

    /// @dev tests that _resolveMintsForMint works with many random values
    function testFuzz_resolveMintsForMint(uint256 value) external {
        randomWords.push(value);

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMintsForMint(
            minter,
            TEST_ADJUSTMENT_FACTOR,
            randomWords
        );
    }
}
