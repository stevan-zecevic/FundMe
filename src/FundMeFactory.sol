// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {FundMe_AmountBased} from "contracts/FundMe_AmountBased.sol";
import {FundMe_TimeBased} from "contracts/FundMe_TimeBased.sol";

error FundMeFactory__IndexOutOfBounds();

contract FundMeFactory {
    address[] private s_fundations;

    /// @notice Creates a new fundation based on the given parameters
    /// @dev Only one type of fundation (time-based or amount-based) can be created per call
    /// @param _name The name of the fundation
    /// @param _description The description of the fundation
    /// @param _timeLimit The time limit for a time-based fundation (0 for amount-based)
    /// @param _goalAmount The goal amount for an amount-based fundation (0 for time-based), in USD
    /// @param _minimumFund The minimum fund amount, in USD
    /// @param _priceFeedAddress The address of the price feed contract
    /// @return fundationAddress The address of the newly created fundation

    function createFundation(
        bytes32 _name,
        bytes32 _description,
        uint256 _timeLimit,
        uint256 _goalAmount,
        uint256 _minimumFund,
        address _priceFeedAddress
    ) public returns (address) {
        address fundationAddress;

        if (_timeLimit != 0) {
            FundMe_TimeBased newFundation = new FundMe_TimeBased(
                _name,
                _description,
                _timeLimit,
                _minimumFund,
                _priceFeedAddress
            );

            s_fundations.push(address(newFundation));

            fundationAddress = address(newFundation);
        } else if (_goalAmount != 0) {
            FundMe_AmountBased newFundation = new FundMe_AmountBased(
                _name,
                _description,
                _goalAmount,
                _minimumFund,
                _priceFeedAddress
            );

            s_fundations.push(address(newFundation));

            fundationAddress = address(newFundation);
        }

        return fundationAddress;
    }

    /// @notice Retrieves the address of a fundation at a given index
    /// @dev Throws an error if the index is out of bounds
    /// @param _index The index of the fundation to retrieve
    /// @return The address of the fundation at the given index
    function getFundation(uint256 _index) public view returns (address) {
        if (_index >= getFundationCount()) {
            revert FundMeFactory__IndexOutOfBounds();
        }

        return s_fundations[_index];
    }

    /// @notice Retrieves the total number of fundations created
    /// @return The number of fundations
    function getFundationCount() public view returns (uint256) {
        return s_fundations.length;
    }
}
