// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

/// @dev A contract that provides various operations for managing arrays.
contract ArrayOps {
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/
    /*                        CUSTOM  ERRORS                        */
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/

    /// @notice Thrown when an index is out of bounds.
    error OutOfBounds();
    /// @notice Thrown when the provided range is invalid.
    error InvalidRange();
    /// @notice Thrown when the array is empty.
    error EmptyArray();

    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/
    /*                      CONTRACT OPERATIONS                     */
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/

    /// @dev Returns the keccak256 hash of the given array `a`.
    /// @param a The array to hash.
    /// @return The keccak256 hash of the array.
    function _hash(uint256[] memory a) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(a));
    }

    /// @dev Resets all elements in the given array `a` to zero.
    /// @param a The array to reset.
    /// @return result The modified array with all elements set to zero.
    function _reset(uint256[] memory a) internal pure returns (uint256[] memory result) {
        result = a;
        for (uint256 i = 0; i < a.length; i++) {
            a[i] = 0;
        }
    }

    /// @dev Swaps the elements at indices `i` and `j` in the given array `a`.
    /// @param a The array in which elements will be swapped.
    /// @param i The index of the first element to swap.
    /// @param j The index of the second element to swap.
    /// @return result The modified array after swapping the elements.
    function _swap(uint256[] memory a, uint256 i, uint256 j) internal pure returns (uint256[] memory result) {
        result = a;

        uint256 n = a.length;

        require(i < n && j < n, OutOfBounds());

        uint256 temp = a[i];
        a[i] = a[j];
        a[j] = temp;
    }

    /// @dev Checks if the array `a` is sorted in non-decreasing order.
    /// @param a The array to be checked.
    /// @return True if the array is sorted, false otherwise.
    function _isSorted(uint256[] memory a) internal pure returns (bool) {
        unchecked {
            for (uint256 i = 1; i < a.length; ++i) {
                if (a[i - 1] > a[i]) {
                    return false;
                }
            }
            return true;
        }
    }

    /// @dev Sorts an array of unsigned integers in ascending order using the insertion sort algorithm.
    /// @param a The array to be sorted.
    /// @return result The sorted array.
    function _insertionSort(uint256[] memory a) internal pure returns (uint256[] memory result) {
        unchecked {
            result = a;
            for (uint256 i = 1; i < a.length; i++) {
                uint256 temp = a[i];
                uint256 j = i;
                while ((j >= 1) && (temp < a[j - 1])) {
                    a[j] = a[j - 1];
                    j--;
                }
                a[j] = temp;
            }
        }
    }

    /// @dev Removes an element from an array at the specified index without preserving order.
    /// @param a The array from which the element will be removed.
    /// @param index The index of the element to remove.
    /// @return result The new array after the element has been removed.
    function _removeCheap(uint256[] memory a, uint256 index) internal pure returns (uint256[] memory result) {
        require(index < a.length, OutOfBounds());

        uint256 lastIndex = a.length - 1;

        result = new uint256[](lastIndex);

        if (index != lastIndex) {
            a[index] = a[lastIndex];
        }

        unchecked {
            for (uint256 i = 0; i < lastIndex; i++) {
                result[i] = a[i];
            }
        }
    }

    /// @dev Removes an element from an array at the specified index while preserving order.
    /// @param a The array from which the element will be removed.
    /// @param index The index of the element to remove.
    /// @return result The new array after the element has been removed, preserving the order of elements.
    function _removeExpensive(uint256[] memory a, uint256 index) internal pure returns (uint256[] memory result) {
        require(index < a.length, OutOfBounds());

        uint256 lastIndex = a.length - 1;

        result = new uint256[](lastIndex);

        unchecked {
            for (uint256 i = 0; i < lastIndex; i++) {
                if (i < index) {
                    result[i] = a[i];
                    continue;
                }
                result[i] = a[i + 1];
            }
        }
    }

    /// @dev Reverses the order of elements in the provided array.
    /// @param a The array to be reversed.
    /// @return result The reverse array.
    function _reverse(uint256[] memory a) internal pure returns (uint256[] memory result) {
        result = a;
        uint256 length = a.length;

        unchecked {
            for (uint256 i = 0; i < length / 2; i++) {
                uint256 temp = a[i];
                a[i] = a[length - i - 1];
                a[length - i - 1] = temp;
            }
        }
    }

    /// @dev Performs an unsorted search for a specified element in the array.
    /// @param a The array to search through.
    /// @param element The element to search for.
    /// @return index The index of the element if found, otherwise 0.
    /// @return found A boolean indicating whether the element was found.
    function _unSortedSearch(uint256[] memory a, uint256 element) internal pure returns (uint256, bool) {
        uint256 length = a.length;

        unchecked {
            for (uint256 i = 0; i < length; i++) {
                if (a[i] == element) {
                    return (i, true);
                }
            }
        }

        return (0, false);
    }

    /// @dev Performs a binary search for a specified element in a sorted array.
    /// @param a The sorted array to search through.
    /// @param element The element to search for.
    /// @return index The index of the element if found, otherwise 0.
    /// @return found A boolean indicating whether the element was found.
    function _sortedSearch(uint256[] memory a, uint256 element) internal pure returns (uint256, bool) {
        uint256 minimum = 0;
        uint256 maximum = a.length;

        unchecked {
            while (minimum < maximum) {
                uint256 middle = (minimum + maximum) / 2;
                uint256 currentElement = a[middle];

                if (currentElement < element) {
                    minimum = middle + 1;
                } else if (currentElement > element) {
                    maximum = middle;
                } else {
                    return (middle, true);
                }
            }
        }

        return (0, false);
    }

    /// @dev Creates a new array that is a slice of the original array from `start` to `end`.
    /// @param a The original array to slice from.
    /// @param start The starting index (inclusive) for the slice.
    /// @param end The ending index (exclusive) for the slice.
    /// @return result A new array containing the elements from `start` to `end - 1`.
    function _slice(uint256[] memory a, uint256 start, uint256 end) internal pure returns (uint256[] memory result) {
        require(start <= end, InvalidRange());
        require(end <= a.length, OutOfBounds());

        uint256 length = end - start;
        result = new uint256[](length);

        unchecked {
            for (uint256 i = 0; i < length; i++) {
                result[i] = a[start + i];
            }
        }
    }

    /// @dev Concatenates two arrays `a` and `b` into a new array.
    /// @param a The first array to concatenate.
    /// @param b The second array to concatenate.
    /// @return result A new array containing the elements of `a` followed by the elements of `b`.
    function _concat(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory result) {
        uint256 aLength = a.length;
        uint256 bLength = b.length;

        result = new uint256[](aLength + bLength);

        unchecked {
            for (uint256 i = 0; i < aLength; i++) {
                result[i] = a[i];
            }

            for (uint256 i = 0; i < bLength; i++) {
                result[aLength + i] = b[i];
            }
        }
    }
}
