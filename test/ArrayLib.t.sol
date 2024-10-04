// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.27;

import { ArrayLib } from "src/libraries/ArrayLib.sol";

import { SarlTest } from "test/utils/SarlTest.sol";

contract ArrayLibTest is SarlTest {
    using ArrayLib for uint256[];

    function setUp() public { }

    function test_malloc() public pure {
        unchecked {
            uint256 length = 1;

            uint256[] memory arr = ArrayLib.malloc(length);

            _checkMemory(arr);

            assertEq(arr.length, length);
        }
    }

    function test_realloc_reducesLength_whenNewLengthIsSmaller() public view {
        unchecked {
            uint256 length = 3;

            uint256[] memory arr = ArrayLib.malloc(length);

            arr[0] = 1;
            arr[1] = 2;
            arr[2] = 3;

            uint256 newtLength = arr.length - 1;

            arr = arr.realloc(newtLength);

            _checkMemory(arr);

            assertEq(arr.length, newtLength);
        }
    }

    function test_realloc_increasesLength_whenMemoryIsContiguous() public view {
        unchecked {
            uint256 length = 3;
            uint256[] memory arr = ArrayLib.malloc(length);

            uint256 newtLength = arr.length + 1;

            arr = arr.realloc(newtLength);

            _checkMemory(arr);

            assertEq(arr.length, newtLength);
        }
    }

    function test_realloc_increasesLength_whenMemoryIsNotContiguous() public view {
        unchecked {
            uint256 length = 3;
            uint256[] memory arr = ArrayLib.malloc(length);

            uint256 newtLength = arr.length + 1;

            uint256[] memory b = new uint256[](1);
            b[0] = 1;

            arr = arr.realloc(newtLength);

            _checkMemory(arr);

            bytes32 fmp = _nextFmp(b);

            bytes32 arrOffset = _getPtr(arr);

            assertEq(arr.length, newtLength);
            assertEq(arrOffset, fmp);
        }
    }

    function test_free() public pure {
        unchecked {
            uint256 length = 3;

            uint256[] memory arr = ArrayLib.malloc(length);

            arr[0] = 1;
            arr[1] = 2;
            arr[2] = 3;

            arr = arr.free();

            assertEq(arr.length, 0);

            bytes32 arrOffset = _nextPtr(_getPtr(arr));

            for (uint256 i; i != length; ++i) {
                assertEq(_loadPtr(arrOffset), 0);

                bytes32 newPtr = _nextPtr(arrOffset);
                arrOffset = newPtr;
            }

            arr = ArrayLib.malloc(1);

            uint256[] memory b = new uint256[](2);

            assertEq(_getPtr(b), _nextFmp(arr));
        }
    }

    function test_free_whenMemoryIsNotContiguous() public pure {
        unchecked {
            uint256 length = 3;

            uint256[] memory arr = ArrayLib.malloc(length);

            arr[0] = 1;
            arr[1] = 2;
            arr[2] = 3;

            uint256[] memory b = ArrayLib.malloc(1);
            b[0] = 1;

            arr = arr.free();

            _checkMemory(arr);

            bytes32 arrOffset = _nextPtr(_getPtr(arr));

            for (uint256 i; i != length; ++i) {
                assertEq(_loadPtr(arrOffset), 0);

                bytes32 newPtr = _nextPtr(arrOffset);
                arrOffset = newPtr;
            }

            assertEq(arr.length, 0);
        }
    }

    function test_trimSize() public pure {
        unchecked {
            uint256 length = 3;

            uint256[] memory arr = ArrayLib.malloc(length);

            arr[0] = 1;
            arr[1] = 2;
            arr[2] = 3;

            uint256 newtLength = arr.length - 1;

            arr = arr.trimSize(newtLength);

            _checkMemory(arr);

            assertEq(arr.length, newtLength);
        }
    }

    function test_setAndGet() public pure {
        unchecked {
            uint256 length = 3;
            uint256 arrLen = 0;

            uint256[] memory arr = ArrayLib.malloc(length);

            for (uint256 i; i != length; ++i) {
                arr.set(i, i);
                arrLen += 1;
            }
            for (uint256 i; i != length; ++i) {
                assertEq(arr.get(i), i);
            }

            _checkMemory(arr);

            assertEq(arr.length, arrLen);
        }
    }

    function test_reset() public pure {
        unchecked {
            uint256 length = 3;
            uint256 arrLen = 0;

            uint256[] memory arr = ArrayLib.malloc(length);

            for (uint256 i; i != length; ++i) {
                arr.set(i, i + 1);
                arrLen += 1;
            }

            arr.reset();

            _checkMemory(arr);

            for (uint256 i; i != length; ++i) {
                assertEq(arr.get(i), 0);
            }

            assertEq(arr.length, arrLen);
        }
    }

    function test_hash() public pure {
        unchecked {
            uint256[] memory arr = ArrayLib.malloc(2);

            arr.set(0, 1);
            arr.set(1, 2);

            bytes32 expected = keccak256(abi.encodePacked(arr));

            bytes32 result = arr.hash();

            assertEq(expected, result);
        }
    }

    function test_swap() public pure {
        unchecked {
            uint256 length = 3;
            uint256[] memory arr = ArrayLib.malloc(length);

            for (uint256 i; i != length; ++i) {
                arr.set(i, i);
            }

            uint256[] memory b = arr;
            b = _swap(b, 1, 2);

            arr.swap(1, 2);

            for (uint256 i; i != length; ++i) {
                assertEq(arr.get(i), b[i]);
            }
        }
    }

    function test_insertionSort() public pure {
        unchecked {
            uint256 length = 3;
            uint256[] memory arr = ArrayLib.malloc(length);

            arr.set(0, 1);
            arr.set(1, 3);
            arr.set(2, 2);
            arr.set(3, 8);
            arr.set(4, 6);
            arr.set(5, 5);

            arr.insertionSort();

            assertTrue(_isSorted(arr));
        }
    }

    function test_removeCheap() public pure {
        unchecked {
            uint256 length = 3;
            uint256 newLen = 0;

            uint256[] memory arr = ArrayLib.malloc(length);

            for (uint256 i; i != length; ++i) {
                arr.set(i, i);
                newLen += 1;
            }

            uint256[] memory b = arr;
            b = _removeCheap(b, 2);

            arr.removeCheap(2);
            newLen -= 1;

            _checkMemory(arr);

            for (uint256 i; i != newLen; ++i) {
                assertEq(arr.get(i), b[i]);
            }

            assertEq(arr.length, newLen);
        }
    }

    function test_removeExpensive() public pure {
        unchecked {
            uint256 length = 3;
            uint256 newLen = 0;

            uint256[] memory arr = ArrayLib.malloc(length);

            for (uint256 i; i != length; ++i) {
                arr.set(i, i);
                newLen += 1;
            }

            uint256[] memory b = arr;
            b = _removeExpensive(b, 2);

            arr.removeExpensive(2);
            newLen -= 1;

            _checkMemory(arr);

            for (uint256 i; i != newLen; ++i) {
                assertEq(arr.get(i), b[i]);
            }

            assertEq(arr.length, newLen);
        }
    }

    function test_reverse() public pure {
        unchecked {
            uint256 length = 3;

            uint256[] memory arr = ArrayLib.malloc(length);

            for (uint256 i; i != length; ++i) {
                arr.set(i, i);
            }

            arr.reverse();

            _checkMemory(arr);

            for (uint256 i; i != length; ++i) {
                assertEq(arr.get(i), 2 - i);
            }
        }
    }

    function test_unSortedSearch() public pure {
        unchecked {
            uint256[] memory arr = ArrayLib.malloc(2);

            arr.set(0, 1);
            arr.set(1, 11);

            (uint256 expectedIndex, bool expectedFound) = arr.unSortedSearch(11);

            uint256[] memory b = arr;
            (uint256 actualIndex, bool actualFound) = _unSortedSearch(b, 11);

            assertEq(expectedFound, actualFound);
            assertEq(expectedIndex, actualIndex);
        }
    }

    function test_unSortedSearch_whenElementNotInArray() public pure {
        unchecked {
            uint256[] memory arr = ArrayLib.malloc(2);

            arr.set(0, 1);
            arr.set(1, 11);

            (uint256 expectedIndex, bool expectedFound) = arr.unSortedSearch(32);

            uint256[] memory b = arr;
            (uint256 actualIndex, bool actualFound) = _unSortedSearch(b, 32);

            assertEq(expectedFound, actualFound);
            assertEq(expectedIndex, actualIndex);
        }
    }

    function test_sortedSearch() public pure {
        unchecked {
            uint128 len = 3;
            uint256[] memory arr = ArrayLib.malloc(len);

            for (uint256 i; i != len; ++i) {
                arr.set(i, i);
            }

            (uint256 expectedIndex, bool expectedFound) = arr.sortedSearch(2);

            uint256[] memory b = arr;
            (uint256 actualIndex, bool actualFound) = _sortedSearch(b, 2);

            assertEq(expectedFound, actualFound);
            assertEq(expectedIndex, actualIndex);
        }
    }

    function test_sortedSearch_whenElementNotInArray() public pure {
        unchecked {
            uint128 len = 3;
            uint256[] memory arr = ArrayLib.malloc(len);

            for (uint256 i; i != len; ++i) {
                arr.set(i, i);
            }

            (uint256 expectedIndex, bool expectedFound) = arr.sortedSearch(32);

            uint256[] memory b = arr;
            (uint256 actualIndex, bool actualFound) = _sortedSearch(b, 32);

            assertEq(expectedFound, actualFound);
            assertEq(expectedIndex, actualIndex);
        }
    }

    function test_slice() public pure {
        unchecked {
            uint128 len = 6;
            uint256 start = 2;
            uint256 end = 4;
            uint256 newLength = end - start;

            uint256[] memory arr = ArrayLib.malloc(len);

            for (uint256 i; i != len; ++i) {
                arr.set(i, i);
            }

            uint256[] memory b = arr;
            b = _slice(b, start, end);

            uint256[] memory newArr = arr.slice(start, end);

            _checkMemory(newArr);

            for (uint256 i; i != newLength; ++i) {
                assertEq(newArr.get(i), b[i]);
            }

            assertEq(newArr.length, newLength);
        }
    }

    function test_concat() public pure {
        unchecked {
            uint128 len = 3;

            uint256[] memory arrOne = ArrayLib.malloc(len);
            uint256[] memory arrTwo = ArrayLib.malloc(len);

            for (uint256 i; i != len; ++i) {
                arrOne.set(i, i);
            }

            for (uint256 i; i != len; ++i) {
                arrTwo.set(i, i);
            }

            uint256 totalLength = arrOne.length + arrTwo.length;

            uint256[] memory b = arrOne;
            uint256[] memory c = arrTwo;

            c = _concat(b, c);

            uint256[] memory newArr = arrOne.concat(arrTwo);

            _checkMemory(newArr);

            for (uint256 i; i != totalLength; ++i) {
                assertEq(newArr.get(i), c[i]);
            }

            assertEq(newArr.length, totalLength);
        }
    }

    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/
    /*                        REVERTS                               */
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/

    function test_swap_reverts_whenOutOfBounds() public {
        uint256[] memory arr = ArrayLib.malloc(1);
        arr.set(0, 1);
        arr.set(1, 2);

        vm.expectRevert(ArrayLib.OutOfBounds.selector);
        arr.swap(0, 2);
    }

    function test_removeCheap_reverts_whenOutOfBounds() public {
        uint256[] memory arr = ArrayLib.malloc(1);
        arr.set(0, 1);
        arr.set(1, 2);

        vm.expectRevert(ArrayLib.OutOfBounds.selector);
        arr.removeCheap(2);
    }

    function test_removeExpensive_reverts_whenOutOfBounds() public {
        uint256[] memory arr = ArrayLib.malloc(1);
        arr.set(0, 1);
        arr.set(1, 2);

        vm.expectRevert(ArrayLib.OutOfBounds.selector);
        arr.removeExpensive(2);
    }

    function test_slice_reverts_whenOutOfBounds() public {
        uint256[] memory arr = ArrayLib.malloc(1);
        arr.set(0, 1);
        arr.set(1, 2);
        arr.set(2, 3);

        vm.expectRevert(ArrayLib.OutOfBounds.selector);
        arr.slice(1, 4);
    }

    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/
    /*                        GAS COMPARISON                        */
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/

    function test_newDifference() public {
        unchecked {
            uint256 g0 = gasleft();
            uint256[] memory arr = ArrayLib.malloc(1);
            uint256 g1 = gasleft();
            uint256[] memory a = new uint256[](1);
            uint256 g2 = gasleft();

            emit log_named_uint("Library New gas", g0 - g1);
            emit log_named_uint("Solidity New gas", g1 - g2);

            assertLt(g0 - g1, g1 - g2);
        }
    }

    function test_setDifference() public {
        unchecked {
            uint256[] memory a = new uint256[](1);

            uint256 g0 = gasleft();
            a.set(0, 1);
            uint256 g1 = gasleft();
            a[0] = 1;
            uint256 g2 = gasleft();

            emit log_named_uint("Library set gas", g0 - g1);
            emit log_named_uint("Solidity set gas", g1 - g2);

            assertLt(g0 - g1, g1 - g2);
        }
    }

    function test_getDifference() public {
        unchecked {
            uint256[] memory a = new uint256[](1);
            a[0] = 1;

            uint256 g0 = gasleft();
            a.get(0);
            uint256 g1 = gasleft();
            a[0];
            uint256 g2 = gasleft();

            emit log_named_uint("Library get gas", g0 - g1);
            emit log_named_uint("Solidity get gas", g1 - g2);

            assertLt(g0 - g1, g1 - g2);
        }
    }

    function test_resetDifference() public {
        unchecked {
            uint256[] memory arr = new uint256[](1);
            arr[0] = 1;

            uint256 g0 = gasleft();
            arr.reset();
            uint256 g1 = gasleft();
            _reset(arr);
            uint256 g2 = gasleft();

            emit log_named_uint("Library reset gas", g0 - g1);
            emit log_named_uint("Solidity reset gas", g1 - g2);

            assertLt(g0 - g1, g1 - g2);
        }
    }

    function test_hashDifference() public {
        unchecked {
            uint256[] memory arr = new uint256[](1);
            arr[0] = 1;

            uint256 g0 = gasleft();
            arr.hash();
            uint256 g1 = gasleft();
            _hash(arr);
            uint256 g2 = gasleft();

            emit log_named_uint("Library hash gas", g0 - g1);
            emit log_named_uint("Solidity hash gas", g1 - g2);

            assertLt(g0 - g1, g1 - g2);
        }
    }

    function test_swapDifference() public {
        unchecked {
            uint256[] memory arr = new uint256[](3);
            arr[0] = 1;
            arr[1] = 2;
            arr[2] = 3;

            uint256 g0 = gasleft();
            arr.swap(1, 2);
            uint256 g1 = gasleft();
            _swap(arr, 1, 2);
            uint256 g2 = gasleft();

            emit log_named_uint("Library swap gas", g0 - g1);
            emit log_named_uint("Solidity swap gas", g1 - g2);

            assertLt(g0 - g1, g1 - g2);
        }
    }

    function test_insertionSortDifference() public {
        unchecked {
            uint256[] memory arr = new uint256[](3);
            arr[0] = 1;
            arr[1] = 3;
            arr[2] = 2;

            uint256[] memory a = new uint256[](3);
            a[0] = 1;
            a[1] = 3;
            a[2] = 2;

            uint256 g0 = gasleft();
            arr.insertionSort();
            uint256 g1 = gasleft();
            _insertionSort(a);
            uint256 g2 = gasleft();

            emit log_named_uint("Library insertionSort gas", g0 - g1);
            emit log_named_uint("Solidity insertionSort gas", g1 - g2);

            assertLt(g0 - g1, g1 - g2);
        }
    }

    function test_removeCheapDifference() public {
        unchecked {
            uint256[] memory arr = new uint256[](3);
            arr[0] = 1;
            arr[1] = 2;
            arr[2] = 3;

            uint256[] memory a = new uint256[](3);
            a[0] = 1;
            a[1] = 2;
            a[2] = 3;

            uint256 g0 = gasleft();
            arr.removeCheap(1);
            uint256 g1 = gasleft();
            _removeCheap(a, 1);
            uint256 g2 = gasleft();

            emit log_named_uint("Library removeCheap gas", g0 - g1);
            emit log_named_uint("Solidity removeCheap gas", g1 - g2);

            assertLt(g0 - g1, g1 - g2);
        }
    }

    function test_removeExpensiveDifference() public {
        unchecked {
            uint256[] memory arr = new uint256[](3);
            arr[0] = 1;
            arr[1] = 2;
            arr[2] = 3;

            uint256[] memory a = new uint256[](3);
            a[0] = 1;
            a[1] = 2;
            a[2] = 3;

            uint256 g0 = gasleft();
            arr.removeExpensive(1);
            uint256 g1 = gasleft();
            _removeExpensive(a, 1);
            uint256 g2 = gasleft();

            emit log_named_uint("Library removeExpensive gas", g0 - g1);
            emit log_named_uint("Solidity removeExpensive gas", g1 - g2);

            assertLt(g0 - g1, g1 - g2);
        }
    }

    function test_reverseDifference() public {
        unchecked {
            uint256[] memory arr = new uint256[](3);
            arr[0] = 1;
            arr[1] = 2;
            arr[2] = 3;

            uint256[] memory a = new uint256[](3);
            a[0] = 1;
            a[1] = 2;
            a[2] = 3;

            uint256 g0 = gasleft();
            arr.reverse();
            uint256 g1 = gasleft();
            _reverse(a);
            uint256 g2 = gasleft();

            emit log_named_uint("Library reverse gas", g0 - g1);
            emit log_named_uint("Solidity reverse gas", g1 - g2);

            assertLt(g0 - g1, g1 - g2);
        }
    }

    function test_unSortedSearchDifference() public {
        unchecked {
            uint256[] memory arr = new uint256[](3);
            arr[0] = 1;
            arr[1] = 3;
            arr[2] = 2;

            uint256 g0 = gasleft();
            arr.unSortedSearch(3);
            uint256 g1 = gasleft();
            _unSortedSearch(arr, 3);
            uint256 g2 = gasleft();

            emit log_named_uint("Library unSortedSearch gas", g0 - g1);
            emit log_named_uint("Solidity unSortedSearch gas", g1 - g2);

            assertLt(g0 - g1, g1 - g2);
        }
    }

    function test_sortedSearchDifference() public {
        unchecked {
            uint256[] memory arr = new uint256[](3);
            arr[0] = 1;
            arr[1] = 2;
            arr[2] = 3;

            uint256 g0 = gasleft();
            arr.sortedSearch(2);
            uint256 g1 = gasleft();
            _sortedSearch(arr, 2);
            uint256 g2 = gasleft();

            emit log_named_uint("Library sortedSearch gas", g0 - g1);
            emit log_named_uint("Solidity sortedSearch gas", g1 - g2);

            assertLt(g0 - g1, g1 - g2);
        }
    }

    function test_sliceDifference() public {
        unchecked {
            uint256[] memory arr = new uint256[](3);
            arr[0] = 1;
            arr[1] = 2;
            arr[2] = 3;

            uint256[] memory a = new uint256[](3);
            a[0] = 1;
            a[1] = 2;
            a[2] = 3;

            uint256 g0 = gasleft();
            arr.slice(1, 2);
            uint256 g1 = gasleft();
            _slice(a, 1, 2);
            uint256 g2 = gasleft();

            emit log_named_uint("Library slice gas", g0 - g1);
            emit log_named_uint("Solidity slice gas", g1 - g2);

            assertLt(g0 - g1, g1 - g2);
        }
    }

    function test_concatDifference() public {
        unchecked {
            uint256[] memory arr = new uint256[](3);
            arr[0] = 1;
            arr[1] = 2;
            arr[2] = 3;

            uint256[] memory a = new uint256[](3);
            a[0] = 1;
            a[1] = 2;
            a[2] = 3;

            uint256 g0 = gasleft();
            arr.concat(a);
            uint256 g1 = gasleft();
            _concat(arr, a);
            uint256 g2 = gasleft();

            emit log_named_uint("Library concat gas", g0 - g1);
            emit log_named_uint("Solidity concat gas", g1 - g2);

            assertLt(g0 - g1, g1 - g2);
        }
    }
}
