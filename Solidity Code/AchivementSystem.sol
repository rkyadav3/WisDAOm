// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./StudentCreditToken.sol";
import "./CreditManager.sol";

/**
 * @title AchievementSystem
 * @dev NFT-based achievement badges for academic accomplishments
 */
contract AchievementSystem is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    
    // Token ID counter
    Counters.Counter private _tokenIdCounter;
    
    // StudentCreditToken contract instance
    StudentCreditToken public studentCreditToken;
    
    // CreditManager contract instance
    CreditManager public creditManager;
    
    // Achievement structure
    struct Achievement {
        uint256 id;
        string name;
        string description;
        uint256 threshold;
        string metadataURI;
        bool isActive;
    }
    
    // Student achievement records
    struct StudentAchievement {
        address student;
        uint256 achievementId;
        uint256 tokenId;
        uint256 timestamp;
    }
    
    // Achievement catalog
    Achievement[] public achievements;
    
    // Achievement records
    StudentAchievement[] public studentAchievements;
    
    // Achievement managers
    mapping(address => bool) public achievementManagers;
    
    // Mapping of student addresses to earned achievement IDs
    mapping(address => mapping(uint256 => bool)) public earnedAchievements;
    
    // Events
    event AchievementCreated(uint256 indexed achievementId, string name, uint256 threshold);
    event AchievementUpdated(uint256 indexed achievementId, string name, uint256 threshold, bool isActive);
    event AchievementEarned(address indexed student, uint256 indexed achievementId, uint256 indexed tokenId);
    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);

    constructor(address tokenAddress, address creditManagerAddress) 
        ERC721("Student Achievement Badge", "SAB") 
        Ownable(msg.sender) 
    {
        // Set the token contract address
        studentCreditToken = StudentCreditToken(tokenAddress);
        
        // Set the credit manager contract address
        creditManager = CreditManager(creditManagerAddress);
        
        // Add contract deployer as an achievement manager
        achievementManagers[msg.sender] = true;
    }

    /**
     * @dev Modifier to restrict function access to achievement managers
     */
    modifier onlyManager() {
        require(achievementManagers[msg.sender], "Not authorized as achievement manager");
        _;
    }

    /**
     * @dev Add a new achievement manager
     * @param manager Address of the manager to add
     */
    function addManager(address manager) external onlyOwner {
        require(manager != address(0), "Invalid address");
        achievementManagers[manager] = true;
        emit ManagerAdded(manager);
    }

    /**
     * @dev Remove an achievement manager
     * @param manager Address of the manager to remove
     */
    function removeManager(address manager) external onlyOwner {
        achievementManagers[manager] = false;
        emit ManagerRemoved(manager);
    }

    /**
     * @dev Create a new achievement
     * @param name Name of the achievement
     * @param description Description of the achievement
     * @param threshold Credit threshold required to earn the achievement
     * @param metadataURI IPFS URI for the achievement metadata
     */
    function createAchievement(string memory name, string memory description, uint256 threshold, string memory metadataURI) 
        external 
        onlyManager 
    {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(metadataURI).length > 0, "Metadata URI cannot be empty");
        require(threshold > 0, "Threshold must be greater than 0");
        
        uint256 achievementId = achievements.length;
        
        achievements.push(Achievement({
            id: achievementId,
            name: name,
            description: description,
            threshold: threshold,
            metadataURI: metadataURI,
            isActive: true
        }));
        
        emit AchievementCreated(achievementId, name, threshold);
    }

    /**
     * @dev Update an existing achievement
     * @param achievementId ID of the achievement to update
     * @param name New name of the achievement
     * @param description New description of the achievement
     * @param threshold New credit threshold
     * @param metadataURI New metadata URI
     * @param isActive New active status
     */
    function updateAchievement(
        uint256 achievementId, 
        string memory name, 
        string memory description, 
        uint256 threshold, 
        string memory metadataURI, 
        bool isActive
    ) 
        external 
        onlyManager 
    {
        require(achievementId < achievements.length, "Invalid achievement ID");
        
        Achievement storage achievement = achievements[achievementId];
        
        if (bytes(name).length > 0) {
            achievement.name = name;
        }
        
        if (bytes(description).length > 0) {
            achievement.description = description;
        }
        
        if (threshold > 0) {
            achievement.threshold = threshold;
        }
        
        if (bytes(metadataURI).length > 0) {
            achievement.metadataURI = metadataURI;
        }
        
        achievement.isActive = isActive;
        
        emit AchievementUpdated(achievementId, achievement.name, achievement.threshold, achievement.isActive);
    }

    /**
     * @dev Award an achievement to a student
     * @param student Address of the student
     * @param achievementId ID of the achievement
     */
    function awardAchievement(address student, uint256 achievementId) 
        external 
        onlyManager 
    {
        require(student != address(0), "Invalid student address");
        require(achievementId < achievements.length, "Invalid achievement ID");
        require(!earnedAchievements[student][achievementId], "Achievement already earned");
        
        Achievement storage achievement = achievements[achievementId];
        require(achievement.isActive, "Achievement is not active");
        
        // Mint new NFT
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        _mint(student, tokenId);
        _setTokenURI(tokenId, achievement.metadataURI);
        
        // Record achievement
        earnedAchievements[student][achievementId] = true;
        
        studentAchievements.push(StudentAchievement({
            student: student,
            achievementId: achievementId,
            tokenId: tokenId,
            timestamp: block.timestamp
        }));
        
        emit AchievementEarned(student, achievement