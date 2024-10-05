<div align="center">
  <img src="logo.svg" alt="sarl" height="250" />
  <br>
  <a href="https://soldeer.xyz/project/sarl">
    <img src="https://img.shields.io/badge/soldeer-0.3.0-blue">
  </a>
  <a href="https://github.com/whisskey/sarl/actions/workflows/ci.yml">
    <img src="https://img.shields.io/github/actions/workflow/status/whisskey/sarl/ci.yml?branch=main&label=build">
  </a>
  <a href="https://github.com/whisskey/sarl/actions/workflows/ci-all-via-ir.yml">
    <img src="https://img.shields.io/badge/solidity-%3E=0.8.4%20%3C=0.8.27-aa6746">
  </a>
  <br>
</div>

## Overview

SARL is an optimized set of libraries for dynamic array management in Solidity. These libraries focus on memory safety, gas efficiency, and low-level array operations for high-performance applications in smart contract development.

## Installation

To use SARL in your project, you can install it via the Solidity package manager or simply include the libraries in your repository:

```
forge soldeer install sarl~1.0.0
```

## Libraries

### DynamicArrayLib

`DynamicArrayLib` provides a custom array structure mimicking dynamic array behavior in memory, allowing optimized manipulation and dynamic resizing while minimizing gas consumption.

#### Example Usage

```solidity
import { Array, DynamicArrayLib } from "Sarl";

contract Example {
    function exampleFunction(uint256 v) public view returns (uint256) {
        Array arr = DynamicArrayLib.create(1);

        return arr.push(v).get(0);
    }
}
```

### UnsafeLib

`UnsafeLib` Provides low-level, unsafe operations for direct memory manipulation, allowing advanced use cases while requiring careful usage to avoid memory issues.

#### Example Usage

```solidity
import { Array, DynamicArrayLib, UnsafeLib } from "Sarl";

contract Example {
    using UnsafeLib for Array;

    function exampleFunction(uint256 i, uint256 v) public pure returns (uint256) {
        Array arr = DynamicArrayLib.create(1);

        return arr.unsafe_set(i, v).unsafe_get(i);
    }
}
```

### ArrayLib

`ArrayLib` Facilitates efficient operations on arrays, including memory management functions like malloc and free. It prioritizes gas efficiency and robust error handling.

#### Example Usage

```solidity
import { ArrayLib } from "Sarl";

contract Example {
    using ArrayLib for uint256[];

    function exampleFunction(uint256 i, uint256 v) public pure returns (uint256) {
        uint256[] memory arr = ArrayLib.malloc(2);

        return arr.set(i, v).get(i);
    }
}
```

#### Gas costs

The following table shows gas consumption for common array operations in SARL's ArrayLib versus Solidity’s built-in array. 
| op             |  ArrayLib |  Solidity |
|----------------|-----------|-----------|
|new             |    54     |    112    |
|set             |    24     |    73     |
|get             |    9      |    47     | 
|reset           |    81     |    195    |
|hash            |    9      |    350    |
|swap            |    189    |    364    |
|insertionSort   |    370    |    944    |
|removeCheap     |    183    |    816    |
|removeExpensive |    211    |    745    |
|reverse         |    192    |    416    |
|unSortedSearch  |    224    |    318    |
|sortedSearch    |    206    |    274    |
|slice           |    260    |    545    |
|concat          |    607    |    1364   |



## Safety

SARL is an evolving project and is provided without any guarantees, on an "as is" basis.

We offer no warranties and cannot be held responsible for any potential issues or losses resulting from the use of this library. While SARL has been rigorously tested, interactions with other code or changes in future Solidity versions may introduce unexpected behavior.

It's essential that you run your own thorough tests when integrating SARL into your projects, ensuring that it works seamlessly with your specific setup. Always validate its behavior to avoid surprises.

## Contributing

Contributions are welcome! If you'd like to contribute, please fork the repository and submit a pull request. Make sure to follow the contribution guidelines in the [CONTRIBUTING](./CONTRIBUTING.md) file.

## License

This project is licensed under the [MIT](LICENSE) license. 