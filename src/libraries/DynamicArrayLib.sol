// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

type Array is bytes32;

using DynamicArrayLib for Array global;

/// @notice A library that provides a custom array structure mimicking dynamic array behavior in memory,
/// allowing optimized manipulation and dynamic resizing while minimizing gas consumption.
/// @author whisskey (https://github.com/whisskey/sarl)
///
/// +------------------------------------+
/// |               Memory               |
/// |------------------------------------|
/// | Offset      | Array Limit & Length |
/// | Offset + 32 |    Array Elements    |
/// +------------------------------------+
///
/// @dev Note: This custom array structure in memory is designed to mimic dynamic array behavior, overcoming Solidity's
/// memory array limitations. The first 128 bits store the array's length, while the remaining 128 bits store the
/// array's limit. The structure allows for optimized manipulation of arrays with operations,minimizing gas consumption
/// and ensuring dynamic resizing.
library DynamicArrayLib { }
