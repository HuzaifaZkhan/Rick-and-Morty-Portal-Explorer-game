// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title QuantumTokenV2
 * @dev Improved ERC-20 token with better faucet system
 */
contract QuantumTokenV2 is ERC20, Ownable {
    mapping(address => bool) public hasClaimed;
    mapping(address => uint256) public lastClaimTime;

    uint256 public constant FAUCET_AMOUNT = 1000 * 10 ** 18;
    uint256 public constant FAUCET_COOLDOWN = 24 hours;

    event FaucetClaimed(address indexed player, uint256 amount);

    constructor() ERC20("Quantum Fuel", "QUANTUM") Ownable(msg.sender) {
        // Mint 10 million tokens to owner (for rewards pool)
        _mint(msg.sender, 10000000 * 10 ** 18);
    }

    /**
     * @dev Claim faucet (once per 24 hours)
     */
    function claimFaucet() external {
        require(
            !hasClaimed[msg.sender] ||
                block.timestamp >= lastClaimTime[msg.sender] + FAUCET_COOLDOWN,
            "Faucet on cooldown!"
        );

        hasClaimed[msg.sender] = true;
        lastClaimTime[msg.sender] = block.timestamp;

        _mint(msg.sender, FAUCET_AMOUNT);
        emit FaucetClaimed(msg.sender, FAUCET_AMOUNT);
    }

    /**
     * @dev Mint tokens (only game contract)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Check time until next faucet claim
     */
    function timeUntilNextClaim(
        address player
    ) external view returns (uint256) {
        if (!hasClaimed[player]) return 0;

        uint256 nextClaimTime = lastClaimTime[player] + FAUCET_COOLDOWN;
        if (block.timestamp >= nextClaimTime) return 0;

        return nextClaimTime - block.timestamp;
    }
}
