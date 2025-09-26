// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title WealthChain
 * @dev A decentralized wealth management and investment tracking platform
 * @author WealthChain Team
 */
contract WealthChain {
    
    // State variables
    address public owner;
    uint256 public totalInvestors;
    uint256 public totalInvestments;
    
    // Investment structure
    struct Investment {
        uint256 amount;
        uint256 timestamp;
        string investmentType;
        uint256 expectedReturn;
        bool isActive;
    }
    
    // Investor portfolio structure
    struct Portfolio {
        uint256 totalInvested;
        uint256 totalReturns;
        uint256 investmentCount;
        bool isRegistered;
    }
    
    // Mappings
    mapping(address => Portfolio) public portfolios;
    mapping(address => Investment[]) public investorInvestments;
    mapping(string => uint256) public investmentTypeCount;
    
    // Events
    event InvestorRegistered(address indexed investor, uint256 timestamp);
    event InvestmentMade(
        address indexed investor, 
        uint256 amount, 
        string investmentType, 
        uint256 expectedReturn,
        uint256 timestamp
    );
    event ReturnsDistributed(address indexed investor, uint256 amount, uint256 timestamp);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyRegisteredInvestor() {
        require(portfolios[msg.sender].isRegistered, "Investor not registered");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        totalInvestors = 0;
        totalInvestments = 0;
    }
    
    /**
     * @dev Core Function 1: Register as an investor on the platform
     * Allows users to register and create their investment portfolio
     */
    function registerInvestor() external {
        require(!portfolios[msg.sender].isRegistered, "Investor already registered");
        
        portfolios[msg.sender] = Portfolio({
            totalInvested: 0,
            totalReturns: 0,
            investmentCount: 0,
            isRegistered: true
        });
        
        totalInvestors++;
        
        emit InvestorRegistered(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Core Function 2: Make an investment
     * @param _investmentType Type of investment (e.g., "Stocks", "Crypto", "Bonds")
     * @param _expectedReturn Expected return percentage (in basis points, e.g., 1000 = 10%)
     * Allows registered investors to record their investments
     */
    function makeInvestment(
        string memory _investmentType, 
        uint256 _expectedReturn
    ) external payable onlyRegisteredInvestor {
        require(msg.value > 0, "Investment amount must be greater than 0");
        require(_expectedReturn > 0, "Expected return must be greater than 0");
        
        // Create new investment
        Investment memory newInvestment = Investment({
            amount: msg.value,
            timestamp: block.timestamp,
            investmentType: _investmentType,
            expectedReturn: _expectedReturn,
            isActive: true
        });
        
        // Add to investor's investments
        investorInvestments[msg.sender].push(newInvestment);
        
        // Update portfolio
        portfolios[msg.sender].totalInvested += msg.value;
        portfolios[msg.sender].investmentCount++;
        
        // Update global stats
        totalInvestments++;
        investmentTypeCount[_investmentType]++;
        
        emit InvestmentMade(
            msg.sender, 
            msg.value, 
            _investmentType, 
            _expectedReturn, 
            block.timestamp
        );
    }
    
    /**
     * @dev Core Function 3: Distribute returns to investors
     * @param _investor Address of the investor
     * @param _investmentIndex Index of the specific investment
     * @param _returnAmount Amount of returns to distribute
     * Allows owner to distribute returns based on investment performance
     */
    function distributeReturns(
        address _investor, 
        uint256 _investmentIndex, 
        uint256 _returnAmount
    ) external onlyOwner {
        require(portfolios[_investor].isRegistered, "Investor not registered");
        require(
            _investmentIndex < investorInvestments[_investor].length, 
            "Invalid investment index"
        );
        require(
            investorInvestments[_investor][_investmentIndex].isActive, 
            "Investment not active"
        );
        require(_returnAmount > 0, "Return amount must be greater than 0");
        require(address(this).balance >= _returnAmount, "Insufficient contract balance");
        
        // Update portfolio returns
        portfolios[_investor].totalReturns += _returnAmount;
        
        // Transfer returns to investor
        payable(_investor).transfer(_returnAmount);
        
        emit ReturnsDistributed(_investor, _returnAmount, block.timestamp);
    }
    
    // View functions
    function getInvestorPortfolio(address _investor) external view returns (
        uint256 totalInvested,
        uint256 totalReturns,
        uint256 investmentCount,
        bool isRegistered
    ) {
        Portfolio memory portfolio = portfolios[_investor];
        return (
            portfolio.totalInvested,
            portfolio.totalReturns,
            portfolio.investmentCount,
            portfolio.isRegistered
        );
    }
    
    function getInvestmentDetails(address _investor, uint256 _index) external view returns (
        uint256 amount,
        uint256 timestamp,
        string memory investmentType,
        uint256 expectedReturn,
        bool isActive
    ) {
        require(_index < investorInvestments[_investor].length, "Invalid investment index");
        Investment memory investment = investorInvestments[_investor][_index];
        return (
            investment.amount,
            investment.timestamp,
            investment.investmentType,
            investment.expectedReturn,
            investment.isActive
        );
    }
    
    function getContractStats() external view returns (
        uint256 _totalInvestors,
        uint256 _totalInvestments,
        uint256 contractBalance
    ) {
        return (totalInvestors, totalInvestments, address(this).balance);
    }
    
    // Emergency functions
    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    // Fallback function to receive Ether
    receive() external payable {}
}
