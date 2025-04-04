// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./StudentCreditToken.sol";

/**
 * @title RedeemStore
 * @dev Allows students to exchange credits for items
 */
contract RedeemStore is Ownable, Pausable, ReentrancyGuard {
    // StudentCreditToken contract instance
    StudentCreditToken public studentCreditToken;
    
    // Store item structure
    struct Item {
        uint256 id;
        string name;
        string description;
        uint256 creditCost;
        uint256 quantity;
        bool isActive;
    }
    
    // Redemption structure
    struct Redemption {
        uint256 id;
        address student;
        uint256 itemId;
        uint256 timestamp;
        bool fulfilled;
    }
    
    // Item catalog
    Item[] public items;
    
    // Redemption history
    Redemption[] public redemptions;
    
    // Item ID counter
    uint256 private nextItemId = 1;
    
    // Redemption ID counter
    uint256 private nextRedemptionId = 1;
    
    // Mapping of store managers
    mapping(address => bool) public storeManagers;
    
    // Events
    event ItemAdded(uint256 indexed itemId, string name, uint256 creditCost, uint256 quantity);
    event ItemUpdated(uint256 indexed itemId, string name, uint256 creditCost, uint256 quantity, bool isActive);
    event QuantityUpdated(uint256 indexed itemId, uint256 newQuantity);
    event ItemRedeemed(uint256 indexed redemptionId, address indexed student, uint256 indexed itemId, uint256 creditCost);
    event RedemptionFulfilled(uint256 indexed redemptionId, address indexed student, uint256 indexed itemId);
    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);

    constructor(address tokenAddress) Ownable(msg.sender) {
        // Set the token contract address
        studentCreditToken = StudentCreditToken(tokenAddress);
        
        // Add contract deployer as a store manager
        storeManagers[msg.sender] = true;
    }

    /**
     * @dev Modifier to restrict function access to store managers
     */
    modifier onlyManager() {
        require(storeManagers[msg.sender], "Not authorized as store manager");
        _;
    }

    /**
     * @dev Add a new store manager
     * @param manager Address of the manager to add
     */
    function addManager(address manager) external onlyOwner {
        require(manager != address(0), "Invalid address");
        storeManagers[manager] = true;
        emit ManagerAdded(manager);
    }

    /**
     * @dev Remove a store manager
     * @param manager Address of the manager to remove
     */
    function removeManager(address manager) external onlyOwner {
        storeManagers[manager] = false;
        emit ManagerRemoved(manager);
    }

    /**
     * @dev Add a new item to the store
     * @param name Name of the item
     * @param description Description of the item
     * @param creditCost Cost in credit tokens
     * @param quantity Available quantity
     */
    function addItem(string memory name, string memory description, uint256 creditCost, uint256 quantity) 
        external 
        onlyManager 
        whenNotPaused 
    {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(creditCost > 0, "Credit cost must be greater than 0");
        
        uint256 itemId = nextItemId++;
        
        items.push(Item({
            id: itemId,
            name: name,
            description: description,
            creditCost: creditCost,
            quantity: quantity,
            isActive: true
        }));
        
        emit ItemAdded(itemId, name, creditCost, quantity);
    }

    /**
     * @dev Update an existing item
     * @param itemId ID of the item to update
     * @param name New name of the item
     * @param description New description of the item
     * @param creditCost New cost in credit tokens
     * @param quantity New available quantity
     * @param isActive New active status
     */
    function updateItem(uint256 itemId, string memory name, string memory description, uint256 creditCost, uint256 quantity, bool isActive) 
        external 
        onlyManager 
        whenNotPaused 
    {
        require(itemId > 0 && itemId < nextItemId, "Invalid item ID");
        
        Item storage item = items[itemId - 1];
        
        if (bytes(name).length > 0) {
            item.name = name;
        }
        
        if (bytes(description).length > 0) {
            item.description = description;
        }
        
        if (creditCost > 0) {
            item.creditCost = creditCost;
        }
        
        item.quantity = quantity;
        item.isActive = isActive;
        
        emit ItemUpdated(itemId, item.name, item.creditCost, item.quantity, item.isActive);
    }

    /**
     * @dev Update item quantity
     * @param itemId ID of the item
     * @param newQuantity New quantity
     */
    function updateQuantity(uint256 itemId, uint256 newQuantity) 
        external 
        onlyManager 
        whenNotPaused 
    {
        require(itemId > 0 && itemId < nextItemId, "Invalid item ID");
        
        Item storage item = items[itemId - 1];
        item.quantity = newQuantity;
        
        emit QuantityUpdated(itemId, newQuantity);
    }

    /**
     * @dev Get the total number of items
     * @return Total number of items
     */
    function getItemCount() external view returns (uint256) {
        return items.length;
    }

    /**
     * @dev Get the total number of redemptions
     * @return Total number of redemptions
     */
    function getRedemptionCount() external view returns (uint256) {
        return redemptions.length;
    }

    /**
     * @dev Get redemptions by student
     * @param student Address of the student
     * @return Array of redemption IDs
     */
    function getStudentRedemptions(address student) external view returns (uint256[] memory) {
        // Count redemptions for the student
        uint256 count = 0;
        for (uint256 i = 0; i < redemptions.length; i++) {
            if (redemptions[i].student == student) {
                count++;
            }
        }
        
        // Populate the result array
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < redemptions.length; i++) {
            if (redemptions[i].student == student) {
                result[index] = redemptions[i].id;
                index++;
            }
        }
        
        return result;
    }

    /**
     * @dev Redeem an item from the store
     * @param itemId ID of the item to redeem
     */
    function redeemItem(uint256 itemId) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        require(itemId > 0 && itemId < nextItemId, "Invalid item ID");
        
        Item storage item = items[itemId - 1];
        require(item.isActive, "Item is not available");
        require(item.quantity > 0, "Item out of stock");
        
        uint256 creditCost = item.creditCost;
        require(studentCreditToken.balanceOf(msg.sender) >= creditCost, "Insufficient credit balance");
        
        // Create redemption record first
        uint256 redemptionId = nextRedemptionId++;
        redemptions.push(Redemption({
            id: redemptionId,
            student: msg.sender,
            itemId: itemId,
            timestamp: block.timestamp,
            fulfilled: false
        }));
        
        // Reduce item quantity
        item.quantity--;
        
        // Transfer credits (burns them)
        require(
            studentCreditToken.transferFrom(msg.sender, address(this), creditCost),
            "Credit transfer failed"
        );
        
        emit ItemRedeemed(redemptionId, msg.sender, itemId, creditCost);
    }

    /**
     * @dev Mark a redemption as fulfilled
     * @param redemptionId ID of the redemption to fulfill
     */
    function fulfillRedemption(uint256 redemptionId) 
        external 
        onlyManager 
        whenNotPaused 
    {
        require(redemptionId > 0 && redemptionId < nextRedemptionId, "Invalid redemption ID");
        
        Redemption storage redemption = redemptions[redemptionId - 1];
        require(!redemption.fulfilled, "Redemption already fulfilled");
        
        redemption.fulfilled = true;
        
        emit RedemptionFulfilled(redemptionId, redemption.student, redemption.itemId);
    }

    /**
     * @dev Withdraw accumulated tokens (in case of contract upgrades or emergencies)
     * @param amount Amount of tokens to withdraw
     */
    function withdrawTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(
            studentCreditToken.balanceOf(address(this)) >= amount,
            "Insufficient balance"
        );
        
        require(
            studentCreditToken.transfer(owner(), amount),
            "Token transfer failed"
        );
    }

    /**
     * @dev Pause contract operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause contract operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}