
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GameCore {
    // get the greeting string declared in the DiamondStorage
    string public versions;
    
    constructor() {
        versions = '0.0.0';
    }

    function getGreeting() public view returns (string memory) {
        return libGameCoreStorage.getGreeting();
    }

    // update greeting string declared in the DiamondStorage
    function setGreeting(string memory _newGreeting) public {
        libGameCoreStorage.setGreeting(_newGreeting);
    }
}

library libGameCoreStorage {
    bytes32 constant SIMPLE_STORAGE_POSITION = keccak256("diamond.standard.simple.storage");

    struct simpleStorage {
        string greeting;
    }

    // we declare this function in this library to be used in our "SImpleStorage" facet
    function getGreeting() internal view returns (string memory) {
        return diamondStorage().greeting;
    }

    // we declare this function in this library to be used in our "SImpleStorage" facet
    function setGreeting(string memory _newGreeting) internal {
        diamondStorage().greeting = _newGreeting;
    }

    function diamondStorage() internal pure returns (simpleStorage storage ds) {
        bytes32 position = SIMPLE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
