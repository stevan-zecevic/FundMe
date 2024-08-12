// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {FundMe} from "contracts/FundMe.sol";
import {Ownable} from "contracts/Ownable.sol";
import {AutomationCompatibleInterface} from "chainlink-toolkit/lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

error FundMe_TimeBased__RetreiveError(uint256);
error FundMe_TimeBased__PerformUpkeepError(uint256, uint256, uint256, uint256);

contract FundMe_TimeBased is FundMe, Ownable {
    // time repesented in seconds
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

        (bool sent, ) = i_owner.call{value: contractBalance}("");

        if (!sent) {
            revert FundMe_TimeBased__RetreiveError(contractBalance);
        }

        setStatus(Status.Finished);
    }
}
