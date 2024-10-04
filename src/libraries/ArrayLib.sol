// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

/// @notice Library for managing solidity dynamic arrays, focusing on optimized memory handling and efficient gas usage.
/// @author whisskey (https://github.com/whisskey/sarl)
///
/// @dev Note: The implemented functions utilize low-level assembly for optimal performance.
/// The functions have been carefully crafted to manage memory safely and efficiently,
/// ensuring that the allocated memory is properly freed and resized without leaks or
/// overflows.
library ArrayLib {
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/
    /*                        CUSTOM  ERRORS                        */
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/

    /// @notice Thrown when an index is out of bounds.
    error OutOfBounds();
    /// @notice Thrown when the provided bounds are invalid.
    error InvalidBounds();

    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/
    /*                      UINT256 OPERATIONS                      */
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/

    /// @dev Allocates memory for an array of length `n` without initializing its elements.
    /// @param n The number of elements to allocate in the array.
    /// @return result A newly allocated array with space for `n` elements.
    function malloc(uint256 n) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := mload(0x40)
            // Store the array length
            mstore(result, n)
            // Memory allocated for the array
            mstore(0x40, add(result, shl(5, add(n, 1))))
        }
    }

    /// @notice This function uses low-level memory operations and assumes that the memory layout
    /// is correctly managed.  If `newSize` is smaller than the current size, the array is truncated.
    /// If `newSize` is larger and enough free memory is available, the array is expanded in place.
    /// If not, a new array is created in memory, and the contents of the old array are copied over.
    /// @dev Reallocates the memory for an array, adjusting its size to `newSize`.
    /// @param a The original array to reallocate.
    /// @param newSize The new size to resize the array to.
    /// @return result The reallocated array with the adjusted size.
    function realloc(uint256[] memory a, uint256 newSize) internal view returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := a
            let n := mload(a)
            // Calculate the size of the array in memory
            let s := add(shl(5, n), 0x20)
            let fmp := mload(0x40)
            // Is the new size smaller than the current size?
            switch lt(newSize, n)
            case 1 {
                // Update the array length
                mstore(a, newSize)
            }
            default {
                // Check if the memory pointer equals the end of the current array
                switch eq(fmp, add(a, s))
                case 1 {
                    mstore(a, newSize)
                    // Move the memory pointer according to the new size
                    mstore(0x40, add(fmp, shl(5, sub(newSize, n))))
                }
                default {
                    // Move memory using precompile (identity precompile)
                    pop(
                        staticcall(
                            gas(),
                            0x04, // `identity` precompile
                            a, // Source address
                            s, // Source length
                            fmp, // Destination memory pointer
                            s // Destination length
                        )
                    )
                    // Set the length and elements of the array in the new memory
                    mstore(fmp, newSize)
                    result := fmp
                    mstore(0x40, add(fmp, add(s, shl(5, sub(newSize, n)))))
                }
            }
        }
    }

    /// @dev Frees the memory allocated for the given array by adjusting the free memory pointer.
    /// @param a The array to free from memory.
    /// @return result The same array passed in, after memory adjustment.
    function free(uint256[] memory a) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := a
            let n := mload(a)
            let s := add(a, shl(5, add(n, 1)))
            let fmp := mload(0x40)
            // If equal, write the array's starting address to 0x40; otherwise, keep the current free pointer
            mstore(0x40, or(mul(eq(fmp, s), a), mul(iszero(eq(fmp, s)), fmp)))
            codecopy(a, codesize(), shl(5, add(n, 1)))
        }
    }

    /// @dev Resizes the array `a` to length `n` if `n` is smaller than the current length.
    /// @param a The array to be resized.
    /// @param n The new length for the array.
    /// @return result The resized array, or the original array if `n` exceeds the current length.
    function resize(uint256[] memory a, uint256 n) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := a
            // If the new size (n) is less than the current length, set it to n; otherwise, keep the current length
            mstore(a, or(mul(lt(n, mload(a)), n), mul(iszero(lt(n, mload(a))), mload(a))))
        }
    }

    /// @dev Sets the element at index `i` in the array `a` to the value `e`.
    /// @param a The array in which the element will be set.
    /// @param i The index at which the value will be set.
    /// @param e The value to set at the specified index.
    function set(uint256[] memory a, uint256 i, uint256 e) internal pure {
        assembly ("memory-safe") {
            if gt(i, mload(a)) { revert(0x00, 0x00) }
            mstore(add(a, shl(5, add(0x01, i))), e)
        }
    }

    /// @dev Returns the element at index `i` from the array `a`.
    /// @param a The array from which to retrieve the element.
    /// @param i The index of the element to retrieve.
    /// @return result The element at the specified index.
    function get(uint256[] memory a, uint256 i) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            if gt(i, mload(a)) { revert(0x00, 0x00) }
            result := mload(add(a, shl(5, add(0x01, i))))
        }
    }

    /// @dev Resets all elements in the array `a` to zero.
    /// @param a The array to be reset.
    /// @return result The array with all elements set to zero.
    function reset(uint256[] memory a) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := a
            codecopy(add(a, 0x20), codesize(), shl(5, mload(a)))
        }
    }

    /// @dev Computes the Keccak-256 hash of the contents of the array `a`.
    /// @param a The array whose contents will be hashed.
    /// @return result The Keccak-256 hash of the array's contents.
    function hash(uint256[] memory a) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            // keccak256(a, length * 32)
            result := keccak256(add(a, 0x20), shl(5, mload(a)))
        }
    }

    /// @dev Swaps the elements at indices `i` and `j` in the array `a`.
    /// @param a The array in which the elements will be swapped.
    /// @param i The index of the first element to swap.
    /// @param j The index of the second element to swap.
    /// @return result The original array after the swap operation has been performed.
    function swap(uint256[] memory a, uint256 i, uint256 j) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := a
            // Get the length of the array and subtract 1
            let li := sub(mload(a), 1)
            if or(gt(i, li), gt(j, li)) {
                mstore(0x00, 0xb4120f14) // "OutOfBounds"
                revert(0x1c, 0x04)
            }
            // Pointer for the i-th index
            let pi := add(a, shl(5, add(0x01, i)))
            // Pointer for the j-th index
            let pj := add(a, shl(5, add(0x01, j)))
            // Load the value at index i into a temporary variable
            let temp := mload(pi)
            mstore(pi, mload(pj))
            mstore(pj, temp)
        }
    }

    /// @dev Sorts the array `a` in ascending order using the insertion sort algorithm.
    /// @param a The array to be sorted.
    /// @return result The sorted array, which is the same reference as the input array.
    function insertionSort(uint256[] memory a) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := a
            // Get the length of the array
            let n := mload(a)
            // Calculate the end pointer for the array
            let ep := add(a, shl(5, n))
            mstore(a, 0)
            // Mask
            let w := not(0x1f)
            for { let i := add(a, 0x20) } 1 { } {
                i := add(i, 0x20)
                if gt(i, ep) { break }
                // Store the current element as the key for insertion
                let k := mload(i)
                // Set j to point to the previous element's position
                let j := add(i, w)
                // Load the value of the element at index j
                let v := mload(j)
                // If the value at j is greater than k, continue with insertion
                if iszero(gt(v, k)) { continue }
                for { } 1 { } {
                    mstore(add(j, 0x20), v)
                    j := add(j, w)
                    v := mload(j)
                    // Break if we've found the correct position for k
                    if iszero(gt(v, k)) { break }
                }
                mstore(add(j, 0x20), k)
            }
            mstore(a, n)
        }
    }

    /// @dev Removes an element from the array `a` at the specified index `i` in an efficient manner.
    /// @param a The array from which the element will be removed.
    /// @param i The index of the element to be removed.
    /// @return result The modified array with the element at index `i` removed.
    function removeCheap(uint256[] memory a, uint256 i) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := a
            let n := mload(a)
            if iszero(lt(i, n)) {
                mstore(0x00, 0xb4120f14) // "OutOfBounds"
                revert(0x1c, 0x04)
            }
            // Calculate the new length
            let li := sub(n, 1)
            // End pointer for the array
            let ei := add(a, shl(5, n))
            if iszero(eq(i, li)) {
                let el := mload(ei)
                // Place the last element in the index i
                mstore(add(a, shl(5, add(0x01, i))), el)
            }
            // Clear the last element
            mstore(ei, 0)
            mstore(a, li)
        }
    }

    /// @dev Removes an element from the array `a` at the specified index `i` by shifting subsequent elements to the
    /// left.
    /// @param a The array from which the element will be removed.
    /// @param i The index of the element to be removed.
    /// @return result The modified array with the element at index `i` removed.
    function removeExpensive(uint256[] memory a, uint256 i) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := a
            let n := mload(a)
            if iszero(lt(i, n)) {
                mstore(0x00, 0xb4120f14) // "OutOfBounds"
                revert(0x1c, 0x04)
            }
            // End pointer for the array
            let ep := add(a, shl(5, n))
            // Calculate the address of the element to be removed
            let t := add(a, shl(5, add(0x01, i)))
            // Address of the next element to be moved
            let nxt := add(t, 0x20)
            for { } 1 { } {
                mstore(t, mload(nxt))
                t := add(t, 0x20)
                nxt := add(nxt, 0x20)
                // Break the loop if we've gone past the end of the array
                if gt(nxt, ep) { break }
            }
            // Clear the last element to prevent dangling reference
            mstore(ep, 0x00)
            mstore(a, sub(n, 1))
        }
    }

    /// @dev Reverses the elements of the array `a` in place.
    /// @param a The array to be reversed.
    /// @return result The modified array with its elements in reverse order.
    function reverse(uint256[] memory a) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := a
            let n := mload(a)
            if iszero(lt(n, 2)) {
                // Calculate the starting pointer
                let sp := add(a, 0x20)
                // Calculate the end pointer
                let ep := add(a, shl(5, n))
                // Mask
                let w := not(0x1f)
                for { } 1 { } {
                    let temp := mload(sp)
                    // Swap the values at the start and end pointers
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

    /// @dev Searches for the element `e` in the unsorted array `a`.
    /// @param a The array in which to search for the element.
    /// @param e The element to search for in the array.
    /// @return i The index of the found element or 0 if not found.
    /// @return f A boolean indicating whether the element was found (true) or not (false).
    function unSortedSearch(uint256[] memory a, uint256 e) internal pure returns (uint256 i, bool f) {
        assembly ("memory-safe") {
            let b := add(a, 0x20)
            // Address of the element just past the last element in the array
            let ep := add(b, shl(5, mload(a)))
            let t := b
            for { } 1 { } {
                if gt(t, ep) { break }
                if eq(mload(t), e) {
                    // If a match is found, calculate the index
                    i := shr(5, sub(t, b))
                    f := 1
                    break
                }
                t := add(t, 0x20)
            }
        }
    }

    /// @dev Performs a binary search for the element `e` in a sorted array `a`.
    /// @param a The sorted array in which to search for the element.
    /// @param e The element to search for in the array.
    /// @return i The index of the found element or 0 if not found.
    /// @return f A boolean indicating whether the element was found (true) or not (false).
    function sortedSearch(uint256[] memory a, uint256 e) internal pure returns (uint256 i, bool f) {
        assembly ("memory-safe") {
            let n := mload(a)
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

    /// @dev Creates a new array that is a slice of the input array `a`,
    /// @param a The original array from which to create a slice.
    /// @param s The starting index (inclusive) of the slice.
    /// @param e The ending index (exclusive) of the slice.
    /// @return result A new array containing the elements from index `s` to `e - 1`.
    function slice(uint256[] memory a, uint256 s, uint256 e) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := mload(0x40)
            let li := sub(mload(a), 1)
            if or(gt(s, li), or(gt(e, li), gt(s, e))) {
                mstore(0x00, 0xa8834357) // "InvalidBounds"
                revert(0x1c, 0x04)
            }
            // Calculate the length of the slice
            let sl := sub(e, s)
            // Calculate the number of bytes for the length of the slice
            let bytesN := shl(5, sl)
            mstore(result, sl)
            // Calculate the starting position offset for the slice
            let si := add(a, shl(5, s))
            // Mask
            let w := not(0x1f)
            for { let o := bytesN } 1 { } {
                mstore(add(result, o), mload(add(si, o)))
                // Move backwards through the byte array
                o := add(o, w)
                if iszero(o) { break }
            }
            mstore(0x40, add(add(result, 0x20), bytesN))
        }
    }

    /// @dev Concatenates two arrays `a` and `b` into a new array.
    /// @param a The first array to concatenate.
    /// @param b The second array to concatenate.
    /// @return result A new array containing all elements from `a` followed by all elements from `b`.
    function concat(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            result := mload(0x40)
            let na := mload(a)
            let nb := mload(b)
            // Calculate the total length of the concatenated array
            let tn := add(na, nb)
            mstore(result, tn)
            // Byte size of array 'a'
            let bytesNa := shl(5, na)
            // Byte size of array 'b'
            let bytesNb := shl(5, nb)
            // Mask
            let w := not(0x1f)
            for { let o := bytesNa } 1 { } {
                mstore(add(result, o), mload(add(a, o)))
                // Move backwards through the byte array
                o := add(o, w)
                if iszero(o) { break }
            }
            for { let o := bytesNb } 1 { } {
                mstore(add(add(result, bytesNa), o), mload(add(b, o)))
                o := add(o, w)
                if iszero(o) { break }
            }
            // Update the free memory pointer to point after the new concatenated array
            mstore(0x40, add(result, shl(5, add(tn, 1))))
        }
    }
}
