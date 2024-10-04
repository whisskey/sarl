// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

import "./DynamicArrayLib.sol";

/// @notice Library for managing unsafe dynamic memory array operations
/// @author whisskey (https://github.com/whisskey/sarl)
///
/// @dev Note: This library provides unsafe operations for a dynamic memory arrays. These functions are marked as unsafe
/// and require the caller to ensure the correctness of their usage. Improper use may lead to undefined behavior or
/// memory corruption.
library UnsafeLib {
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/
    /*                  DYNAMICARRAYLIB OPERATIONS                  */
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/

    /// @dev Retrieves a pointer to an element at the specified index in the array.
    /// @param a The pointer to the array in memory.
    /// @param i The index of the element for which to retrieve the pointer.
    /// @return result A pointer to the element at the specified index.
    function unsafe_ptr(Array a, uint256 i) internal pure returns (Array result) {
        assembly ("memory-safe") {
            result := add(a, shl(5, add(0x01, i)))
        }
    }

    /// @dev Clears the array by resetting its length to zero.
    /// @param a The pointer to the array in memory.
    function unsafe_clear(Array a) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := a
            // Clear the array by setting the length to 0 while preserving the limit
            mstore(a, and(mload(a), not(sub(shl(128, 1), 1))))
        }
    }

    /// @dev Resizes the array to a specified length.
    /// @param a The pointer to the array in memory.
    /// @param n The new length of the array.
    function unsafe_resize(Array a, uint256 n) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := a
            // Update the length of the array to the new size n
            mstore(a, or(shl(128, shr(128, mload(a))), n))
        }
    }

    /// @dev Sets the value at a specified index in the array, assuming the index is within bounds.
    /// @param a The pointer to the array in memory.
    /// @param i The index at which to set the value.
    /// @param e The value to set at the specified index.
    /// @notice This function should only be used when you are certain that the index is valid.
    /// Using an out-of-bounds index can lead to undefined behavior.
    /// While marked as memory safe, it may not be safe if the calling contract violates safety guarantees.
    function unsafe_set(Array a, uint256 i, uint256 e) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := a
            // Store the element e at the specified index i in the array a
            mstore(add(a, shl(5, add(0x01, i))), e)
        }
    }

    /// @dev Sets the address value at a specified index in the array, assuming the index is within bounds.
    /// @param a The pointer to the array in memory.
    /// @param i The index at which to set the address value.
    /// @param e The address value to set at the specified index.
    function unsafe_set(Array a, uint256 i, address e) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := a
            mstore(add(a, shl(5, add(0x01, i))), shr(96, shl(96, e)))
        }
    }

    /// @dev Sets the boolean value at a specified index in the array, assuming the index is within bounds.
    /// @param a The pointer to the array in memory.
    /// @param i The index at which to set the boolean value.
    /// @param e The boolean value to set at the specified index.
    function unsafe_set(Array a, uint256 i, bool e) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := a
            mstore(add(a, shl(5, add(0x01, i))), iszero(iszero(e)))
        }
    }

    /// @dev Sets the bytes32 value at a specified index in the array, assuming the index is within bounds.
    /// @param a The pointer to the array in memory.
    /// @param i The index at which to set the bytes32 value.
    /// @param e The bytes32 value to set at the specified index.
    function unsafe_set(Array a, uint256 i, bytes32 e) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := a
            mstore(add(a, shl(5, add(0x01, i))), e)
        }
    }

    /// @dev Retrieves the uint256 value at a specified index in the array, assuming the index is within bounds.
    /// @param a The pointer to the array in memory.
    /// @param i The index from which to retrieve the uint256 value.
    /// @return result The uint256 value located at the specified index.
    function unsafe_get(Array a, uint256 i) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            // Load the value at the specified index and store it in the result
            result := mload(add(a, shl(5, add(0x01, i))))
        }
    }

    /// @dev Retrieves the uint256 value at a specified index in the array, assuming the index is within bounds.
    /// @param a The pointer to the array in memory.
    /// @param i The index from which to retrieve the uint256 value.
    /// @return result The uint256 value located at the specified index.
    function unsafe_getUint256(Array a, uint256 i) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            result := mload(add(a, shl(5, add(0x01, i))))
        }
    }

    /// @dev Retrieves the address value at a specified index in the array, assuming the index is within bounds.
    /// @param a The pointer to the array in memory.
    /// @param i The index from which to retrieve the address value.
    /// @return result The address value located at the specified index.
    function unsafe_getAddress(Array a, uint256 i) internal pure returns (address result) {
        assembly ("memory-safe") {
            result := mload(add(a, shl(5, add(0x01, i))))
        }
    }

    /// @dev Retrieves the boolean value at a specified index in the array, assuming the index is within bounds.
    /// @param a The pointer to the array in memory.
    /// @param i The index from which to retrieve the boolean value.
    /// @return result The boolean value located at the specified index.
    function unsafe_getBool(Array a, uint256 i) internal pure returns (bool result) {
        assembly ("memory-safe") {
            result := mload(add(a, shl(5, add(0x01, i))))
        }
    }

    /// @dev Retrieves the bytes32 value at a specified index in the array, assuming the index is within bounds.
    /// @param a The pointer to the array in memory.
    /// @param i The index from which to retrieve the bytes32 value.
    /// @return result The bytes32 value located at the specified index.
    function unsafe_getBytes32(Array a, uint256 i) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            result := mload(add(a, shl(5, add(0x01, i))))
        }
    }

    /// @dev Removes and returns the last element of the array, assuming the array is not empty.
    /// @param a The pointer to the array in memory.
    /// @return result The value of the last element that was removed from the array.
    function unsafe_pop(Array a) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            // Get the current length of the array (first 128 bits)
            let n := and(mload(a), sub(shl(128, 1), 1))
            result := mload(add(a, shl(5, n)))
            // Do not pop anything
            mstore(a, or(shl(128, shr(128, mload(a))), sub(n, iszero(iszero(n)))))
        }
    }

    /// @dev Removes and returns the last `uint256` element of the array, assuming the array is not empty.
    /// @param a The pointer to the array in memory.
    /// @return result The `uint256` value of the last element that was removed from the array.
    function unsafe_popUint256(Array a) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            let n := and(mload(a), sub(shl(128, 1), 1))
            result := mload(add(a, shl(5, n)))
            mstore(a, or(shl(128, shr(128, mload(a))), sub(n, iszero(iszero(n)))))
        }
    }

    /// @dev Removes and returns the last `address` element of the array, assuming the array is not empty.
    /// @param a The pointer to the array in memory.
    /// @return result The `address` value of the last element that was removed from the array.
    function unsafe_popAddress(Array a) internal pure returns (address result) {
        assembly ("memory-safe") {
            let n := and(mload(a), sub(shl(128, 1), 1))
            result := mload(add(a, shl(5, n)))
            mstore(a, or(shl(128, shr(128, mload(a))), sub(n, iszero(iszero(n)))))
        }
    }

    /// @dev Removes and returns the last `bool` element of the array, assuming the array is not empty.
    /// @param a The pointer to the array in memory.
    /// @return result The `bool` value of the last element that was removed from the array.
    function unsafe_popBool(Array a) internal pure returns (bool result) {
        assembly ("memory-safe") {
            let n := and(mload(a), sub(shl(128, 1), 1))
            result := mload(add(a, shl(5, n)))
            mstore(a, or(shl(128, shr(128, mload(a))), sub(n, iszero(iszero(n)))))
        }
    }

    /// @dev Removes and returns the last `bytes32` element of the array, assuming the array is not empty.
    /// @param a The pointer to the array in memory.
    /// @return result The `bytes32` value of the last element that was removed from the array.
    function unsafe_popBytes32(Array a) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            let n := and(mload(a), sub(shl(128, 1), 1))
            result := mload(add(a, shl(5, n)))
            mstore(a, or(shl(128, shr(128, mload(a))), sub(n, iszero(iszero(n)))))
        }
    }

    /// @dev Adds a new `uint256` element to the end of the array, assuming there is available capacity.
    /// @param a The pointer to the array in memory.
    /// @param e The `uint256` element to be added to the array.
    /// @return arr The pointer to the updated array.
    /// @notice This function does not perform any checks to ensure that the array has enough capacity.
    /// It is the caller's responsibility to guarantee that space is available for the new element.
    /// If the capacity is exceeded, this can lead to unintended behavior.
    function unsafe_push(Array a, uint256 e) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := a
            let n := and(mload(a), sub(shl(128, 1), 1))
            // Add the new element at the next available index
            mstore(add(arr, shl(5, add(0x01, n))), e)
            // Update the length of the array
            mstore(arr, or(shl(128, shr(128, mload(a))), add(n, 0x01)))
        }
    }

    /// @dev Adds a new `address` element to the end of the array, assuming there is available capacity.
    /// @param a The pointer to the array in memory.
    /// @param e The `address` element to be added to the array.
    /// @return arr The pointer to the updated array.
    function unsafe_push(Array a, address e) internal pure returns (Array arr) {
        arr = unsafe_push(a, uint256(uint160(e)));
    }

    /// @dev Adds a new `bool` element to the end of the array, assuming there is available capacity.
    /// @param a The pointer to the array in memory.
    /// @param e The `bool` element to be added to the array.
    /// @return arr The pointer to the updated array.
    function unsafe_push(Array a, bool e) internal pure returns (Array arr) {
        uint256 result;
        assembly {
            result := iszero(iszero(e))
        }
        arr = unsafe_push(a, result);
    }

    /// @dev Adds a new `bytes32` element to the end of the array, assuming there is available capacity.
    /// @param a The pointer to the array in memory.
    /// @param e The `bytes32` element to be added to the array.
    /// @return arr The pointer to the updated array.
    function unsafe_push(Array a, bytes32 e) internal pure returns (Array arr) {
        arr = unsafe_push(a, uint256(e));
    }

    /// @dev Retrieves all `uint256` elements from the array.
    /// @param a The pointer to the array in memory.
    /// @return result A new `uint256[]` array containing all elements from the original array.
    function unsafe_getAll(Array a) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := a
            // Update the length of the array in the result to the current length
            mstore(a, and(mload(a), sub(shl(128, 1), 1)))
        }
    }

    /// @dev Retrieves all `uint256` elements from the array.
    /// @param a The pointer to the array in memory.
    /// @return result A new `uint256[]` array containing all elements from the original array.
    function unsafe_getUint256All(Array a) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := a
            mstore(a, and(mload(a), sub(shl(128, 1), 1)))
        }
    }

    /// @dev Retrieves all `address` elements from the array.
    /// @param a The pointer to the array in memory.
    /// @return result A new `address[]` array containing all elements from the original array.
    function unsafe_getAddressAll(Array a) internal pure returns (address[] memory result) {
        assembly ("memory-safe") {
            result := a
            mstore(a, and(mload(a), sub(shl(128, 1), 1)))
        }
    }

    /// @dev Retrieves all `bool` elements from the array.
    /// @param a The pointer to the array in memory.
    /// @return result A new `bool[]` array containing all elements from the original array.
    function unsafe_getBoolAll(Array a) internal pure returns (bool[] memory result) {
        assembly ("memory-safe") {
            result := a
            mstore(a, and(mload(a), sub(shl(128, 1), 1)))
        }
    }

    /// @dev Retrieves all `bytes32` elements from the array.
    /// @param a The pointer to the array in memory.
    /// @return result A new `bytes32[]` array containing all elements from the original array.
    function unsafe_getBytes32All(Array a) internal pure returns (bytes32[] memory result) {
        assembly ("memory-safe") {
            result := a
            mstore(a, and(mload(a), sub(shl(128, 1), 1)))
        }
    }

    /// @dev Swaps the elements at the specified indices in the array.
    /// @param a The pointer to the array in memory.
    /// @param i The index of the first element to swap.
    /// @param j The index of the second element to swap.
    function unsafe_swap(Array a, uint256 i, uint256 j) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := a
            // Load value at index i into temp
            let tmp := mload(add(a, shl(5, add(0x01, i))))
            mstore(add(a, shl(5, add(0x01, i))), mload(add(a, shl(5, add(0x01, j)))))
            mstore(add(a, shl(5, add(0x01, j))), tmp)
        }
    }

    /// @dev Removes an element from the array by replacing it with the last element, reducing the array's length by
    /// one.
    /// @param a The array from which to remove the element.
    /// @param i The index of the element to remove.
    function unsafe_removeCheap(Array a, uint256 i) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := a
            let n := and(mload(a), sub(shl(128, 1), 1))
            // Calculate the new length
            let li := sub(n, 1)
            // End pointer of the array
            let ei := add(a, shl(5, n))
            if iszero(eq(i, li)) {
                let el := mload(ei)
                mstore(add(a, shl(5, add(0x01, i))), el)
            }
            mstore(a, or(shl(128, shr(128, mload(a))), li))
        }
    }

    /// @dev Removes an element at the specified index from the array.
    /// @param a The pointer to the array in memory.
    /// @param i The index of the element to remove.
    function unsafe_removeExpensive(Array a, uint256 i) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := a
            let n := and(mload(a), sub(shl(128, 1), 1))
            // Calculate the address of the element to be removed
            let ptr := add(a, shl(5, add(0x01, i)))
            let nextPtr := add(ptr, 0x20)
            for { } 1 { } {
                mstore(ptr, mload(nextPtr))
                ptr := nextPtr
                nextPtr := add(nextPtr, 0x20)
                if gt(nextPtr, add(a, shl(5, n))) { break }
            }
            mstore(a, or(shl(128, shr(128, mload(a))), sub(n, 1)))
        }
    }

    /// @dev Checks if a specified element exists in the array.
    /// @param a The pointer to the array in memory.
    /// @param e The element to search for.
    /// @return f A boolean indicating whether the element was found.
    function unsafe_search(Array a, uint256 e) internal pure returns (bool f) {
        assembly ("memory-safe") {
            let ptr := add(a, 0x20)
            for { } 1 { } {
                if gt(ptr, add(a, shl(5, and(mload(a), sub(shl(128, 1), 1))))) { break }
                // If a match is found, calculate the index
                if eq(mload(ptr), e) {
                    f := 1
                    break
                }
                ptr := add(ptr, 0x20)
            }
        }
    }

    /// @dev Converts a standard `uint256[]` memory array into a custom array structure (`Array`)
    /// @param a The standard `uint256[]` memory array to convert.
    /// @return arr The converted custom `Array` structure with the length and limit set.
    function unsafe_flipCustomArr(uint256[] memory a) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := a
            let n := mload(a)
            // Update the length and limit in array a
            mstore(arr, or(shl(128, n), n))
        }
    }

    /// @dev Creates a new array slice from the original array.
    /// @param a The original array from which the slice will be created.
    /// @param s The starting index of the slice (inclusive).
    /// @param e The ending index of the slice (exclusive).
    /// @return arr The new array slice.
    function unsafe_slice(Array a, uint256 s, uint256 e) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := mload(0x40)
            let sl := sub(e, s)
            let bytesN := shl(5, sl)
            mstore(arr, or(shl(128, sl), sl))
            // Calculate the starting position offset for the slice
            let si := add(a, shl(5, s))
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

    /// @dev Concatenates two arrays into the first array.
    /// @param a The first array that will receive elements from the second array.
    /// @param b The second array whose elements will be appended to the first array.
    function unsafe_concat(Array a, Array b) internal pure returns (Array arr) {
        assembly ("memory-safe") {
            arr := a
            let m := sub(shl(128, 1), 1)
            let na := and(mload(a), m)
            let nb := and(mload(b), m)
            // Calculate the total length after concatenation
            let tn := add(na, nb)
            // Calculate the start pointer for writing in array a
            let si := add(a, shl(5, add(0x01, na)))
            let nxt := add(b, 0x20)
            // End pointer for array b
            let ep := add(b, shl(5, nb))
            for { } 1 { } {
                mstore(si, mload(nxt))
                si := add(si, 0x20)
                nxt := add(nxt, 0x20)
                if gt(nxt, ep) { break }
            }
            // Update the length and limit in array a
            mstore(a, or(shl(128, tn), tn))
        }
    }
}
