// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

/// @dev A contract providing low-level memory operations for arrays.
contract MemoryOps {
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/
    /*                        CUSTOM  ERRORS                        */
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/

    /// @notice Thrown when a free memory pointer overflows.
    error FmpOverflowed();
    /// @notice Thrown when zero slot is not zero.
    error NotZero();
    /// @notice Thrown when memory allocation is insufficient.
    error InsufficientMemory();

    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/
    /*                      CONTRACT OPERATIONS                     */
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/

    /// @dev Calculates the pointer to the next free memory position after the elements of the array `a`.
    /// @param a The array from which to calculate the next free memory pointer.
    /// @return ptr The memory pointer to the next free position after the array's elements.
    function _nextFmp(uint256[] memory a) internal pure returns (bytes32 ptr) {
        assembly ("memory-safe") {
            ptr := add(a, add(shl(5, mload(a)), 0x20))
        }
    }

    /// @dev Increments the given memory pointer `ptr` by 32 bytes to point to the next memory position.
    /// @param ptr The current memory pointer to be incremented.
    /// @return nextPtr The new memory pointer, which is 32 bytes ahead of the input pointer.
    function _nextPtr(bytes32 ptr) internal pure returns (bytes32 nextPtr) {
        assembly {
            nextPtr := add(ptr, 0x20)
        }
    }

    /// @dev Loads a 256-bit value from the specified memory pointer `ptr`.
    /// @param ptr The memory pointer from which the value will be loaded.
    /// @return result The 256-bit value loaded from the specified memory location.
    function _loadPtr(bytes32 ptr) internal pure returns (uint256 result) {
        assembly {
            result := mload(ptr)
        }
    }

    /// @dev Retrieves the memory pointer of the array `a`.
    /// @param a The array whose memory pointer is being retrieved.
    /// @return ptr The memory pointer pointing to the start of the array.
    function _getPtr(uint256[] memory a) internal pure returns (bytes32 ptr) {
        assembly ("memory-safe") {
            ptr := a
        }
    }

    /// @notice  This function is intended for internal use only and should be called
    /// to validate memory state before performing critical operations.
    /// @dev Checks the integrity of memory allocation and ensures the following:
    /// The free memory pointer (located at `0x40`) has not overflowed.
    /// The zero slot (located at `0x60`) is zero.
    function _checkMemory() internal pure {
        bool zeroSlot;
        bool memOverflowed;
        assembly ("memory-safe") {
            mstore(mload(0x40), not(0))
            // Check if the free memory pointer (located at 0x40) overflows a safe limit (0xffffffff).
            if gt(mload(0x40), 0xffffffff) { memOverflowed := 1 }
            zeroSlot := mload(0x60)
        }

        require(!memOverflowed, FmpOverflowed());
        require(!zeroSlot, NotZero());
    }

    /// @dev Checks the integrity of memory allocation for the given array `a` and ensures:
    /// The free memory pointer (located at `0x40`) is sufficient to accommodate the array.
    /// The memory allocation is verified by checking if the required space exceeds the free memory pointer.
    /// @param arr The array to check for sufficient memory allocation.
    function _checkMemory(uint256[] memory arr) internal pure {
        bool insufMalloc;

        assembly ("memory-safe") {
            mstore(mload(0x40), not(0))
            // Calculate the total size required for the array and compare it to the current free memory pointer.
            insufMalloc := gt(add(add(arr, 0x20), shl(5, mload(arr))), mload(0x40))
        }

        if (insufMalloc) {
            revert("Insufficient memory allocation!");
        }

        require(!insufMalloc, InsufficientMemory());

        _checkMemory();
    }
}
