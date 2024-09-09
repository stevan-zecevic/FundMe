// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {FundMe, FundMe__RetreiveError} from "contracts/FundMe.sol";
import {Ownable} from "contracts/Ownable.sol";
import {AutomationCompatibleInterface} from "chainlink-toolkit/lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

error FundMe_TimeBased__PerformUpkeepError(uint256, uint256, uint256, uint256);

contract FundMe_TimeBased is FundMe, Ownable {
    //@dev: Time repesented in seconds
    uint256 private immutable i_timeLimit;
    uint256 private immutable i_timestamp;

    constructor(
        uint256 _timeLimit,
        uint256 _minimumFund,
        address _priceFeedAddress
    ) FundMe(_minimumFund, _priceFeedAddress) {
        i_timeLimit = _timeLimit;
        i_timestamp = block.timestamp;
    }

    receive() external payable override {
        fund();
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        returns (bool upkeepNeeded /* bytes memory  performData */)
    {
        upkeepNeeded = block.timestamp - i_timestamp >= i_timeLimit;
        return upkeepNeeded;
    }

    // @dev: collect the contract balance
    function performUpkeep(
        bytes calldata /* performData */
    ) public payable override onlyOwner {
        Status status = getStatus();

        if (
            (block.timestamp - i_timestamp < i_timeLimit) ||
            status == Status.Closed ||
            status == Status.Finished
        ) {
            revert FundMe_TimeBased__PerformUpkeepError(
                block.timestamp,
                i_timestamp,
                i_timeLimit,
                uint256(status)
            );
        }

        uint256 contractBalance = address(this).balance;

        (bool sent, ) = s_owner.call{value: contractBalance}("");

        if (!sent) {
            revert FundMe__RetreiveError(contractBalance);
        }

        emit FundMe__DonationsCollected(contractBalance);
        setStatus(Status.Finished);
    }

    function getTimeLimit() public view returns (uint256) {
        return i_timeLimit;
    }

    function getTimeStamp() public view returns (uint256) {
        return i_timestamp;
    }
}
