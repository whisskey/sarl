// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

type Array is bytes32;

using ArrayLib for Array global;

/// @notice Library for optimized dynamic arrays and operations for dynamic arrays.
/// @author whisskey (https://github.com/whisskey/sarl)
///
/// @dev Note: Managing memory allocation, array length and capacity in dynamic arrays can significantly reduce gas
/// consumption and mitigate performance issues during array operations.
library ArrayLib {
    /**
     *                     +-----------------------------+
     *                     |           Memory            |
     *                     |-----------------------------|
     *                     | Offset     | Array Length   |
     *                     | Offset + 32| Array Limit    |
     *                     | Offset + 64| Array Elements |
     *                     +-----------------------------+
     */

    /**
     * @dev Creates a new dynamic array with a specified maximum size using assembly.
     * @param lmt The maximum number of elements the array can hold.
     * @return arr The pointer to the newly created array in memory.
     */
    function create(uint256 lmt) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := mload(0x40)

            mstore(0x40, add(arr, mul(add(lmt, 0x02), 0x20)))

            mstore(add(arr, 0x20), lmt)
        }
    }

    function set(Array arr, uint256 index, uint256 value) internal pure {
        assembly ("memory-safe") {
            let len := mload(arr)
            let lmt := mload(add(arr, 0x20))

            if iszero(lt(index, lmt)) {
                mstore(0x00, 0x2238ba58) // IndexDoesNotExist()
                revert(0x1c, 0x04)
            }

            let elementPtr := add(arr, mul(add(index, 0x02), 0x20))

            if iszero(mload(elementPtr)) {
                if lt(len, add(index, 1)) {
                    // Uzunluğu sadece yeni bir eleman ekleniyorsa artır
                    mstore(arr, add(index, 1))
                }
            }

            mstore(elementPtr, value)
        }
    }

    function get(Array arr, uint256 index) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            if lt(mload(add(arr, 0x20)), index) {
                mstore(0x00, 0x2238ba58) // IndexDoesNotExist()

                revert(0x1c, 0x04)
            }

            result := mload(add(arr, mul(0x20, add(index, 0x02))))
        }
    }

    //function push(Array arr, uint256 elem) internal pure returns (Array arr) { }

    function pop(Array arr) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            let len := mload(arr)

            if iszero(len) {
                mstore(0x00, 0x521299a9) // EmptyArray()
                revert(0x1c, 0x04)
            }

            let last := add(arr, mul(0x20, add(len, 0x01)))

            result := mload(last)

            mstore(last, 0x00)

            mstore(arr, sub(len, 1))
        }
    }

    function length(Array arr) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            result := mload(arr)
        }
    }

    function limit(Array arr) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            result := mload(add(arr, 0x20))
        }
    }
}
