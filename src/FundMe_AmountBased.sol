// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {FundMe, FundMe__FundRequirementNotMet, FundMe__RetreiveError, FundMe__GoalAmountNotMet} from "contracts/FundMe.sol";
import {Ownable} from "contracts/Ownable.sol";

contract FundMe_AmountBased is FundMe, Ownable {
    uint256 private immutable i_goalAmount;

    constructor(
        uint256 _goalAmount,
        uint256 _minimumFund,
        address _priceFeedAddress
    ) FundMe(_minimumFund, _priceFeedAddress) {
        i_goalAmount = _goalAmount;
    }

    receive() external payable override {
        fund();
    }

    // @dev: collect the contract balance
    function performUpkeep(
        bytes calldata /* performData */
    ) public payable override onlyOwner {
        uint256 contractBalance = address(this).balance;

        if ((i_goalAmount != 0 && contractBalance < i_goalAmount)) {
            revert FundMe__GoalAmountNotMet(contractBalance, i_goalAmount);
        }

        (bool sent, ) = s_owner.call{value: contractBalance}("");

        if (!sent) {
            revert FundMe__RetreiveError(contractBalance);
        }

        emit FundMe__DonationsCollected(contractBalance);
        setStatus(Status.Finished);
    }

    function getGoalAmount() public view returns (uint256) {
        return i_goalAmount;
    }
}
