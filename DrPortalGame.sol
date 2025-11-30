// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DimensionNFTV2.sol";

/**
 * @title DrPortalGameV2
 * @dev Complete game with level gating, NFT tiers, reward scaling
 */
contract DrPortalGameV2 {
    IERC20 public quantumToken;
    DimensionNFTV2 public dimensionNFT;
    address public owner;

    struct Player {
        uint256 level;
        uint256 xp;
        uint256 dimensionsExplored;
        uint256 currentDimensionId;
        bool inDimension;
    }

    mapping(address => Player) public players;
    mapping(address => mapping(uint256 => bool)) public hasCompletedDimension;
    mapping(address => mapping(uint256 => bool)) public hasClaimedNFT;

    event PortalOpened(
        address indexed player,
        uint256 dimensionId,
        uint256 cost
    );
    event DimensionCompleted(
        address indexed player,
        uint256 dimensionId,
        uint256 reward
    );
    event NFTAwarded(
        address indexed player,
        uint256 tokenId,
        uint256 dimensionId,
        DimensionNFTV2.ArtifactRarity rarity
    );
    event LevelUp(address indexed player, uint256 newLevel);
    event PlayerFled(address indexed player, uint256 dimensionId);

    constructor(address _quantumToken, address _dimensionNFT) {
        quantumToken = IERC20(_quantumToken);
        dimensionNFT = DimensionNFTV2(_dimensionNFT);
        owner = msg.sender;
    }

    /**
     * @dev Get portal cost for dimension
     */
    function getPortalCost(uint256 dimensionId) public pure returns (uint256) {
        require(dimensionId >= 1 && dimensionId <= 21, "Invalid dimension");
        return (100 + ((dimensionId - 1) * 50)) * 10 ** 18;
    }

    /**
     * @dev Get reward for completing dimension
     */
    function getDimensionReward(
        uint256 dimensionId
    ) public pure returns (uint256) {
        require(dimensionId >= 1 && dimensionId <= 21, "Invalid dimension");
        return (200 + (dimensionId * 50)) * 10 ** 18;
    }

    /**
     * @dev Check if player can access dimension (level requirement)
     */
    function canAccessDimension(
        address player,
        uint256 dimensionId
    ) public view returns (bool) {
        if (dimensionId <= 5) return true; // First 5 always open
        if (dimensionId <= 10) return players[player].level >= 3;
        if (dimensionId <= 15) return players[player].level >= 6;
        if (dimensionId <= 20) return players[player].level >= 10;
        return players[player].level >= 15; // Dimension 21
    }

    /**
     * @dev Open portal to specific dimension
     */
    function openPortalToDimension(uint256 dimensionId) external {
        require(dimensionId >= 1 && dimensionId <= 21, "Invalid dimension");
        require(!players[msg.sender].inDimension, "Already in dimension!");
        require(canAccessDimension(msg.sender, dimensionId), "Level too low!");

        uint256 cost = getPortalCost(dimensionId);
        require(
            quantumToken.balanceOf(msg.sender) >= cost,
            "Not enough QUANTUM!"
        );

        quantumToken.transferFrom(msg.sender, address(this), cost);

        players[msg.sender].inDimension = true;
        players[msg.sender].currentDimensionId = dimensionId;

        emit PortalOpened(msg.sender, dimensionId, cost);
    }

    /**
     * @dev Complete dimension and get rewards
     */
    function completeDimension() external {
        require(players[msg.sender].inDimension, "Not in dimension!");

        uint256 dimensionId = players[msg.sender].currentDimensionId;

        // Mark completed
        if (!hasCompletedDimension[msg.sender][dimensionId]) {
            hasCompletedDimension[msg.sender][dimensionId] = true;
            players[msg.sender].dimensionsExplored++;
        }

        // Give XP
        players[msg.sender].xp += 50;

        // Check level up
        uint256 xpNeeded = 200 + (players[msg.sender].level * 300);
        if (
            players[msg.sender].xp >= xpNeeded && players[msg.sender].level < 20
        ) {
            players[msg.sender].level++;
            emit LevelUp(msg.sender, players[msg.sender].level);
        }

        // Give token reward
        uint256 reward = getDimensionReward(dimensionId);
        quantumToken.transfer(msg.sender, reward);

        // Mint NFT if first time completing this dimension
        if (!hasClaimedNFT[msg.sender][dimensionId]) {
            hasClaimedNFT[msg.sender][dimensionId] = true;
            _mintDimensionNFT(msg.sender, dimensionId);
        }

        players[msg.sender].inDimension = false;

        emit DimensionCompleted(msg.sender, dimensionId, reward);
    }

    /**
     * @dev Flee dimension (lose tokens)
     */
    function fleeDimension() external {
        require(players[msg.sender].inDimension, "Not in dimension!");

        uint256 dimensionId = players[msg.sender].currentDimensionId;
        players[msg.sender].inDimension = false;

        emit PlayerFled(msg.sender, dimensionId);
    }

    /**
     * @dev Mint NFT with rarity based on dimension difficulty
     */
    function _mintDimensionNFT(address player, uint256 dimensionId) internal {
        // Determine rarity based on dimension
        DimensionNFTV2.ArtifactRarity rarity;

        if (dimensionId <= 7) {
            rarity = DimensionNFTV2.ArtifactRarity.COMMON;
        } else if (dimensionId <= 14) {
            rarity = DimensionNFTV2.ArtifactRarity.RARE;
        } else {
            rarity = DimensionNFTV2.ArtifactRarity.LEGENDARY;
        }

        string memory name = _getArtifactName(dimensionId, rarity);
        string memory desc = _getArtifactDesc(dimensionId);

        uint256 tokenId = dimensionNFT.mintArtifact(
            player,
            name,
            desc,
            rarity,
            dimensionId
        );

        emit NFTAwarded(player, tokenId, dimensionId, rarity);
    }

    /**
     * @dev Get player stats
     */
    function getPlayerStats(
        address player
    )
        external
        view
        returns (
            uint256 level,
            uint256 xp,
            uint256 dimensionsExplored,
            bool inDimension,
            uint256 currentDimensionId
        )
    {
        Player memory p = players[player];
        return (
            p.level,
            p.xp,
            p.dimensionsExplored,
            p.inDimension,
            p.currentDimensionId
        );
    }

    // Artifact names by dimension
    function _getArtifactName(
        uint256 dimId,
        DimensionNFTV2.ArtifactRarity rarity
    ) internal pure returns (string memory) {
        string[21] memory baseNames = [
            "C-137 Portal Fragment",
            "Cronenberg Tissue",
            "Blender Core",
            "Sentient Pizza",
            "Gazorpazorp Crystal",
            "Purge Medallion",
            "Anatomy Pass",
            "Microverse Battery",
            "Froopy Token",
            "Citadel Card",
            "Bird Feather",
            "Giant Relic",
            "Unity Node",
            "Scary Hat",
            "Federation Badge",
            "Cable Box",
            "Eye Patch",
            "Simulation Chip",
            "Survivor Medal",
            "Customs Stamp",
            "Reality Stabilizer"
        ];

        string memory rarityPrefix = "";
        if (rarity == DimensionNFTV2.ArtifactRarity.RARE)
            rarityPrefix = "Rare ";
        if (rarity == DimensionNFTV2.ArtifactRarity.LEGENDARY)
            rarityPrefix = "Legendary ";

        return string(abi.encodePacked(rarityPrefix, baseNames[dimId - 1]));
    }

    function _getArtifactDesc(
        uint256 dimId
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "Proof of conquering Dimension ",
                    _uint2str(dimId),
                    " in the multiverse"
                )
            );
    }

    function _uint2str(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Owner functions
    function withdrawTokens() external {
        require(msg.sender == owner, "Not owner");
        quantumToken.transfer(owner, quantumToken.balanceOf(address(this)));
    }
}
