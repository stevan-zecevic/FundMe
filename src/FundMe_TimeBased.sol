// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {FundMe, FundMe__RetreiveError} from "contracts/FundMe.sol";
import {AutomationCompatibleInterface} from "chainlink-toolkit/lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

error FundMe_TimeBased__PerformUpkeepError(uint256, uint256, uint256, uint256);

contract FundMe_TimeBased is FundMe {
    /// @notice The time limit for the fundation, in seconds
    /// @notice The timestamp when the fundation started, in seconds
    uint256 private immutable i_timeLimit;
    uint256 private immutable i_timestamp;

    /// @notice Creates a new fundation based on the given parameters
    /// @param _name The name of the fundation
    /// @param _description The description of the fundation
    /// @param _timeLimit The time limit for the fundation, in seconds
    /// @param _minimumFund The minimum fund amount, in USD
    /// @param _priceFeedAddress The address of the price feed contract
    constructor(
        bytes32 _name,
        bytes32 _description,
        uint256 _timeLimit,
        uint256 _minimumFund,
        address _priceFeedAddress
    ) FundMe(_name, _description, _minimumFund, _priceFeedAddress) {
        i_timeLimit = _timeLimit;
        i_timestamp = block.timestamp;
    }

    /// @notice Receives funds from funders
    /// @dev This function is called when eth is sent to the contract
    receive() external payable override {
        fund();
    }

    /// @notice Checks if the fundation is ready to be collected
    /// @return upkeepNeeded Whether the fundation is ready to be collected
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

    /// @notice Performs upkeep on the fundation and collects the funds
    /// @dev This function is called when time limit is reached
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
        uint256 contractBalanceInUSD = convertToUSD(contractBalance);

        (bool sent, ) = s_owner.call{value: contractBalance}("");

        if (!sent) {
            revert FundMe__RetreiveError(contractBalanceInUSD);
        }

        emit FundMe__DonationsCollected(contractBalanceInUSD);
        setStatus(Status.Finished);
    }

    function getTimeLimit() public view returns (uint256) {
        return i_timeLimit;
    }

    function getTimeStamp() public view returns (uint256) {
        return i_timestamp;
    }
}
