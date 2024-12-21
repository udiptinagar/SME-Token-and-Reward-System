// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SME_Token {
    // ERC-20 Token Details
    string public name = "SME Token";
    string public symbol = "SME";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply; // Assign all tokens to contract deployer
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}

contract SME_RewardSystem {
    SME_Token public token;
    address public owner;

    mapping(address => uint256) public userRewards;

    event RewardIssued(address indexed to, uint256 amount);
    event ContentSubmitted(address indexed creator, uint256 indexed contentId);
    event ValidationCompleted(address indexed validator, uint256 indexed contentId, bool isApproved);

    uint256 public contentCounter;
    struct Content {
        address creator;
        uint256 rewardPool;
        bool isValidated;
    }
    
    mapping(uint256 => Content) public contentRegistry;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(SME_Token _token) {
        token = _token;
        owner = msg.sender;
    }

    function submitContent(uint256 rewardAmount) external {
        require(token.transferFrom(msg.sender, address(this), rewardAmount), "Token transfer failed");

        contentCounter++;
        contentRegistry[contentCounter] = Content({
            creator: msg.sender,
            rewardPool: rewardAmount,
            isValidated: false
        });

        emit ContentSubmitted(msg.sender, contentCounter);
    }

    function validateContent(uint256 contentId, bool isApproved) external onlyOwner {
        Content storage content = contentRegistry[contentId];
        require(!content.isValidated, "Content already validated");

        content.isValidated = true;

        if (isApproved) {
            require(token.transfer(content.creator, content.rewardPool), "Reward transfer failed");
        }

        emit ValidationCompleted(msg.sender, contentId, isApproved);
    }

    function issueReward(address to, uint256 amount) external onlyOwner {
        require(token.transfer(to, amount), "Reward transfer failed");
        userRewards[to] += amount;
        emit RewardIssued(to, amount);
    }
}
