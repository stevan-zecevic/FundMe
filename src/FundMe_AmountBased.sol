// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {FundMe, FundMe__RetreiveError, FundMe__GoalAmountNotMet} from "contracts/FundMe.sol";

error FundMe_AmountBased__PerformUpkeepError(uint256, uint256, uint256);

contract FundMe_AmountBased is FundMe {
    /// @notice The goal amount in USD
    uint256 private immutable i_goalAmount;

    /// @notice Creates a new fundation based on the given parameters
    /// @param _name The name of the fundation
    /// @param _description The description of the fundation
    /// @param _goalAmount The goal amount for an amount-based fundation (0 for time-based), in USD
    /// @param _minimumFund The minimum fund amount, in USD
    /// @param _priceFeedAddress The address of the price feed contract
    constructor(
        bytes32 _name,
        bytes32 _description,
        uint256 _goalAmount,
        uint256 _minimumFund,
        address _priceFeedAddress
    ) FundMe(_name, _description, _minimumFund, _priceFeedAddress) {
        i_goalAmount = _goalAmount;
    }

    /// @notice Receives funds from funders
    /// @dev This function is called when eth is sent to the contract
    receive() external payable override {
        fund();
    }

    /// @notice Performs upkeep on the fundation and collects the funds
    /// @dev This function is called when owner wants to collect the funds
    function performUpkeep(
        bytes calldata /* performData */
    ) public payable override onlyOwner {
        Status status = getStatus();

        uint256 contractBalance = address(this).balance;
        uint256 contractBalanceInUSD = convertToUSD(contractBalance);

        if (
            (i_goalAmount != 0 && contractBalanceInUSD < i_goalAmount) ||
            status == Status.Closed ||
            status == Status.Finished
        ) {
            revert FundMe_AmountBased__PerformUpkeepError(
                uint256(status),
                contractBalanceInUSD,
                i_goalAmount
            );
        }

        (bool sent, ) = s_owner.call{value: contractBalance}("");

        if (!sent) {
            revert FundMe__RetreiveError(contractBalanceInUSD);
        }

        emit FundMe__DonationsCollected(contractBalanceInUSD);
        setStatus(Status.Finished);
    }

    /// @notice Retrieves the goal amount for the fundation
    /// @return The goal amount in USD
    function getGoalAmount() public view returns (uint256) {
        return i_goalAmount;
    }
}
