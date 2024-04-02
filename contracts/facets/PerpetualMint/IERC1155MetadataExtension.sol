// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title IERC1155MetadataExtension
/// @dev ERC1155MetadataExtension interface
interface IERC1155MetadataExtension {
    /// @notice Retrieves token values for a given owner and token ID
    /// @param owner The owner of the tokens
    /// @param tokenId The token ID for which values are retrieved
    /// @return tokenValues An array of uint256 representing the values of each token
    function getTokenValues(
        address owner,
        uint256 tokenId
    ) external view returns (uint256[] memory tokenValues);

    /// @notice reads the ERC1155 collection name
    /// @return name ERC1155 collection name
    function name() external view returns (string memory name);

    /// @notice reads the ERC1155 collection symbol
    /// @return symbol ERC1155 collection symbol
    function symbol() external view returns (string memory symbol);
}
