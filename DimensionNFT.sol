// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DimensionNFTV2
 * @dev NFTs with Common/Rare/Legendary tiers
 */
contract DimensionNFTV2 is ERC721, Ownable {
    
    uint256 private _tokenIdCounter;
    
    enum ArtifactRarity { COMMON, RARE, LEGENDARY }
    
    struct Artifact {
        string name;
        string description;
        ArtifactRarity rarity;
        uint256 dimensionId;
        uint256 timestamp;
    }
    
    mapping(uint256 => Artifact) public artifacts;
    
    event ArtifactMinted(
        address indexed player,
        uint256 indexed tokenId,
        string name,
        ArtifactRarity rarity,
        uint256 dimensionId
    );
    
    constructor() ERC721("Dimension Artifact", "ARTIFACT") Ownable(msg.sender) {}
    
    /**
     * @dev Mint artifact (only game contract)
     */
    function mintArtifact(
        address player,
        string memory name,
        string memory description,
        ArtifactRarity rarity,
        uint256 dimensionId
    ) external onlyOwner returns (uint256) {
        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;
        
        _safeMint(player, newTokenId);
        
        artifacts[newTokenId] = Artifact({
            name: name,
            description: description,
            rarity: rarity,
            dimensionId: dimensionId,
            timestamp: block.timestamp
        });
        
        emit ArtifactMinted(player, newTokenId, name, rarity, dimensionId);
        
        return newTokenId;
    }
    
    /**
     * @dev Get artifact details
     */
    function getArtifact(uint256 tokenId) external view returns (
        string memory name,
        string memory description,
        ArtifactRarity rarity,
        uint256 dimensionId,
        uint256 timestamp
    ) {
        require(_ownerOf(tokenId) != address(0), "Artifact doesn't exist");
        Artifact memory artifact = artifacts[tokenId];
        return (
            artifact.name,
            artifact.description,
            artifact.rarity,
            artifact.dimensionId,
            artifact.timestamp
        );
    }
    
    /**
     * @dev Get player's artifacts
     */
    function getPlayerArtifacts(address player) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(player);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= _tokenIdCounter; i++) {
            if (_ownerOf(i) == player) {
                tokenIds[index] = i;
                index++;
            }
        }
        
        return tokenIds;
    }
    
    /**
     * @dev Total minted
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }
}