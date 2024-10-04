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
library DynamicArrayLib {
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/
    /*                          CONSTANTS                           */
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/

    uint256 internal constant MASK_128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/
    /*                        CUSTOM  ERRORS                        */
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/

    /// @notice The index does not exist.
    error IndexDoesNotExist();
    /// @notice The array is empty.
    error EmptyArray();
    /// @notice Thrown when an index is out of bounds.
    error OutOfBounds();
    /// @notice Thrown when the provided bounds are invalid.
    error InvalidBounds();

    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/
    /*                      LIBRARY OPERATIONS                      */
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/

    ///@dev Creates a new dynamic array with a specified maximum size using assembly.
    ///@param lmt The maximum number of elements the array can hold.
    /// @return arr The pointer to the newly created array in memory.
    function create(uint128 lmt) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := mload(0x40)
            // Store the array limit
            mstore(arr, shl(128, lmt))
            // Allocate memory for the array
            mstore(0x40, add(arr, shl(5, add(lmt, 1))))
        }
    }

    /// @dev Returns the length of the array.
    /// @param a The pointer to the array in memory.
    /// @return result The length of the array.
    function length(Array a) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            result := and(mload(a), MASK_128)
        }
    }

    /// @dev Retrieves the maximum number of elements the array can hold.
    /// @param a The pointer to the array in memory.
    /// @return result The maximum number of elements that the array can hold.
    function limit(Array a) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            result := shr(128, mload(a))
        }
    }

    /// @dev Resets all elements of the array to zero.
    /// @param a The pointer to the array in memory.
    function reset(Array a) internal pure {
        assembly ("memory-safe") {
            // Use codecopy to reset the array
            codecopy(add(a, 0x20), codesize(), shl(5, and(mload(a), MASK_128)))
        }
    }

    /// @dev Computes the Keccak-256 hash of the elements in the array.
    /// @param a The pointer to the array in memory.
    /// @return result The Keccak-256 hash of the array's elements.
    function hash(Array a) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            // keccak256(a, length /// 32)
            result := keccak256(add(a, 0x20), shl(5, and(mload(a), MASK_128)))
        }
    }

    /// @notice This function allocates memory for the array and sets the limit field. The length is not modified
    /// directly and should be updated separately when elements are added.
    /// @dev Allocates memory for an `Array` structure with the given number of elements `n`.
    /// @param n The number of elements to allocate memory for (this defines the array's limit).
    /// @return result A pointer to the newly allocated `Array` structure in memory.
    function malloc(uint256 n) internal pure returns (Array result) {
        assembly ("memory-safe") {
            result := mload(0x40)
            // Store the array limit
            mstore(result, shl(128, n))
            // Space allocated for the array
            mstore(0x40, add(result, shl(5, add(n, 1))))
        }
    }

    /// @dev Allocates memory for an `Array` structure with the given number of elements `n`,
    /// and initializes all elements to zero. The function sets both the length and limit of the array.
    /// @param n The number of elements to allocate and initialize memory for.
    /// @return result A pointer to the newly allocated and zero-initialized `Array` structure in memory.
    function calloc(uint256 n) internal pure returns (Array result) {
        assembly ("memory-safe") {
            result := mload(0x40)
            // Update length and limit
            mstore(result, or(shl(128, n), n))
            // Initialize array elements to zero
            codecopy(add(result, 0x20), codesize(), shl(5, and(mload(result), MASK_128)))
            // Space allocated for the array
            mstore(0x40, add(result, shl(5, add(n, 1))))
        }
    }

    /// @notice This function reallocates memory for the array's limit, expanding or shrinking as needed.
    /// If the new limit is smaller than the current limit, the function may also shrink the length.
    /// If the new limit is larger, the function allocates new memory and copies the existing array data.
    /// @dev Resizes the limit of the `Array` structure, either expanding or shrinking it.
    /// @param a The original `Array` that is to be resized.
    /// @param newLmt The new limit (capacity) for the array.
    /// @return arr The resized `Array` with the updated limit.
    function realloc(Array a, uint256 newLmt) internal view returns (Array arr) {
        assembly ("memory-safe") {
            arr := a
            let data := mload(a)
            // First 128 bits: length
            let n := and(data, MASK_128)
            // Last 128 bits: limit
            let lmt := shr(128, data)
            // Size
            let s := add(shl(5, lmt), 0x20)
            let fmp := mload(0x40)
            // Is the new limit smaller than the current limit?
            switch lt(newLmt, lmt)
            case 1 {
                // If the length exceeds the new limit, reduce the length
                switch gt(n, newLmt)
                case 1 {
                    // Update the length
                    mstore(a, or(shl(128, newLmt), newLmt))
                }
                default {
                    // Reduce the limit
                    mstore(a, or(shl(128, newLmt), n))
                }
            }
            default {
                // Check if the memory pointer is equal to the end of the preallocated area
                switch eq(fmp, add(a, s))
                case 1 {
                    // Update the limit
                    mstore(a, or(shl(128, newLmt), n))
                    // Shift the memory pointer
                    mstore(0x40, add(fmp, shl(5, sub(newLmt, lmt))))
                }
                default {
                    // Move using memory precompile
                    pop(
                        staticcall(
                            gas(),
                            0x04, // Use `identity` precompile for the move
                            a,
                            s,
                            fmp,
                            s
                        )
                    )
                    mstore(fmp, or(shl(128, newLmt), n))
                    arr := fmp
                    mstore(0x40, add(add(fmp, s), shl(5, sub(newLmt, lmt))))
                }
            }
        }
    }

    /// @dev Sets the value at a specified index in the array.
    /// @param a The pointer to the array in memory.
    /// @param i The index at which to set the value.
    /// @param e The value to set at the specified index.
    function set(Array a, uint256 i, uint256 e) internal pure {
        assembly ("memory-safe") {
            let data := mload(a)
            // First 128 bits: length
            let n := and(data, MASK_128)
            // Last 128 bits: limit
            let lmt := shr(128, data)
            if iszero(lt(i, lmt)) {
                mstore(0x00, 0x2238ba58) // IndexDoesNotExist()
                revert(0x1c, 0x04)
            }
            // Calculate the index pointer.
            let t := add(a, shl(5, add(0x01, i)))
            if iszero(mload(t)) {
                if lt(n, add(i, 1)) {
                    // Update the length
                    mstore(a, or(shl(128, lmt), add(i, 1)))
                }
            }
            mstore(t, e)
        }
    }

    /// @dev Sets the value at a specified index in the array.
    /// @param a The pointer to the array in memory.
    /// @param i The index at which to set the value.
    /// @param e The value to set at the specified index.
    function set(Array a, uint256 i, address e) internal pure {
        assembly ("memory-safe") {
            let data := mload(a)
            let n := and(data, MASK_128)
            let lmt := shr(128, data)
            if iszero(lt(i, lmt)) {
                mstore(0x00, 0x2238ba58) // IndexDoesNotExist()
                revert(0x1c, 0x04)
            }
            // Calculate the index pointer.
            let t := add(a, shl(5, add(0x01, i)))
            if iszero(mload(t)) {
                if lt(n, add(i, 1)) {
                    // Update the length
                    mstore(a, or(shl(128, lmt), add(i, 1)))
                }
            }
            mstore(t, shr(96, shl(96, e)))
        }
    }

    /// @dev Sets the value at a specified index in the array.
    /// @param a The pointer to the array in memory.
    /// @param i The index at which to set the value.
    /// @param e The value to set at the specified index.
    function set(Array a, uint256 i, bool e) internal pure {
        assembly ("memory-safe") {
            let data := mload(a)
            let n := and(data, MASK_128)
            let lmt := shr(128, data)
            if iszero(lt(i, lmt)) {
                mstore(0x00, 0x2238ba58) // IndexDoesNotExist()
                revert(0x1c, 0x04)
            }
            // Calculate the index pointer.
            let t := add(a, shl(5, add(0x01, i)))
            if iszero(mload(t)) {
                if lt(n, add(i, 1)) {
                    // Update the length
                    mstore(a, or(shl(128, lmt), add(i, 1)))
                }
            }
            mstore(t, iszero(iszero(e)))
        }
    }

    /// @dev Sets the value at a specified index in the array.
    /// @param a The pointer to the array in memory.
    /// @param i The index at which to set the value.
    /// @param e The value to set at the specified index.
    function set(Array a, uint256 i, bytes32 e) internal pure {
        assembly ("memory-safe") {
            let data := mload(a)
            let n := and(data, MASK_128)
            let lmt := shr(128, data)
            if iszero(lt(i, lmt)) {
                mstore(0x00, 0x2238ba58) // IndexDoesNotExist()
                revert(0x1c, 0x04)
            }
            // Calculate the index pointer.
            let t := add(a, shl(5, add(0x01, i)))
            if iszero(mload(t)) {
                if lt(n, add(i, 1)) {
                    // Update the length
                    mstore(a, or(shl(128, lmt), add(i, 1)))
                }
            }
            mstore(t, e)
        }
    }

    /// @dev Retrieves the value at a specified index from the array.
    /// @param a The pointer to the array in memory.
    /// @param i The index of the value to retrieve.
    /// @return result The value at the specified index.
    function get(Array a, uint256 i) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            let n := and(mload(a), MASK_128)
            if iszero(lt(i, n)) {
                mstore(0x00, 0x2238ba58) //  IndexDoesNotExist()
                revert(0x1c, 0x04)
            }
            result := mload(add(a, shl(5, add(0x01, i))))
        }
    }

    /// @dev Retrieves the 256-bit unsigned integer value at a specified index from the array.
    /// @param a The pointer to the array in memory.
    /// @param i The index of the value to retrieve.
    /// @return result The 256-bit unsigned integer value at the specified index.
    function getUint256(Array a, uint256 i) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            let n := and(mload(a), MASK_128)
            if iszero(lt(i, n)) {
                mstore(0x00, 0x2238ba58) //  IndexDoesNotExist()
                revert(0x1c, 0x04)
            }
            result := mload(add(a, shl(5, add(0x01, i))))
        }
    }

    /// @dev Retrieves the address at a specified index from the array.
    /// @param a The pointer to the array in memory.
    /// @param i The index of the address to retrieve.
    /// @return result the address at the specified index.
    function getAddress(Array a, uint256 i) internal pure returns (address result) {
        assembly ("memory-safe") {
            let n := and(mload(a), MASK_128)
            if iszero(lt(i, n)) {
                mstore(0x00, 0x2238ba58) //  IndexDoesNotExist()
                revert(0x1c, 0x04)
            }
            result := mload(add(a, shl(5, add(0x01, i))))
        }
    }

    /// @dev Retrieves the boolean value at a specified index from the array.
    /// @param a The pointer to the array in memory.
    /// @param i The index of the boolean value to retrieve.
    /// @return result The boolean value at the specified index.
    function getBool(Array a, uint256 i) internal pure returns (bool result) {
        assembly ("memory-safe") {
            let n := and(mload(a), MASK_128)
            if iszero(lt(i, n)) {
                mstore(0x00, 0x2238ba58) //  IndexDoesNotExist()
                revert(0x1c, 0x04)
            }
            result := mload(add(a, shl(5, add(0x01, i))))
        }
    }

    /// @dev Retrieves the `bytes32` value at a specified index from the array.
    /// @param a The pointer to the array in memory.
    /// @param i The index of the `bytes32` value to retrieve.
    /// @return result The `bytes32` value at the specified index.
    function getBytes32(Array a, uint256 i) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            let n := and(mload(a), MASK_128)
            if iszero(lt(i, n)) {
                mstore(0x00, 0x2238ba58) //  IndexDoesNotExist()
                revert(0x1c, 0x04)
            }
            result := mload(add(a, shl(5, add(0x01, i))))
        }
    }

    /// @dev Removes and returns the last value from the array.
    /// @param a The pointer to the array in memory.
    /// @return result The value that was removed from the end of the array.
    function pop(Array a) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            let data := mload(a)
            // First 128 bits: length
            let n := and(data, MASK_128)
            if iszero(n) {
                mstore(0x00, 0x521299a9) // EmptyArray()
                revert(0x1c, 0x04)
            }
            let ep := add(a, shl(5, n))
            result := mload(ep)
            mstore(ep, 0x00)
            // Update the length of the array
            mstore(a, or(shl(128, shr(128, data)), sub(n, 1)))
        }
    }

    /// @dev Removes and returns the last `uint256` value from the array.
    /// @param a The pointer to the array in memory.
    /// @return result The `uint256` value that was removed from the end of the array.
    function popUint256(Array a) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            let data := mload(a)
            // First 128 bits: length
            let n := and(data, MASK_128)
            if iszero(n) {
                mstore(0x00, 0x521299a9) // EmptyArray()
                revert(0x1c, 0x04)
            }
            let ep := add(a, shl(5, n))
            result := mload(ep)
            mstore(ep, 0x00)
            // Update the length of the array
            mstore(a, or(shl(128, shr(128, data)), sub(n, 1)))
        }
    }

    /// @dev Removes and returns the last `address` value from the array.
    /// @param a The pointer to the array in memory.
    /// @return result The `address` value that was removed from the end of the array.
    function popAddress(Array a) internal pure returns (address result) {
        assembly ("memory-safe") {
            let data := mload(a)
            // First 128 bits: length
            let n := and(data, MASK_128)
            if iszero(n) {
                mstore(0x00, 0x521299a9) // EmptyArray()
                revert(0x1c, 0x04)
            }
            let ep := add(a, shl(5, n))
            result := mload(ep)
            mstore(ep, 0x00)
            // Update the length of the array
            mstore(a, or(shl(128, shr(128, data)), sub(n, 1)))
        }
    }

    /// @dev Removes and returns the last `bool` value from the array.
    /// @param a The pointer to the array in memory.
    /// @return result The `bool` value that was removed from the end of the array.
    function popBool(Array a) internal pure returns (bool result) {
        assembly ("memory-safe") {
            let data := mload(a)
            // First 128 bits: length
            let n := and(data, MASK_128)
            if iszero(n) {
                mstore(0x00, 0x521299a9) // EmptyArray()
                revert(0x1c, 0x04)
            }
            let ep := add(a, shl(5, n))
            result := mload(ep)
            mstore(ep, 0x00)
            // Update the length of the array
            mstore(a, or(shl(128, shr(128, data)), sub(n, 1)))
        }
    }

    /// @dev Removes and returns the last `bytes32` value from the array.
    /// @param a The pointer to the array in memory.
    /// @return result The `bytes32` value that was removed from the end of the array.
    function popBytes32(Array a) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            let data := mload(a)
            // First 128 bits: length
            let n := and(data, MASK_128)
            if iszero(n) {
                mstore(0x00, 0x521299a9) // EmptyArray()
                revert(0x1c, 0x04)
            }
            let ep := add(a, shl(5, n))
            result := mload(ep)
            mstore(ep, 0x00)
            // Update the length of the array
            mstore(a, or(shl(128, shr(128, data)), sub(n, 1)))
        }
    }

    /// @dev Adds a new element to the end of the array, potentially expanding the array if needed.
    /// @param a The pointer to the array in memory.
    /// @param e The value to push to the end of the array.
    /// @param ovr The number of additional slots to allocate if the array needs to be expanded.
    /// @return arr The pointer to the updated array in memory.
    function push(Array a, uint256 e, uint256 ovr) internal view returns (Array arr) {
        assembly ("memory-safe") {
            arr := a
            let data := mload(a)
            // First 128 bits: length
            let n := and(data, MASK_128)
            // Last 128 bits: limit
            let lmt := shr(128, data)
            let fmp := mload(0x40)
            // Calculate the address of the last element
            let s := add(shl(5, n), 0x20)
            // Check if the capacity is full (length == limit)
            switch eq(n, lmt)
            case 1 {
                // Check if the free memory pointer is equal to the end of the preallocated space
                switch eq(fmp, add(a, s))
                case 1 {
                    // Update length and limit
                    mstore(a, or(shl(128, add(lmt, 0x01)), add(n, 0x01)))
                    mstore(fmp, e)
                    // Move the free memory pointer forward by one word (32 bytes)
                    mstore(0x40, add(fmp, 0x20))
                }
                default {
                    // Use identity precompile to move the existing elements
                    pop(
                        staticcall(
                            gas(),
                            0x04, // `identity` precompile
                            a,
                            s,
                            fmp,
                            s
                        )
                    )
                    // Make space for the new element and add it
                    mstore(add(fmp, s), e)
                    // Update length and limit
                    mstore(fmp, or(shl(128, add(lmt, add(0x01, ovr))), add(n, 0x01)))
                    arr := fmp
                    mstore(0x40, add(add(fmp, s), add(0x20, shl(5, ovr))))
                }
            }
            default {
                // If there is capacity, add the new element
                mstore(add(a, s), e)
                mstore(a, or(shl(128, lmt), add(n, 0x01)))
            }
        }
    }

    /// @dev Adds a new element to the end of the array.
    /// @param a The pointer to the array in memory.
    /// @param e The value to push to the end of the array.
    /// @return arr The pointer to the updated array in memory.
    function push(Array a, uint256 e) internal view returns (Array arr) {
        arr = push(a, uint256(e), 0);
    }

    /// @dev Adds a new address element to the end of the array.
    /// @param a The pointer to the array in memory.
    /// @param e The address to push to the end of the array.
    /// @return arr The pointer to the updated array in memory.
    function push(Array a, address e) internal view returns (Array arr) {
        arr = push(a, uint256(uint160(e)), 0);
    }

    /// @dev Adds a new boolean element to the end of the array.
    /// @param a The pointer to the array in memory.
    /// @param e The boolean value to push to the end of the array.
    /// @return arr The pointer to the updated array in memory.
    function push(Array a, bool e) internal view returns (Array arr) {
        uint256 result;

        assembly {
            result := iszero(iszero(e))
        }

        arr = push(a, result, 0);
    }

    /// @dev Adds a new `bytes32` element to the end of the array.
    /// @param a The pointer to the array in memory.
    /// @param e The `bytes32` value to push to the end of the array.
    /// @return arr The pointer to the updated array in memory.
    function push(Array a, bytes32 e) internal view returns (Array arr) {
        arr = push(a, uint256(e), 0);
    }

    /// @dev Copies all elements from the custom array to a new dynamically allocated `uint256[]` array.
    /// @param a The pointer to the array in memory.
    /// @return result A new `uint256[]` array containing all elements from the original array.
    function getAll(Array a) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := mload(0x40)
            let n := and(mload(a), MASK_128)
            // Calculate the byte size of the length
            let bytesN := shl(5, n)
            mstore(result, n)
            // Word mask
            let w := not(0x1f)
            for { let o := bytesN } 1 { } {
                if iszero(o) { break }
                // Copy word from the original array to the result array
                mstore(add(result, o), mload(add(a, o)))
                o := add(o, w) // Move to the next word
            }
            mstore(0x40, add(result, add(bytesN, 0x20)))
        }
    }

    /// @dev Copies all elements from the custom array to a new dynamically allocated `uint256[]` array.
    /// @param a The pointer to the array in memory.
    /// @return result A new `uint256[]` array containing all elements from the original array.
    function getUint256All(Array a) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := mload(0x40)
            let n := and(mload(a), MASK_128)
            // Calculate the byte size of the length
            let bytesN := shl(5, n)
            mstore(result, n)
            // Word mask
            let w := not(0x1f)
            for { let o := bytesN } 1 { } {
                if iszero(o) { break }
                // Copy word from the original array to the result array
                mstore(add(result, o), mload(add(a, o)))
                o := add(o, w) // Move to the next word
            }
            mstore(0x40, add(result, add(bytesN, 0x20)))
        }
    }

    /// @dev Retrieves all `address` elements from the array and returns them as a dynamic array.
    /// @param a The pointer to the array in memory.
    /// @return result The dynamic array of `address` elements.
    function getAddressAll(Array a) internal pure returns (address[] memory result) {
        assembly ("memory-safe") {
            result := mload(0x40)
            let n := and(mload(a), MASK_128)
            // Calculate the byte size of the length
            let bytesN := shl(5, n)
            mstore(result, n)
            // Word mask
            let w := not(0x1f)
            for { let o := bytesN } 1 { } {
                if iszero(o) { break }
                // Copy word from the original array to the result array
                mstore(add(result, o), mload(add(a, o)))
                o := add(o, w) // Move to the next word
            }
            mstore(0x40, add(result, add(bytesN, 0x20)))
        }
    }

    /// @dev Retrieves all `bool` elements from the array and returns them as a dynamic array.
    /// @param a The pointer to the array in memory.
    /// @return result The dynamic array of `bool` elements.
    function getBoolAll(Array a) internal pure returns (bool[] memory result) {
        assembly ("memory-safe") {
            result := mload(0x40)
            let n := and(mload(a), MASK_128)
            // Calculate the byte size of the length
            let bytesN := shl(5, n)
            mstore(result, n)
            // Word mask
            let w := not(0x1f)
            for { let o := bytesN } 1 { } {
                if iszero(o) { break }
                // Copy word from the original array to the result array
                mstore(add(result, o), mload(add(a, o)))
                o := add(o, w) // Move to the next word
            }
            mstore(0x40, add(result, add(bytesN, 0x20)))
        }
    }

    /// @dev Retrieves all `bytes32` elements from the array and returns them as a dynamic array.
    /// @param a The pointer to the array in memory.
    /// @return result The dynamic array of `bytes32` elements.
    function getBytes32All(Array a) internal pure returns (bytes32[] memory result) {
        assembly ("memory-safe") {
            result := mload(0x40)
            let n := and(mload(a), MASK_128)
            // Calculate the byte size of the length
            let bytesN := shl(5, n)
            mstore(result, n)
            // Word mask
            let w := not(0x1f)
            for { let o := bytesN } 1 { } {
                if iszero(o) { break }
                // Copy word from the original array to the result array
                mstore(add(result, o), mload(add(a, o)))
                o := add(o, w) // Move to the next word
            }
            mstore(0x40, add(result, add(bytesN, 0x20)))
        }
    }

    /// @dev Swaps the elements at indices `i` and `j` in the given `Array`.
    /// @param a The `Array` in which elements will be swapped.
    /// @param i The index of the first element to swap.
    /// @param j The index of the second element to swap.
    function swap(Array a, uint256 i, uint256 j) internal pure {
        assembly ("memory-safe") {
            // Last valid index
            let li := sub(and(mload(a), MASK_128), 1)
            if or(gt(i, li), gt(j, li)) {
                mstore(0x00, 0xb4120f14) // "OutOfBounds"
                revert(0x1c, 0x04)
            }
            // Calculate pointer for index i
            let pi := add(a, shl(5, add(0x01, i)))
            // Calculate pointer for index j
            let pj := add(a, shl(5, add(0x01, j)))
            // Load value at index i into temp
            let temp := mload(pi)
            mstore(pi, mload(pj))
            mstore(pj, temp)
        }
    }

    /// @dev Sorts the given array in ascending order using the insertion sort algorithm.
    /// Quicksort is generally more efficient for large arrays, but insertion sort
    /// is more effective for smaller arrays due to fewer comparisons and swaps.
    /// @param a The pointer to the array in memory.
    function insertionSort(Array a) internal pure {
        assembly ("memory-safe") {
            let n := and(mload(a), MASK_128)
            // Calculate the end pointer for the array
            let ep := add(a, shl(5, n))
            mstore(a, 0)
            // Mask
            let w := not(0x1f)
            for { let i := add(a, 0x20) } 1 { } {
                i := add(i, 0x20)
                if gt(i, ep) { break }
                // Current key (element being sorted)
                let k := mload(i)
                // The slot before the current slot
                let j := add(i, w)
                // The value of `j`
                let v := mload(j)
                // If the value at j is not greater than the key, continue
                if iszero(gt(v, k)) { continue }
                // Shift elements that are greater than the key
                for { } 1 { } {
                    mstore(add(j, 0x20), v)
                    j := add(j, w)
                    v := mload(j)
                    if iszero(gt(v, k)) { break }
                }
                // Place the key in its correct position
                mstore(add(j, 0x20), k)
            }
            mstore(a, n)
        }
    }

    /// @dev Removes an element from the array at a specified index by replacing it
    /// with the last element and then reducing the array's length by one.
    /// This method is efficient for cases where the order of elements is not important.
    /// @param a The pointer to the array in memory.
    /// @param i The index of the element to be removed.
    function removeCheap(Array a, uint256 i) internal pure {
        assembly ("memory-safe") {
            let n := and(mload(a), MASK_128)
            if iszero(lt(i, n)) {
                mstore(0x00, 0xb4120f14) // "OutOfBounds"
                revert(0x1c, 0x04)
            }
            // Calculate the new length
            let li := sub(n, 1)
            // End pointer of the array
            let ei := add(a, shl(5, n))
            if iszero(eq(i, li)) {
                let el := mload(ei)
                // Move the last element to the index being removed
                mstore(add(a, shl(5, add(0x01, i))), el)
            }
            // Clear the last element (optional)
            mstore(ei, 0)
            mstore(a, or(shl(128, shr(128, mload(a))), li))
        }
    }

    /// @dev Removes an element from the array at a specified index by shifting subsequent
    /// elements to the left. The last element is then set to zero.
    /// This method preserves the order of elements but is more costly as it requires
    /// shifting elements, making it less efficient than other removal methods.
    /// @param a The pointer to the array in memory.
    /// @param i The index of the element to be removed.
    function removeExpensive(Array a, uint256 i) internal pure {
        assembly ("memory-safe") {
            let n := and(mload(a), MASK_128)
            if iszero(lt(i, n)) {
                mstore(0x00, 0xb4120f14) // "OutOfBounds"
                revert(0x1c, 0x04)
            }
            // End pointer for the array
            let ep := add(a, shl(5, n))
            // Calculate the address of the element to be removed
            let t := add(a, shl(5, add(0x01, i)))
            let nxt := add(t, 0x20)
            for { } 1 { } {
                // Bir sonraki elemanı mevcut pozisyona kopyala
                mstore(t, mload(nxt))
                t := add(t, 0x20)
                nxt := add(nxt, 0x20)
                // Break the loop if we've gone past the end of the array
                if gt(nxt, ep) { break }
            }
            // Clear the last element to prevent dangling reference
            mstore(ep, 0x00)
            mstore(a, or(shl(128, shr(128, mload(a))), sub(n, 1)))
        }
    }

    /// @dev Reverses the elements of the array in place.
    /// @param a The pointer to the array in memory that will be reversed.
    function reverse(Array a) internal pure {
        assembly ("memory-safe") {
            let n := and(mload(a), MASK_128)
            if iszero(lt(n, 2)) {
                // Calculate the starting pointer
                let sp := add(a, 0x20)
                // Calculate the end pointer
                let ep := add(a, shl(5, n))
                // Mask
                let w := not(0x1f)
                for { } 1 { } {
                    let temp := mload(sp)
                    mstore(sp, mload(ep))
                    mstore(ep, temp)
                    // Move start pointer right
                    sp := sub(sp, w)
                    // Move end pointer left
                    ep := add(ep, w)
                    if iszero(lt(sp, ep)) { break }
                }
            }
        }
    }

    /// @notice Linear search is less efficient than binary search because it checks each element sequentially. However,
    /// it works on unsorted arrays.
    /// @dev Performs a linear search on an unsorted array to find the index of a specified value.
    /// @param a The pointer to the array in memory.
    /// @param e The value to search for in the array.
    /// @return i The index of the value if found; otherwise, it will be 0.
    /// @return f A boolean indicating whether the value was found (true) or not (false).
    function unSortedSearch(Array a, uint256 e) internal pure returns (uint256 i, bool f) {
        assembly ("memory-safe") {
            let b := add(a, 0x20)
            // Address of the element just past the last element in the array
            let ep := add(b, shl(5, and(mload(a), MASK_128)))
            let t := b
            for { } 1 { } {
                if gt(t, ep) { break }
                // If a match is found, calculate the index
                if eq(mload(t), e) {
                    i := shr(5, sub(t, b))
                    f := 1
                    break
                }
                t := add(t, 0x20)
            }
        }
    }

    /// @notice Binary search is more efficient than linear search for sorted arrays because it repeatedly divides the
    /// search interval in half.
    /// @dev Performs a binary search on a sorted array to find the index of a specified value.
    /// @param a The pointer to the sorted array in memory.
    /// @param e The value to search for in the array.
    /// @return i The index of the value if found; otherwise, it will be 0.
    /// @return f A boolean indicating whether the value was found (true) or not (false).
    function sortedSearch(Array a, uint256 e) internal pure returns (uint256 i, bool f) {
        assembly ("memory-safe") {
            let n := and(mload(a), MASK_128)
            // Initialize left boundary for binary search
            let l := 1
            // Mask
            let w := not(0)
            // Temporary variable
            let t := 0
            for { } 1 { } {
                // Calculate the index of the middle element
                i := shr(1, add(l, n))
                t := mload(add(a, shl(5, i)))
                if or(gt(l, n), eq(t, e)) { break }
                // Determine if the target element is to the left or right of the middle element
                if iszero(gt(e, t)) {
                    // Target element is to the left, update the upper boundary
                    n := add(i, w)
                    continue
                }
                // Target element is to the right, update the lower boundary
                l := add(i, 1)
            }
            // Check if the element was found
            f := eq(t, e)
            // Check if index i is non-zero
            t := iszero(iszero(i))
            i := mul(add(i, w), t)
            // If the element was found, update the found status
            f := and(f, t)
        }
    }

    /// @dev Converts a standard `uint256[]` array into a custom `Array` format.
    /// @param a The standard `uint256[]` array to be converted.
    /// @return arr A custom `Array` formatted as an `Array` type with the same elements as the input.
    function flipCustomArr(uint256[] memory a) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := mload(0x40)
            let n := mload(a)
            // Calculate the byte size of the length
            let bytesN := shl(5, n)
            // Update the length and limit in the custom array
            mstore(arr, or(shl(128, n), n))
            // Mask
            let w := not(0x1f)
            for { let o := bytesN } 1 { } {
                mstore(add(arr, o), mload(add(a, o)))
                // Move to the next word
                o := add(o, w)
                if iszero(o) { break }
            }
            mstore(0x40, add(arr, shl(5, add(n, 1))))
        }
    }

    /// @dev Creates a new `Array` by slicing a portion from the original `Array` from index `s` to `e`.
    /// @param a The original `Array` to be sliced.
    /// @param s The starting index (inclusive) of the slice.
    /// @param e The ending index (exclusive) of the slice.
    /// @return arr A new `Array` that contains the elements from index `s` to `e-1` of the original `Array`.
    function slice(Array a, uint256 s, uint256 e) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := mload(0x40)
            let li := sub(and(mload(a), MASK_128), 1)
            if or(gt(s, li), or(gt(e, li), gt(s, e))) {
                mstore(0x00, 0xa8834357) // "InvalidBounds"
                revert(0x1c, 0x04)
            }
            // Calculate the length of the slice
            let sl := sub(e, s)
            // Calculate the number of bytes for the length of the slice
            let bytesN := shl(5, sl)
            mstore(arr, or(shl(128, sl), sl))
            // Calculate the starting position offset for the slice
            let si := add(a, shl(5, s))
            // Mask
            let w := not(0x1f)
            for { let o := bytesN } 1 { } {
                mstore(add(arr, o), mload(add(si, o)))
                // Move backwards through the byte array
                o := add(o, w)
                if iszero(o) { break }
            }
            mstore(0x40, add(add(arr, 0x20), bytesN))
        }
    }

    /// @dev Concatenates two `Array` objects into a single `Array`.
    /// @param a The first `Array` to be concatenated.
    /// @param b The second `Array` to be concatenated.
    /// @return arr A new `Array` that contains all elements of `a` followed by all elements of `b`.
    function concat(Array a, Array b) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := mload(0x40)
            let na := and(mload(a), MASK_128)
            let nb := and(mload(b), MASK_128)
            // Calculate the total length of the concatenated array
            let tn := add(na, nb)
            mstore(arr, or(shl(128, tn), tn))
            // Byte size of array 'a'
            let bytesNa := shl(5, na)
            // Byte size of array 'b'
            let bytesNb := shl(5, nb)
            // Mask
            let w := not(0x1f)
            for { let o := bytesNa } 1 { } {
                mstore(add(arr, o), mload(add(a, o)))
                // Move backwards through the byte array
                o := add(o, w)
                if iszero(o) { break }
            }
            for { let o := bytesNb } 1 { } {
                mstore(add(add(arr, bytesNa), o), mload(add(b, o)))
                o := add(o, w)
                if iszero(o) { break }
            }
            // Update the free memory pointer to point after the new concatenated array
            mstore(0x40, add(arr, shl(5, add(tn, 1))))
        }
    }
}
