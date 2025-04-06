// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./StudentCreditToken.sol";

/**
 * @title CreditManager
 * @dev Manages the distribution of student credits based on academic performance
 */
contract CreditManager is Ownable, Pausable {
    // StudentCreditToken contract instance
    StudentCreditToken public studentCreditToken;
    
    // Course credit structure
    struct Course {
        string courseId;
        string courseName;
        uint256 creditValue;
        bool isActive;
    }
    
    // Assignment structure
    struct Assignment {
        string assignmentId;
        string courseId;
        uint256 maxCredits;
        bool isActive;
    }

    // Mapping of course IDs to Course structs
    mapping(string => Course) public courses;
    
    // Mapping of assignment IDs to Assignment structs
    mapping(string => Assignment) public assignments;
    
    // Mapping to track if an address is an authorized academic evaluator
    mapping(address => bool) public academicEvaluators;
    
    // Mapping to track completed assignments by student
    mapping(address => mapping(string => bool)) public completedAssignments;
    
    // Events
    event CourseAdded(string courseId, string courseName, uint256 creditValue);
    event CourseUpdated(string courseId, string courseName, uint256 creditValue, bool isActive);
    event AssignmentAdded(string assignmentId, string courseId, uint256 maxCredits);
    event AssignmentUpdated(string assignmentId, string courseId, uint256 maxCredits, bool isActive);
    event EvaluatorAdded(address indexed evaluator);
    event EvaluatorRemoved(address indexed evaluator);
    event CreditsAwarded(address indexed student, string assignmentId, uint256 amount);
    event CourseCompleted(address indexed student, string courseId, uint256 amount);

    constructor(address tokenAddress) Ownable(msg.sender) {
        // Set the token contract address
        studentCreditToken = StudentCreditToken(tokenAddress);
        
        // Add contract deployer as an evaluator
        academicEvaluators[msg.sender] = true;
    }

    /**
     * @dev Modifier to restrict function access to academic evaluators
     */
    modifier onlyEvaluator() {
        require(academicEvaluators[msg.sender], "Not authorized as evaluator");
        _;
    }

    /**
     * @dev Add a new academic evaluator
     * @param evaluator Address of the evaluator to add
     */
    function addEvaluator(address evaluator) external onlyOwner {
        require(evaluator != address(0), "Invalid address");
        academicEvaluators[evaluator] = true;
        emit EvaluatorAdded(evaluator);
    }

    /**
     * @dev Remove an academic evaluator
     * @param evaluator Address of the evaluator to remove
     */
    function removeEvaluator(address evaluator) external onlyOwner {
        academicEvaluators[evaluator] = false;
        emit EvaluatorRemoved(evaluator);
    }

    /**
     * @dev Add a new course
     * @param courseId Unique identifier for the course
     * @param courseName Name of the course
     * @param creditValue Credit value for completing the course
     */
    function addCourse(string memory courseId, string memory courseName, uint256 creditValue) 
        external 
        onlyOwner 
        whenNotPaused 
    {
        require(bytes(courseId).length > 0, "Course ID cannot be empty");
        require(bytes(courseName).length > 0, "Course name cannot be empty");
        require(creditValue > 0, "Credit value must be greater than 0");
        require(bytes(courses[courseId].courseId).length == 0, "Course already exists");
        
        courses[courseId] = Course({
            courseId: courseId,
            courseName: courseName,
            creditValue: creditValue,
            isActive: true
        });
        
        emit CourseAdded(courseId, courseName, creditValue);
    }

    /**
     * @dev Update an existing course
     * @param courseId Unique identifier for the course
     * @param courseName New name of the course
     * @param creditValue New credit value for the course
     * @param isActive New active status for the course
     */
    function updateCourse(string memory courseId, string memory courseName, uint256 creditValue, bool isActive) 
        external 
        onlyOwner 
        whenNotPaused 
    {
        require(bytes(courseId).length > 0, "Course ID cannot be empty");
        require(bytes(courses[courseId].courseId).length > 0, "Course does not exist");
        
        Course storage course = courses[courseId];
        
        if (bytes(courseName).length > 0) {
            course.courseName = courseName;
        }
        
        if (creditValue > 0) {
            course.creditValue = creditValue;
        }
        
        course.isActive = isActive;
        
        emit CourseUpdated(courseId, course.courseName, course.creditValue, course.isActive);
    }

    /**
     * @dev Add a new assignment to a course
     * @param assignmentId Unique identifier for the assignment
     * @param courseId ID of the course this assignment belongs to
     * @param maxCredits Maximum credits that can be earned for this assignment
     */
    function addAssignment(string memory assignmentId, string memory courseId, uint256 maxCredits) 
        external 
        onlyOwner 
        whenNotPaused 
    {
        require(bytes(assignmentId).length > 0, "Assignment ID cannot be empty");
        require(bytes(courseId).length > 0, "Course ID cannot be empty");
        require(bytes(courses[courseId].courseId).length > 0, "Course does not exist");
        require(maxCredits > 0, "Max credits must be greater than 0");
        require(bytes(assignments[assignmentId].assignmentId).length == 0, "Assignment already exists");
        
        assignments[assignmentId] = Assignment({
            assignmentId: assignmentId,
            courseId: courseId,
            maxCredits: maxCredits,
            isActive: true
        });
        
        emit AssignmentAdded(assignmentId, courseId, maxCredits);
    }

    /**
     * @dev Update an existing assignment
     * @param assignmentId Unique identifier for the assignment
     * @param courseId New course ID for the assignment
     * @param maxCredits New maximum credits for the assignment
     * @param isActive New active status for the assignment
     */
    function updateAssignment(string memory assignmentId, string memory courseId, uint256 maxCredits, bool isActive) 
        external 
        onlyOwner 
        whenNotPaused 
    {
        require(bytes(assignmentId).length > 0, "Assignment ID cannot be empty");
        require(bytes(assignments[assignmentId].assignmentId).length > 0, "Assignment does not exist");
        
        Assignment storage assignment = assignments[assignmentId];
        
        if (bytes(courseId).length > 0 && bytes(courses[courseId].courseId).length > 0) {
            assignment.courseId = courseId;
        }
        
        if (maxCredits > 0) {
            assignment.maxCredits = maxCredits;
        }
        
        assignment.isActive = isActive;
        
        emit AssignmentUpdated(assignmentId, assignment.courseId, assignment.maxCredits, assignment.isActive);
    }

    /**
     * @dev Award credits to a student for completing an assignment
     * @param student Address of the student
     * @param assignmentId ID of the completed assignment
     * @param creditsEarned Number of credits earned (must be <= maxCredits)
     */
    function awardAssignmentCredits(address student, string memory assignmentId, uint256 creditsEarned) 
        external 
        onlyEvaluator 
        whenNotPaused 
    {
        require(student != address(0), "Invalid student address");
        require(bytes(assignmentId).length > 0, "Assignment ID cannot be empty");
        
        Assignment storage assignment = assignments[assignmentId];
        require(bytes(assignment.assignmentId).length > 0, "Assignment does not exist");
        require(assignment.isActive, "Assignment is not active");
        require(!completedAssignments[student][assignmentId], "Assignment already completed by student");
        require(creditsEarned <= assignment.maxCredits, "Credits exceed maximum allowed");
        
        // Mark assignment as completed
        completedAssignments[student][assignmentId] = true;
        
        // Award credits through the token contract
        studentCreditToken.mintCredits(student, creditsEarned, string(abi.encodePacked("Assignment: ", assignmentId)));
        
        emit CreditsAwarded(student, assignmentId, creditsEarned);
    }

    /**
     * @dev Award course completion credits to a student
     * @param student Address of the student
     * @param courseId ID of the completed course
     */
    function awardCourseCredits(address student, string memory courseId) 
        external 
        onlyEvaluator 
        whenNotPaused 
    {
        require(student != address(0), "Invalid student address");
        require(bytes(courseId).length > 0, "Course ID cannot be empty");
        
        Course storage course = courses[courseId];
        require(bytes(course.courseId).length > 0, "Course does not exist");
        require(course.isActive, "Course is not active");
        
        // Award course completion credits
        studentCreditToken.mintCredits(student, course.creditValue, string(abi.encodePacked("Course Completion: ", courseId)));
        
        emit CourseCompleted(student, courseId, course.creditValue);
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