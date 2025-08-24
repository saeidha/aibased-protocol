// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Loanly
 * @dev A simple smart contract for peer-to-peer lending with interest.
 */
contract Loanly {
    // A structure to hold the details of each loan.
    struct Loan {
        uint256 id;
        address payable borrower;
        address payable lender;
        uint256 amount;
        uint256 interest; // Basis points, e.g., 500 for 5%
        uint256 duration; // in seconds
        uint256 startTime;
        bool funded;
        bool repaid;
    }
    // A mapping from loan IDs to Loan structs.
    mapping(uint256 => Loan) public loans;
    // A counter to ensure unique loan IDs.
    uint256 public loanCounter;

    // Events to log significant actions.
    event LoanRequested(uint256 indexed id, address indexed borrower, uint256 amount, uint256 interest);
    event LoanFunded(uint256 indexed id, address indexed lender, uint256 amount);
    event LoanRepaid(uint256 indexed id, uint256 totalAmount);

 /**
     * @dev Requests a new loan.
     * @param _amount The principal amount of the loan.
     * @param _interest The interest rate in basis points (e.g., 500 for 5%).
     * @param _duration The duration of the loan in seconds.
     */
    function requestLoan(uint256 _amount, uint256 _interest, uint256 _duration) public {
        require(_amount > 0, "Loan amount must be greater than zero");
        require(_interest > 0, "Interest rate must be greater than zero");
        require(_duration > 0, "Loan duration must be greater than zero");

        loanCounter++;
        loans[loanCounter] = Loan({
            id: loanCounter,
            borrower: payable(msg.sender),
            lender: payable(address(0)),
            amount: _amount,
            interest: _interest,
            duration: _duration,
            startTime: 0,
            funded: false,
            repaid: false
        });

        emit LoanRequested(loanCounter, msg.sender, _amount, _interest);
    }

    /**
     * @dev Funds an existing loan request.
     * @param _id The ID of the loan to fund.
     */

    function fundLoan(uint256 _id) public payable {
        Loan storage loan = loans[_id];
        
        require(loan.id != 0, "Loan does not exist");
        require(!loan.funded, "Loan is already funded");
        require(msg.value == loan.amount, "Incorrect funding amount sent");
        require(msg.sender != loan.borrower, "Cannot fund your own loan");


        loan.lender = payable(msg.sender);
        loan.funded = true;
        loan.startTime = block.timestamp;

        emit LoanFunded(_id, msg.sender, loan.amount);
        }

    /**
     * @dev Repays a funded loan.
     * @param _id The ID of the loan to repay.
     */
    function repayLoan(uint256 _id) public payable {
        Loan storage loan = loans[_id];
        require(loan.funded, "Loan is not funded");
        require(!loan.repaid, "Loan has already been repaid");
        require(msg.sender == loan.borrower, "Only the borrower can repay the loan");

        uint256 interestAmount = calculateInterest(_id);
        uint256 totalAmount = loan.amount + interestAmount;
        require(msg.value == totalAmount, "Incorrect repayment amount");
        loan.repaid = true;
        loan.lender.transfer(totalAmount);

        emit LoanRepaid(_id, totalAmount);
    }

    /**
     * @dev Calculates the interest for a loan.
     * @param _id The ID of the loan.
     * @return The calculated interest amount.
     */
    function calculateInterest(uint256 _id) public view returns (uint256) {
        Loan storage loan = loans[_id];
        if (!loan.funded) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - loan.startTime;
        return (loan.amount * loan.interest * timeElapsed) / (10000 * loan.duration);
    }
    /**
     * @dev Retrieves the details of a specific loan.
     * @param _id The ID of the loan.
     * @return All the loan's details.
     */
    function getLoanDetails(uint256 _id) public view returns (uint256, address, address, uint256, uint256, uint256, uint256, bool, bool) {
        Loan storage loan = loans[_id];
        return (loan.id, loan.borrower, loan.lender, loan.amount, loan.interest, loan.duration, loan.startTime, loan.funded, loan.repaid);
    }

     /**
     * @dev Allows the lender to withdraw their funds if the loan is repaid.
     * @param _id The ID of the loan to withdraw from.
     */

    function withdraw(uint256 _id) public {
        Loan storage loan = loans[_id];
        require(loan.repaid, "Loan not repaid yet");
        require(msg.sender == loan.lender, "Only lender can withdraw");
        uint256 amountToWithdraw = loan.amount + calculateInterest(_id);
        (bool success, ) = loan.lender.call{value: amountToWithdraw}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev A simple function to get the current timestamp of the blockchain.
     * @return The current block timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev A simple check to see if a loan is funded.
     * @param _id The ID of the loan.
     * @return A boolean indicating if the loan is funded.
     */
    function isLoanFunded(uint256 _id) public view returns (bool) {
        return loans[_id].funded;
    }

    /**
     * @dev A simple check to see if a loan is repaid.
     * @param _id The ID of the loan.
     * @return A boolean indicating if the loan is repaid.
     */
    function isLoanRepaid(uint256 _id) public view returns (bool) {
        return loans[_id].repaid;
    }

    /**
     * @dev Gets the total number of loans created.
     * @return The total loan count.
     */