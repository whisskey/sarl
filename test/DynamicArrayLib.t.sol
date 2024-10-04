// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.27;

import { Array, DynamicArrayLib } from "src/libraries/DynamicArrayLib.sol";

import { SarlTest } from "test/utils/SarlTest.sol";

contract DynamicArrayLibTest is SarlTest {
    error outOfBounds();
    error invalidRange();
    error emptyArray();

    function setUp() public { }

    function test_create() public pure {
        unchecked {
            uint128 lmt = 1;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            _checkMemory(arr);

            assertEq(arr.length(), length);
            assertEq(arr.limit(), lmt);
        }
    }

    function test_length() public pure {
        unchecked {
            Array arr;

            uint256 result = arr.length();
            uint256 expected = 0;

            assertEq(result, expected);
        }
    }

    function test_limit() public pure {
        unchecked {
            Array arr;

            uint256 result = arr.limit();
            uint256 expected = 0;

            assertEq(result, expected);
        }
    }

    function test_reset() public pure {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i + 1);
                length += 1;
            }

            arr.reset();

            _checkMemory(arr);

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.get(i), 0);
            }

            assertEq(arr.length(), length);
            assertEq(arr.limit(), lmt);
        }
    }

    function test_hash() public pure {
        unchecked {
            Array arr = DynamicArrayLib.create(2);

            arr.set(0, 1);
            arr.set(1, 2);

            bytes32 expected = keccak256(abi.encodePacked(arr.getAll()));

            bytes32 result = arr.hash();

            assertEq(expected, result);
        }
    }

    function test_malloc() public pure {
        unchecked {
            uint128 lmt = 1;
            uint256 length = 0;

            Array arr = DynamicArrayLib.malloc(lmt);

            _checkMemory(arr);

            assertEq(arr.length(), length);
            assertEq(arr.limit(), lmt);
        }
    }

    function test_calloc() public pure {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.calloc(lmt);

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.get(i), 0);
                length += 1;
            }

            _checkMemory(arr);

            assertEq(arr.length(), length);
            assertEq(arr.limit(), lmt);
        }
    }

    function test_realloc_reducesLength_whenNewLimitIsSmaller() public view {
        unchecked {
            uint128 lmt = 3;
            Array arr = DynamicArrayLib.create(lmt);

            arr.set(0, 1);
            arr.set(1, 2);
            arr.set(2, 3);

            uint256 newLimit = lmt - 1;
            uint256 newtLength = arr.length() - 1;

            arr = arr.realloc(newLimit);

            _checkMemory(arr);

            assertEq(arr.limit(), newLimit);
            assertEq(arr.length(), newtLength);
        }
    }

    function test_realloc_reducesLimit_whenLengthIsWithinNewLimit() public view {
        unchecked {
            uint128 lmt = 3;
            Array arr = DynamicArrayLib.create(lmt);

            uint256 newLimit = lmt - 1;

            arr = arr.realloc(newLimit);

            _checkMemory(arr);

            assertEq(arr.limit(), newLimit);
        }
    }

    function test_realloc_increasesLimit_whenMemoryIsContiguous() public view {
        unchecked {
            uint128 lmt = 3;
            Array arr = DynamicArrayLib.create(lmt);

            uint256 newLimit = lmt + 1;

            arr = arr.realloc(newLimit);

            _checkMemory(arr);

            assertEq(arr.limit(), newLimit);
        }
    }

    function test_realloc_increasesLimit_whenMemoryIsNotContiguous() public view {
        unchecked {
            uint128 lmt = 3;
            Array arr = DynamicArrayLib.create(lmt);

            uint256 newLimit = lmt + 1;

            uint256[] memory b = new uint256[](1);
            b[0] = 1;

            Array newArr = arr.realloc(newLimit);

            _checkMemory(newArr);

            bytes32 fmp = _nextFmp(b);

            assertEq(newArr.limit(), newLimit);
            assertEq(Array.unwrap(newArr), fmp);
        }
    }

    function test_setAndGet() public pure {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i ^ 2);
                length += 1;
            }
            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.get(i), i ^ 2);
            }

            _checkMemory(arr);

            assertEq(arr.length(), length);
        }
    }

    function test_setAndGet_uint256() public pure {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i ^ 2);
                length += 1;
            }
            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.getUint256(i), i ^ 2);
            }

            _checkMemory(arr);

            assertEq(arr.length(), length);
        }
    }

    function test_setAndGet_address() public pure {
        unchecked {
            uint256 length = 0;
            address data = vm.addr(1);

            Array arr = DynamicArrayLib.create(2);

            _checkMemory(arr);

            assertEq(arr.set(0, data).getAddress(0), data);

            length += 1;
            assertEq(arr.length(), length);
        }
    }

    function test_setAndGet_bool() public view {
        unchecked {
            uint256 length = 0;
            bool data = vm.isPersistent(address(0x1));

            Array arr = DynamicArrayLib.create(2);

            _checkMemory(arr);

            assertEq(arr.set(0, data).getBool(0), data);

            length += 1;
            assertEq(arr.length(), length);
        }
    }

    function test_setAndGet_bytes32() public pure {
        unchecked {
            uint256 length = 0;
            bytes32 data = keccak256("sarl");

            Array arr = DynamicArrayLib.create(2);

            _checkMemory(arr);

            assertEq(arr.set(0, data).getBytes32(0), data);

            length += 1;
            assertEq(arr.length(), length);
        }
    }

    function test_pop() public pure {
        unchecked {
            uint128 lmt = 10;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
                length += 1;
            }

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.pop(), 9 - i);

                length -= 1;
                assertEq(arr.length(), length);
            }

            _checkMemory(arr);
        }
    }

    function test_popUint256() public pure {
        unchecked {
            uint128 lmt = 10;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
                length += 1;
            }

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.popUint256(), 9 - i);

                length -= 1;
                assertEq(arr.length(), length);
            }

            _checkMemory(arr);
        }
    }

    function test_popAddress() public pure {
        unchecked {
            address data = vm.addr(1);
            Array arr = DynamicArrayLib.create(2);

            assertEq(arr.set(0, data).popAddress(), data);
            assertEq(arr.length(), 0);
        }
    }

    function test_popBool() public view {
        unchecked {
            Array arr = DynamicArrayLib.create(2);
            bool data = vm.isPersistent(address(0x1));

            assertEq(arr.set(0, data).popBool(), data);
            assertEq(arr.length(), 0);
        }
    }

    function test_popBytes32() public pure {
        unchecked {
            Array arr = DynamicArrayLib.create(2);
            bytes32 data = keccak256("sarl");

            assertEq(arr.set(0, data).popBytes32(), data);
            assertEq(arr.length(), 0);
        }
    }

    function test_push_AddElement_whenLimitAvailable() public view {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.push(i ^ 2);
                length += 1;
            }
            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.get(i), i ^ 2);
            }

            _checkMemory(arr);

            assertEq(arr.length(), length);
        }
    }

    function test_push_expandArray_whenMemoryIsContiguous() public view {
        unchecked {
            uint128 lmt = 3;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            uint256 newLimit = lmt + 1;

            for (uint256 i; i != newLimit; ++i) {
                arr.push(i);
                length += 1;
            }

            for (uint256 i; i != newLimit; ++i) {
                assertEq(arr.get(i), i);
            }

            _checkMemory(arr);

            assertEq(arr.limit(), newLimit);
            assertEq(arr.length(), length);
        }
    }

    function test_push_reallocateArray_whenMemoryIsNotContiguous() public view {
        unchecked {
            uint128 lmt = 3;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            uint256 newLimit = lmt + 1;

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
                length += 1;
            }

            uint256[] memory b = new uint256[](1);
            b[0] = 1;

            Array newArr = arr.push(3);
            length += 1;

            _checkMemory(newArr);

            bytes32 fmp = _nextFmp(b);

            assertEq(newArr.get(length - 1), 3);
            assertEq(newArr.limit(), newLimit);
            assertEq(Array.unwrap(newArr), fmp);
            assertEq(newArr.length(), length);
        }
    }

    function test_push_address() public view {
        unchecked {
            address data = vm.addr(1);
            Array arr = DynamicArrayLib.create(1);

            assertEq(arr.push(data).getAddress(0), data);
            assertEq(arr.length(), 1);
        }
    }

    function test_push_bool() public view {
        unchecked {
            Array arr = DynamicArrayLib.create(1);
            bool data = vm.isPersistent(address(0x1));

            assertEq(arr.push(data).getBool(0), data);
            assertEq(arr.length(), 1);
        }
    }

    function test_push_bytes32() public view {
        unchecked {
            Array arr = DynamicArrayLib.create(1);
            bytes32 data = keccak256("sarl");

            assertEq(arr.push(data).getBytes32(0), data);
            assertEq(arr.length(), 1);
        }
    }

    function test_getAll() public pure {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
                length += 1;
            }

            uint256[] memory result = arr.getAll();

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.get(i), result[i]);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_getUint256All() public pure {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
                length += 1;
            }

            uint256[] memory result = arr.getAll();

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.get(i), result[i]);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_getAddressAll() public pure {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, vm.addr(i + 1));
                length += 1;
            }

            address[] memory result = arr.getAddressAll();

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.getAddress(i), result[i]);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_getBoolAll() public view {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, vm.isPersistent(vm.addr(i + 1)));
                length += 1;
            }

            bool[] memory result = arr.getBoolAll();

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.getBool(i), result[i]);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_getBytes32All() public pure {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, keccak256(abi.encodePacked(i)));
                length += 1;
            }

            bytes32[] memory result = arr.getBytes32All();

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.getBytes32(i), result[i]);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_swap() public pure {
        unchecked {
            uint128 lmt = 3;
            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
            }

            uint256[] memory b = arr.getAll();
            b = _swap(b, 1, 2);

            arr.swap(1, 2);

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.get(i), b[i]);
            }
        }
    }

    function test_insertionSort() public pure {
        unchecked {
            Array arr = DynamicArrayLib.create(6);

            arr.set(0, 1);
            arr.set(1, 3);
            arr.set(2, 2);
            arr.set(3, 8);
            arr.set(4, 6);
            arr.set(5, 5);

            arr.insertionSort();

            assertTrue(_isSorted(arr.getAll()));
        }
    }

    function test_removeCheap() public pure {
        unchecked {
            uint128 lmt = 3;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
                length += 1;
            }

            uint256[] memory b = arr.getAll();
            b = _removeCheap(b, 2);

            arr.removeCheap(2);
            length -= 1;

            _checkMemory(arr);

            for (uint256 i; i != length; ++i) {
                assertEq(arr.get(i), b[i]);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_removeExpensive() public pure {
        unchecked {
            uint128 lmt = 3;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
                length += 1;
            }

            uint256[] memory b = arr.getAll();
            b = _removeExpensive(b, 2);

            arr.removeExpensive(2);
            length -= 1;

            _checkMemory(arr);

            for (uint256 i; i != length; ++i) {
                assertEq(arr.get(i), b[i]);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_reverse() public pure {
        unchecked {
            uint128 lmt = 3;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
            }

            arr.reverse();

            _checkMemory(arr);

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.get(i), 2 - i);
            }
        }
    }

    function test_unSortedSearch() public pure {
        unchecked {
            uint128 lmt = 3;
            Array arr = DynamicArrayLib.create(lmt);

            arr.set(0, 1);
            arr.set(1, 11);
            arr.set(2, 2);

            (uint256 expectedIndex, bool expectedFound) = arr.unSortedSearch(11);

            uint256[] memory b = arr.getAll();
            (uint256 actualIndex, bool actualFound) = _unSortedSearch(b, 11);

            assertEq(expectedFound, actualFound);
            assertEq(expectedIndex, actualIndex);
        }
    }

    function test_unSortedSearch_whenElementNotInArray() public pure {
        unchecked {
            uint128 lmt = 3;
            Array arr = DynamicArrayLib.create(lmt);

            arr.set(0, 1);
            arr.set(1, 11);
            arr.set(2, 2);

            (uint256 expectedIndex, bool expectedFound) = arr.unSortedSearch(32);

            uint256[] memory b = arr.getAll();
            (uint256 actualIndex, bool actualFound) = _unSortedSearch(b, 32);

            assertEq(expectedFound, actualFound);
            assertEq(expectedIndex, actualIndex);
        }
    }

    function test_sortedSearch() public pure {
        unchecked {
            uint128 lmt = 3;
            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
            }

            (uint256 expectedIndex, bool expectedFound) = arr.sortedSearch(2);

            uint256[] memory b = arr.getAll();
            (uint256 actualIndex, bool actualFound) = _sortedSearch(b, 2);

            assertEq(expectedFound, actualFound);
            assertEq(expectedIndex, actualIndex);
        }
    }

    function test_sortedSearch_whenElementNotInArray() public pure {
        unchecked {
            uint128 lmt = 3;
            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
            }

            (uint256 expectedIndex, bool expectedFound) = arr.sortedSearch(32);

            uint256[] memory b = arr.getAll();
            (uint256 actualIndex, bool actualFound) = _sortedSearch(b, 32);

            assertEq(expectedFound, actualFound);
            assertEq(expectedIndex, actualIndex);
        }
    }

    function test_flipCustomArr() public pure {
        unchecked {
            uint256 length = 6;
            uint256[] memory b = new uint256[](length);
            b[0] = 1;
            b[1] = 2;
            b[2] = 3;
            b[3] = 4;
            b[4] = 5;
            b[5] = 6;

            Array arr = DynamicArrayLib.flipCustomArr(b);

            _checkMemory(arr);

            for (uint256 i; i != length; ++i) {
                assertEq(arr.get(i), b[i]);
            }

            assertEq(arr.limit(), length);
            assertEq(arr.length(), length);
        }
    }

    function test_slice() public pure {
        unchecked {
            uint128 lmt = 6;
            uint256 start = 2;
            uint256 end = 4;
            uint256 newLength = end - start;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
            }

            uint256[] memory b = arr.getAll();
            b = _slice(b, start, end);

            Array newArr = arr.slice(start, end);

            _checkMemory(newArr);

            for (uint256 i; i != newLength; ++i) {
                assertEq(newArr.get(i), b[i]);
            }

            assertEq(newArr.length(), newLength);
        }
    }

    function test_concat() public pure {
        unchecked {
            uint128 lmt = 3;

            Array arrOne = DynamicArrayLib.create(lmt);
            Array arrTwo = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arrOne.set(i, i);
            }

            for (uint256 i; i != lmt; ++i) {
                arrTwo.set(i, i);
            }

            uint256 totalLength = arrOne.length() + arrTwo.length();

            uint256[] memory b = arrOne.getAll();
            uint256[] memory c = arrTwo.getAll();

            c = _concat(b, c);

            Array newArr = arrOne.concat(arrTwo);

            _checkMemory(newArr);

            for (uint256 i; i != totalLength; ++i) {
                assertEq(newArr.get(i), c[i]);
            }

            assertEq(newArr.length(), totalLength);
        }
    }

    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/
    /*                        REVERTS                               */
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/

    function test_set_uint256_reverts_whenIndexDoesNotExist() public {
        Array arr = DynamicArrayLib.create(1);

        vm.expectRevert(DynamicArrayLib.IndexDoesNotExist.selector);
        arr.set(2, 1);
    }

    function test_set_address_reverts_whenIndexDoesNotExist() public {
        Array arr = DynamicArrayLib.create(1);
        address data = vm.addr(1);

        vm.expectRevert(DynamicArrayLib.IndexDoesNotExist.selector);
        arr.set(2, data);
    }

    function test_set_bool_reverts_whenIndexDoesNotExist() public {
        Array arr = DynamicArrayLib.create(1);
        bool data = vm.isPersistent(address(0x1));

        vm.expectRevert(DynamicArrayLib.IndexDoesNotExist.selector);
        arr.set(2, data);
    }

    function test_set_bytes32_reverts_whenIndexDoesNotExist() public {
        Array arr = DynamicArrayLib.create(1);
        bytes32 data = keccak256("sarl");

        vm.expectRevert(DynamicArrayLib.IndexDoesNotExist.selector);
        arr.set(2, data);
    }

    function test_get_reverts_whenIndexDoesNotExist() public {
        Array arr = DynamicArrayLib.create(1);
        arr.set(0, 1);

        vm.expectRevert(DynamicArrayLib.IndexDoesNotExist.selector);
        arr.get(1);
    }

    function test_getUint256_reverts_whenIndexDoesNotExist() public {
        Array arr = DynamicArrayLib.create(1);
        arr.set(0, 1);

        vm.expectRevert(DynamicArrayLib.IndexDoesNotExist.selector);
        arr.getUint256(1);
    }

    function test_getAddress_reverts_whenIndexDoesNotExist() public {
        Array arr = DynamicArrayLib.create(1);
        address data = vm.addr(1);
        arr.set(0, data);

        vm.expectRevert(DynamicArrayLib.IndexDoesNotExist.selector);
        arr.getAddress(1);
    }

    function test_getBool_reverts_whenIndexDoesNotExist() public {
        Array arr = DynamicArrayLib.create(1);
        bool data = vm.isPersistent(address(0x1));
        arr.set(0, data);

        vm.expectRevert(DynamicArrayLib.IndexDoesNotExist.selector);
        arr.getBool(1);
    }

    function test_getBytes32_reverts_whenIndexDoesNotExist() public {
        Array arr = DynamicArrayLib.create(1);
        bytes32 data = keccak256("sarl");
        arr.set(0, data);

        vm.expectRevert(DynamicArrayLib.IndexDoesNotExist.selector);
        arr.getBytes32(1);
    }

    function test_pop_reverts_whenArrayEmpty() public {
        Array arr = DynamicArrayLib.create(0);

        vm.expectRevert(DynamicArrayLib.EmptyArray.selector);
        arr.pop();
    }

    function test_popUint256_reverts_whenArrayEmpty() public {
        Array arr = DynamicArrayLib.create(0);

        vm.expectRevert(DynamicArrayLib.EmptyArray.selector);
        arr.popUint256();
    }

    function test_popAddress_reverts_whenArrayEmpty() public {
        Array arr = DynamicArrayLib.create(0);

        vm.expectRevert(DynamicArrayLib.EmptyArray.selector);
        arr.popAddress();
    }

    function test_popBool_reverts_whenArrayEmpty() public {
        Array arr = DynamicArrayLib.create(0);

        vm.expectRevert(DynamicArrayLib.EmptyArray.selector);
        arr.popBool();
    }

    function test_popBytes32_reverts_whenArrayEmpty() public {
        Array arr = DynamicArrayLib.create(0);

        vm.expectRevert(DynamicArrayLib.EmptyArray.selector);
        arr.popBytes32();
    }

    function test_swap_reverts_whenOutOfBounds() public {
        Array arr = DynamicArrayLib.create(2);
        arr.set(0, 1);
        arr.set(1, 2);

        vm.expectRevert(DynamicArrayLib.OutOfBounds.selector);
        arr.swap(0, 2);
    }

    function test_removeCheap_reverts_whenOutOfBounds() public {
        Array arr = DynamicArrayLib.create(2);
        arr.set(0, 1);
        arr.set(1, 2);

        vm.expectRevert(DynamicArrayLib.OutOfBounds.selector);
        arr.removeCheap(2);
    }

    function test_removeExpensive_reverts_whenOutOfBounds() public {
        Array arr = DynamicArrayLib.create(2);
        arr.set(0, 1);
        arr.set(1, 2);

        vm.expectRevert(DynamicArrayLib.OutOfBounds.selector);
        arr.removeExpensive(2);
    }

    function test_slice_reverts_whenOutOfBounds() public {
        Array arr = DynamicArrayLib.create(3);
        arr.set(0, 1);
        arr.set(1, 2);
        arr.set(2, 3);

        vm.expectRevert(DynamicArrayLib.OutOfBounds.selector);
        arr.slice(1, 4);
    }

    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/
    /*                        HELPERS                               */
    /*&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%&&%+&/%*/

    function _checkMemory(Array a) internal pure {
        bool insufficientMalloc;
        assembly ("memory-safe") {
            // Write ones to the free memory, to make subsequent checks fail if
            // insufficient memory is allocated.
            mstore(mload(0x40), not(0))
            // Check if the memory allocated is sufficient.
            insufficientMalloc := gt(add(add(a, 0x20), shl(5, shr(128, mload(a)))), mload(0x40))
        }
        if (insufficientMalloc) {
            revert("Insufficient memory allocation!");
        }
        _checkMemory();
    }
}
