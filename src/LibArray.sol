// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

type Array is bytes32;

using LibArray for Array global;

/**
 * ------------------------------+
 * |          Memory             |
 * ------------------------------|
 * | Offset     | Array Length   |
 * | Offset + 32| Array maxSize  |
 * | Offset + 64| Array Elements |
 * ------------------------------|
 */

/// @notice Library for optimized dynamic arrays and operations for dynamic arrays.
/// @author whisskey (https://github.com/whisskey/sarl)
///
/// @dev Note:
/// Managing memory allocation, array length and capacity in dynamic arrays can significantly reduce gas consumption
/// and mitigate performance issues during array operations.

library LibArray {
    function create(uint256 maxSize) internal pure returns (Array fmp) {
        assembly ("memory-safe") {
            fmp := mload(0x40)

            mstore(0x40, add(fmp, mul(add(maxSize, 0x02), 0x20)))

            mstore(add(fmp, 0x20), maxSize)
        }
    }
}
