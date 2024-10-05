// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.27;

import { Array, DynamicArrayLib, UnsafeLib } from "src/libraries/UnsafeLib.sol";

import { SarlTest } from "test/utils/SarlTest.sol";

contract UnsafeLibTest is SarlTest {
    using UnsafeLib for Array;

    function setUp() public { }

    function test_unsafePtr() public pure {
        unchecked {
            Array arr = DynamicArrayLib.create(1);
            arr.set(0, 1);

            uint256 expected = arr.get(0);

            Array ptr = arr.unsafe_ptr(0);

            uint256 result = _loadPtr(Array.unwrap(ptr));

            assertEq(expected, result);
        }
    }

    function test_unsafeClear() public pure {
        unchecked {
            uint128 lmt = 1;

            Array arr = DynamicArrayLib.create(1);
            arr.set(0, 1);

            arr.unsafe_clear();

            assertEq(arr.length(), 0);
            assertEq(arr.limit(), lmt);
        }
    }

    function test_unsafeResize() public pure {
        unchecked {
            Array arr = DynamicArrayLib.create(2);
            arr.set(0, 1);

            uint256 currentLen = arr.length();

            arr.unsafe_resize(currentLen + 1);

            assertEq(arr.length(), currentLen + 1);
        }
    }

    function test_unsafeSetAndGet() public pure {
        unchecked {
            uint128 lmt = 5;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.unsafe_set(i, i ^ 2);
            }
            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.unsafe_get(i), i ^ 2);
            }
        }
    }

    function test_unsafeSetAndGet_uint256() public pure {
        unchecked {
            uint128 lmt = 5;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.unsafe_set(i, i ^ 2);
            }
            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.unsafe_getUint256(i), i ^ 2);
            }
        }
    }

    function test_unsafeSetAndGet_address() public pure {
        unchecked {
            address data = vm.addr(1);

            Array arr = DynamicArrayLib.create(2);

            assertEq(arr.unsafe_set(0, data).unsafe_getAddress(0), data);
        }
    }

    function test_unsafeSetAndGet_bool() public view {
        unchecked {
            bool data = vm.isPersistent(address(0x1));

            Array arr = DynamicArrayLib.create(2);

            assertEq(arr.unsafe_set(0, data).unsafe_getBool(0), data);
        }
    }

    function test_unsafeSetAndGet_bytes32() public pure {
        unchecked {
            bytes32 data = keccak256("sarl");

            Array arr = DynamicArrayLib.create(2);

            assertEq(arr.unsafe_set(0, data).unsafe_getBytes32(0), data);
        }
    }

    function test_unsafePop() public pure {
        unchecked {
            uint128 lmt = 10;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
                length += 1;
            }

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.unsafe_pop(), 9 - i);

                length -= 1;
                assertEq(arr.length(), length);
            }
        }
    }

    function test_unsafePopUint256() public pure {
        unchecked {
            uint128 lmt = 10;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
                length += 1;
            }

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.unsafe_popUint256(), 9 - i);

                length -= 1;
                assertEq(arr.length(), length);
            }
        }
    }

    function test_unsafePopAddress() public pure {
        unchecked {
            address data = vm.addr(1);
            Array arr = DynamicArrayLib.create(2);

            assertEq(arr.set(0, data).unsafe_popAddress(), data);
            assertEq(arr.length(), 0);
        }
    }

    function test_unsafePopBool() public view {
        unchecked {
            Array arr = DynamicArrayLib.create(2);
            bool data = vm.isPersistent(address(0x1));

            assertEq(arr.set(0, data).unsafe_popBool(), data);
            assertEq(arr.length(), 0);
        }
    }

    function test_unsafePopBytes32() public pure {
        unchecked {
            Array arr = DynamicArrayLib.create(2);
            bytes32 data = keccak256("sarl");

            assertEq(arr.set(0, data).unsafe_popBytes32(), data);
            assertEq(arr.length(), 0);
        }
    }

    function test_unsafePush() public pure {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.unsafe_push(i ^ 2);
                length += 1;
            }
            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.get(i), i ^ 2);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_unsafePush_address() public pure {
        unchecked {
            address data = vm.addr(1);
            Array arr = DynamicArrayLib.create(1);

            assertEq(arr.unsafe_push(data).getAddress(0), data);
            assertEq(arr.length(), 1);
        }
    }

    function test_unsafePush_bool() public view {
        unchecked {
            Array arr = DynamicArrayLib.create(1);
            bool data = vm.isPersistent(address(0x1));

            assertEq(arr.unsafe_push(data).getBool(0), data);
            assertEq(arr.length(), 1);
        }
    }

    function test_unsafePush_bytes32() public pure {
        unchecked {
            Array arr = DynamicArrayLib.create(1);
            bytes32 data = keccak256("sarl");

            assertEq(arr.unsafe_push(data).getBytes32(0), data);
            assertEq(arr.length(), 1);
        }
    }

    function test_unsafeGetAll() public pure {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
                length += 1;
            }

            uint256[] memory result = arr.unsafe_getAll();

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.get(i), result[i]);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_unsafeGetUint256All() public pure {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
                length += 1;
            }

            uint256[] memory result = arr.unsafe_getUint256All();

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.get(i), result[i]);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_unsafeGetAddressAll() public pure {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, vm.addr(i + 1));
                length += 1;
            }

            address[] memory result = arr.unsafe_getAddressAll();

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.getAddress(i), result[i]);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_unsafeGetBoolAll() public view {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, vm.isPersistent(vm.addr(i + 1)));
                length += 1;
            }

            bool[] memory result = arr.unsafe_getBoolAll();

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.getBool(i), result[i]);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_unsafeGetBytes32All() public pure {
        unchecked {
            uint128 lmt = 5;
            uint256 length = 0;

            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, keccak256(abi.encodePacked(i)));
                length += 1;
            }

            bytes32[] memory result = arr.unsafe_getBytes32All();

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.getBytes32(i), result[i]);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_unsafeSwap() public pure {
        unchecked {
            uint128 lmt = 3;
            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
            }

            uint256[] memory b = arr.getAll();
            b = _swap(b, 1, 2);

            arr.unsafe_swap(1, 2);

            for (uint256 i; i != lmt; ++i) {
                assertEq(arr.get(i), b[i]);
            }
        }
    }

    function test_unsafeRemoveCheap() public pure {
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

            arr.unsafe_removeCheap(2);
            length -= 1;

            for (uint256 i; i != length; ++i) {
                assertEq(arr.get(i), b[i]);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_unsafeRemoveExpensive() public pure {
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

            arr.unsafe_removeExpensive(2);
            length -= 1;

            for (uint256 i; i != length; ++i) {
                assertEq(arr.get(i), b[i]);
            }

            assertEq(arr.length(), length);
        }
    }

    function test_unsafeSearch() public pure {
        unchecked {
            uint128 lmt = 3;
            Array arr = DynamicArrayLib.create(lmt);

            for (uint256 i; i != lmt; ++i) {
                arr.set(i, i);
            }

            bool expectedFound = arr.unsafe_search(2);

            uint256[] memory b = arr.getAll();
            (, bool actualFound) = _unSortedSearch(b, 2);

            assertEq(expectedFound, actualFound);
        }
    }

    function test_unsafeWrap() public pure {
        unchecked {
            uint256 length = 6;
            uint256[] memory b = new uint256[](length);
            b[0] = 1;
            b[1] = 2;
            b[2] = 3;
            b[3] = 4;
            b[4] = 5;
            b[5] = 6;

            Array arr = UnsafeLib.unsafe_wrap(b);

            for (uint256 i; i != length; ++i) {
                assertEq(arr.get(i), b[i]);
            }

            assertEq(arr.limit(), length);
            assertEq(arr.length(), length);
        }
    }

    function test_unsafeWrap_address() public pure {
        unchecked {
            uint256 length = 1;
            address[] memory b = new address[](length);
            b[0] = vm.addr(1);

            Array arr = UnsafeLib.unsafe_wrap(b);

            for (uint256 i; i != length; ++i) {
                assertEq(arr.getAddress(i), b[i]);
            }

            assertEq(arr.limit(), length);
            assertEq(arr.length(), length);
        }
    }

    function test_unsafeWrap_bool() public view {
        unchecked {
            uint256 length = 1;
            bool[] memory b = new bool[](length);
            b[0] = vm.isPersistent(address(0x1));

            Array arr = UnsafeLib.unsafe_wrap(b);

            for (uint256 i; i != length; ++i) {
                assertEq(arr.getBool(i), b[i]);
            }

            assertEq(arr.limit(), length);
            assertEq(arr.length(), length);
        }
    }

    function test_unsafeWrap_bytes32() public pure {
        unchecked {
            uint256 length = 1;
            bytes32[] memory b = new bytes32[](length);
            b[0] = keccak256("sarl");

            Array arr = UnsafeLib.unsafe_wrap(b);

            for (uint256 i; i != length; ++i) {
                assertEq(arr.getBytes32(i), b[i]);
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

            Array newArr = arr.unsafe_slice(start, end);

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

            Array newArr = arrOne.unsafe_concat(arrTwo);

            for (uint256 i; i != totalLength; ++i) {
                assertEq(newArr.get(i), c[i]);
            }

            assertEq(newArr.length(), totalLength);
        }
    }
}
