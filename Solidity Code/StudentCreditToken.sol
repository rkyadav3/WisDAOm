// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title StudentCreditToken
 * @dev ERC20 token representing student academic credits
 */
contract StudentCreditToken is ERC20, Ownable, Pausable {
    // Mapping to track if an address is an authorized credit distributor
    mapping(address => bool) public creditDistributors;
    
    // Events
    event DistributorAdded(address indexed distributor);
    event DistributorRemoved(address indexed distributor);
    event CreditsMinted(address indexed student, uint256 amount, string reason);

    constructor() ERC20("Student Credit Token", "SCT") Ownable(msg.sender) {
        // Add contract deployer as a distributor
        creditDistributors[msg.sender] = true;
    }

    /**
     * @dev Modifier to restrict function access to credit distributors
     */
    modifier onlyCreditDistributor() {
        require(creditDistributors[msg.sender], "Not authorized as credit distributor");
        _;
    }

    /**
     * @dev Add a new credit distributor
     * @param distributor Address of the distributor to add
     */
    function addCreditDistributor(address distributor) external onlyOwner {
        require(distributor != address(0), "Invalid address");
        creditDistributors[distributor] = true;
        emit DistributorAdded(distributor);
    }

    /**
     * @dev Remove a credit distributor
     * @param distributor Address of the distributor to remove
     */
    function removeCreditDistributor(address distributor) external onlyOwner {
        creditDistributors[distributor] = false;
        emit DistributorRemoved(distributor);
    }

    /**
     * @dev Mint new credit tokens to a student
     * @param student Address of the student
     * @param amount Amount of tokens to mint
     * @param reason Reason for minting credits (e.g., "Course Completion", "Project")
     */
    function mintCredits(address student, uint256 amount, string memory reason) 
        external 
        onlyCreditDistributor 
        whenNotPaused 
    {
        require(student != address(0), "Invalid student address");
        require(amount > 0, "Amount must be greater than 0");
        
        _mint(student, amount);
        emit CreditsMinted(student, amount, reason);
    }

    /**
     * @dev Burn tokens from caller's account
     * @param amount Amount of tokens to burn
     */
    function burnCredits(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        _burn(msg.sender, amount);
    }

    /**
     * @dev Pause token transfers and operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause token transfers and operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // Override transfer functions to check if contract is paused
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }
}