// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import { ICore } from "../../contracts/diamonds/Core/ICore.sol";
import { MintOutcome, MintResultDataBlast, MintTokenTiersData, TiersData } from "../../contracts/facets/PerpetualMint/Storage.sol";

/// @title CalculateMintResultSupraBlast
/// @dev Script for calculating the result of a batch mint attempt on Blast, Supra-specific
contract CalculateMintResultSupraBlast is Script, Test {
    // get CoreBlast PerpetualMint diamond address
    address payable perpetualMintAddress =
        payable(vm.envAddress("CORE_BLAST_ADDRESS"));

    ICore core = ICore(perpetualMintAddress);

    uint32 BASIS = core.BASIS();

    uint256 ethToMintRatio = core.ethToMintRatio();

    MintTokenTiersData mintTokenTiers = core.mintTokenTiers();

    TiersData tiers = core.tiers();

    /// @dev runs the script logic
    function run() external {
        // get collection address
        address collection = vm.envAddress("COLLECTION_ADDRESS");

        // determine if minting for ETH
        bool mintForEth = collection == address(type(uint160).max);

        // determine if minting for mint or collection
        bool mintForMint = collection == address(0);

        // get number of mints
        uint8 numberOfMints = uint8(vm.envUint("NUMBER_OF_MINTS"));

        // get randomness signature
        uint256[] memory envRandomness = vm.envUint("RANDOMNESS", ",");

        // get price per mint
        uint256 pricePerMint = vm.envUint("PRICE_PER_MINT");

        // get prize value in wei
        uint256 prizeValueInWei = vm.envUint("PRIZE_VALUE_IN_WEI");

        // convert randomness signature to uint256[2]
        uint256[2] memory randomnessFixed;

        randomnessFixed[0] = envRandomness[0];
        randomnessFixed[1] = envRandomness[1];

        uint256 collectionMintMultiplier = core.collectionMintMultiplier(
            collection
        );

        uint256 collectionMintPrice = core.collectionMintPrice(collection);

        console.log("BASIS: ", BASIS);
        console.log("Collection Address: ", collection);
        console.log("Mint for ETH?: ", mintForEth);
        console.log("Mint for Mint?: ", mintForMint);
        console.log("Collection Mint Multiplier: ", collectionMintMultiplier);
        console.log("Collection Mint Price: ", collectionMintPrice);
        console.log("ETH to Mint Ratio: ", ethToMintRatio);
        console.log("Number of Mints: ", numberOfMints);
        emit log_named_array("Randomness Signature: ", envRandomness);
        console.log("Price Per Mint: ", pricePerMint);
        console.log("Prize Value in Wei: ", prizeValueInWei);

        if (mintForMint) {
            console.log("Mint Token Tiers: ");
            emit log_named_array(
                "  Tier Multipliers: ",
                mintTokenTiers.tierMultipliers
            );
            emit log_named_array(
                "  Tier Risks: ",
                toUint256Array(mintTokenTiers.tierRisks)
            );
        } else {
            if (mintForEth) {
                uint256 msgValue = numberOfMints * pricePerMint;

                // calculate the mint for ETH consolation fee
                uint256 mintForEthConsolationFee = (msgValue *
                    core.mintForEthConsolationFeeBP()) / BASIS;

                // apply the mint for ETH-specific mint fee ratio
                uint256 additionalDepositorFee = (mintForEthConsolationFee *
                    core.collectionMintFeeDistributionRatioBP(collection)) /
                    BASIS;

                // calculate the protocol mint fee
                uint256 mintFee = (msgValue * core.mintFeeBP()) / BASIS;

                uint256 mintEarningsFee = msgValue -
                    mintForEthConsolationFee -
                    mintFee +
                    additionalDepositorFee;

                uint256 risk = (mintEarningsFee * BASIS) / prizeValueInWei;

                console.log("Risk: ", risk);
            } else {
                uint32 collectionRisk = core.collectionRisk(collection);

                console.log("Collection Risk: ", collectionRisk);
            }

            console.log("Tiers: ");
            emit log_named_array("  Tier Multipliers: ", tiers.tierMultipliers);
            emit log_named_array(
                "  Tier Risks: ",
                toUint256Array(tiers.tierRisks)
            );
        }

        MintResultDataBlast memory result = core.calculateMintResultSupraBlast(
            collection,
            numberOfMints,
            randomnessFixed,
            pricePerMint,
            prizeValueInWei
        );

        // Iterate over the mintOutcomes array in MintResultData
        for (uint256 i = 0; i < result.mintOutcomes.length; i++) {
            // Access the MintOutcome struct at the i-th index
            MintOutcome memory outcome = result.mintOutcomes[i];

            // Log the outcome
            console.log("\nOutcome #", i + 1, ":");
            console.log("Tier: ", outcome.tierIndex);
            console.log(" | Tier Multiplier: ", outcome.tierMultiplier);
            console.log(" | Tier Risk: ", outcome.tierRisk);
            console.log(" | Tier Mint Amount in Wei: ", outcome.mintAmount);
        }

        console.log(
            "\nTotal Blast Bounty Yield Amount: ",
            result.totalBlastYieldAmount
        );

        console.log("\nTotal Mint Amount: ", result.totalMintAmount);

        if (!mintForMint) {
            if (mintForEth) {
                console.log(
                    "Total Prize Value Amount: ",
                    result.totalPrizeValueAmount
                );
            }

            console.log(
                "Total Number of Wins: ",
                result.totalSuccessfulMints,
                "\n"
            );
        }
    }

    /// @notice Converts a uint32 array to a uint256 array
    /// @param uint32Array The uint32 array to convert
    /// @return uint256Array The converted uint256 array
    function toUint256Array(
        uint32[] memory uint32Array
    ) internal pure returns (uint256[] memory uint256Array) {
        uint256Array = new uint256[](uint32Array.length);

        for (uint256 i = 0; i < uint32Array.length; ++i) {
            uint256Array[i] = uint256(uint32Array[i]);
        }

        return uint256Array;
    }
}
