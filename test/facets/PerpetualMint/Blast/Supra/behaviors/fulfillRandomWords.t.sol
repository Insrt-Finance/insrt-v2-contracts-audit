// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { PerpetualMintTest_SupraBlast } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../../../Token/Token.t.sol";
import { BlastForkTest } from "../../../../../BlastForkTest.t.sol";
import { CoreTest } from "../../../../../diamonds/Core/Core.t.sol";
import { TokenProxyTest } from "../../../../../diamonds/TokenProxy.t.sol";

/// @title PerpetualMint_fulfillRandomWordsSupraBlast
/// @dev PerpetualMint_SupraBlast test contract for testing expected fulfillRandomWords behavior. Tested on a Blast fork.
contract PerpetualMint_fulfillRandomWordsSupraBlast is
    BlastForkTest,
    PerpetualMintTest_SupraBlast,
    TokenTest
{
    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    uint256 internal MINT_FOR_MINT_PRICE;

    /// @dev address to test when minting for collections
    address internal constant MINT_FOR_COLLECTION_ADDRESS =
        BORED_APE_YACHT_CLUB;

    /// @dev address to test when minting for $MINT, currently treated as address(0)
    address internal constant MINT_FOR_MINT_ADDRESS = address(0);

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev Sets up the test case environment.
    function setUp() public override(PerpetualMintTest_SupraBlast, TokenTest) {
        PerpetualMintTest_SupraBlast.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        token.addMintingContract(address(perpetualMint));

        perpetualMint.setConsolationFees(100 ether);

        // mint a bunch of tokens to minter
        vm.prank(MINTER);
        token.mint(minter, MINT_AMOUNT * 1e10);

        // get the mint price for $MINT
        MINT_FOR_MINT_PRICE = perpetualMint.collectionMintPrice(
            MINT_FOR_MINT_ADDRESS
        );
    }

    /// @dev Tests fulfillRandomWords functionality when mint for collection is paid in ETH.
    function testFuzz_fulfillRandomWordsMintForCollectionWithEth(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint for a collection using ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(
            MINT_FOR_COLLECTION_ADDRESS,
            NO_REFERRER,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_COLLECTION_FLOOR_PRICE
        );

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        uint8 numberOfRandomWordsRequested = uint8(TEST_MINT_ATTEMPTS * 3); // 3 words per mint for collection attempt on Blast

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        assert(
            perpetualMint.exposed_pendingRequestsAt(
                MINT_FOR_COLLECTION_ADDRESS,
                0
            ) == postRequestNonce
        );

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(MINT_FOR_COLLECTION_ADDRESS, 1);
    }

    /// @dev Tests fulfillRandomWords functionality when mint for $MINT is paid in ETH.
    function testFuzz_fulfillRandomWordsMintForMintWithEth(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint for $MINT using ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_FOR_MINT_PRICE * TEST_MINT_ATTEMPTS
        }(NO_REFERRER, TEST_MINT_ATTEMPTS);

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        uint8 numberOfRandomWordsRequested = uint8(TEST_MINT_ATTEMPTS * 2); // 2 words per mint for $MINT attempt on Blast

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        assert(
            perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 0) ==
                postRequestNonce
        );

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 1);
    }

    /// @dev Tests fulfillRandomWords functionality when mint for collection is paid in $MINT.
    function testFuzz_fulfillRandomWordsMintForCollectionWithMint(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint for collection using $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            MINT_FOR_COLLECTION_ADDRESS,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_FOR_COLLECTION_FLOOR_PRICE,
            TEST_MINT_ATTEMPTS
        );

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        uint8 numberOfRandomWordsRequested = uint8(TEST_MINT_ATTEMPTS * 3); // 3 words per mint for collection attempt on Blast

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        assert(
            perpetualMint.exposed_pendingRequestsAt(
                MINT_FOR_COLLECTION_ADDRESS,
                0
            ) == postRequestNonce
        );

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(MINT_FOR_COLLECTION_ADDRESS, 1);
    }

    /// @dev Tests fulfillRandomWords functionality when mint for $MINT is paid in $MINT.
    function testFuzz_fulfillRandomWordsMintForMintWithMint(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint for $MINT using $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        uint8 numberOfRandomWordsRequested = uint8(TEST_MINT_ATTEMPTS * 2); // 2 words per mint for $MINT attempt on Blast

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        assert(
            perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 0) ==
                postRequestNonce
        );

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 1);
    }

    /// @dev Tests that fulfillRandomWords (when minting for a collection paid in ETH) can currently handle the max limit of 85 attempted mints per tx on Blast.
    function testFuzz_fulfillRandomWordsMintForCollectionWithETHCanHandleMaximum85MintAttempts(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // specify the current max number of words
        uint8 currentMaxNumWords = type(uint8).max;

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 3;

        // attempt to mint for collection with ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * MAXIMUM_MINT_ATTEMPTS
        }(
            MINT_FOR_COLLECTION_ADDRESS,
            NO_REFERRER,
            MAXIMUM_MINT_ATTEMPTS,
            TEST_MINT_FOR_COLLECTION_FLOOR_PRICE
        );

        vm.expectRevert();

        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * (MAXIMUM_MINT_ATTEMPTS + 1)
        }(
            MINT_FOR_COLLECTION_ADDRESS,
            NO_REFERRER,
            MAXIMUM_MINT_ATTEMPTS + 1,
            TEST_MINT_FOR_COLLECTION_FLOOR_PRICE
        );

        uint8 numberOfRandomWordsRequested = uint8(MAXIMUM_MINT_ATTEMPTS * 3); // 3 words per mint for collection attempt on Blast

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        (bool success, ) = supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        assert(success == true);
    }

    /// @dev Tests that fulfillRandomWords (when minting for $MINT paid in ETH) can currently handle the max limit of 127 attempted mints per tx on Blast.
    function testFuzz_fulfillRandomWordsMintForMintWithETHCanHandleMaximum127MintAttempts(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // specify the current max number of words
        uint8 currentMaxNumWords = type(uint8).max;

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 2;

        // attempt to mint for $MINT with ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_FOR_MINT_PRICE * MAXIMUM_MINT_ATTEMPTS
        }(NO_REFERRER, MAXIMUM_MINT_ATTEMPTS);

        vm.expectRevert();

        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_PRICE * (MAXIMUM_MINT_ATTEMPTS + 1)
        }(NO_REFERRER, MAXIMUM_MINT_ATTEMPTS + 1);

        uint8 numberOfRandomWordsRequested = uint8(MAXIMUM_MINT_ATTEMPTS * 2); // 2 words per mint for $MINT attempt on Blast

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        (bool success, ) = supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        assert(success == true);
    }

    /// @dev Tests that fulfillRandomWords (when minting for a collection paid in $MINT) can currently handle the max limit of 85 attempted mints per tx on Blast.
    function testFuzz_fulfillRandomWordsMintForCollectionWithMintCanHandleMaximum85MintAttempts(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // specify the current max number of words
        uint8 currentMaxNumWords = type(uint8).max;

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 3;

        // attempt to mint for collection with $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            MINT_FOR_COLLECTION_ADDRESS,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_FOR_COLLECTION_FLOOR_PRICE,
            MAXIMUM_MINT_ATTEMPTS
        );

        vm.expectRevert();

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            MINT_FOR_COLLECTION_ADDRESS,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_FOR_COLLECTION_FLOOR_PRICE,
            MAXIMUM_MINT_ATTEMPTS + 1
        );

        uint8 numberOfRandomWordsRequested = uint8(MAXIMUM_MINT_ATTEMPTS * 3); // 3 words per mint for collection attempt on Blast

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        (bool success, ) = supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        assert(success == true);
    }

    /// @dev Tests that fulfillRandomWords (when minting for $MINT paid in $MINT) can currently handle the max limit of 127 attempted mints per tx on Blast.
    function testFuzz_fulfillRandomWordsMintForMintWithMintCanHandleMaximum127MintAttempts(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // specify the current max number of words
        uint8 currentMaxNumWords = type(uint8).max;

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 2;

        // attempt to mint for $MINT with $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            MAXIMUM_MINT_ATTEMPTS
        );

        vm.expectRevert();

        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            MAXIMUM_MINT_ATTEMPTS + 1
        );

        uint8 numberOfRandomWordsRequested = uint8(MAXIMUM_MINT_ATTEMPTS * 2); // 2 word per mint for $MINT attempt on Blast

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        (bool success, ) = supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        assert(success == true);
    }
}
