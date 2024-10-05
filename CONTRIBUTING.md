# Contributing

We welcome contributions to the SARL project! Whether you want to open an issue, start a discussion, or submit a pull request (PR), your input is appreciated. Contributions are encouraged from anyone interested in improving the project through bug fixes, readability enhancements, gas optimization, or new features.

## Pre-Requisites

You will need the following software on your machine:

- [Git](https://git-scm.com/downloads)
- [Foundry](https://github.com/foundry-rs/foundry)

Familiarity with [Solidity](https://soliditylang.org/) is also essential.

## Set Up

Clone this repository:

```sh
$ git clone https://github.com/whisskey/sarl.git
```

Inside the project's directory, run the following to install dependencies and build the contracts:

```sh
$ forge install
$ forge build
```
Now you can start making changes.

## Pull Requests

When submitting a pull request, ensure the following:

- All tests pass.
- Code coverage remains the same or improves.
- All new code adheres to the following style guide:
  - All lint checks pass.
  - Comments must end with periods.
  - Use an underscore prefix for private and internal functions and variables.
  - Backquote variables and code expressions in comments (e.g., b).
  - Memory addresses and constants should be in hexadecimal format (e.g., 0x20).
  - Keep maximum line length, including comments, to 100 characters or below for better readability.
  - Constants must be in ALL_CAPS; prefix private or internal constants with an underscore.
- If making changes to the contracts:
  - Gas snapshots are provided, demonstrating improvements or acceptable trade-offs.
  - Reference contracts are updated accordingly if relevant.
  - New tests are added for all new features or code paths.
- A descriptive summary of the PR has been provided.

#### Thank you for contributing to SARL ♡