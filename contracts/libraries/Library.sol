// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This library has the state variables 'contractAddress' and 'name'
library Library {

  // defining state variables
  struct DiamondStorage {
    address contractAddress;
    string name;
    // ... any number of other state variables
  }

  // return a struct storage pointer for accessing the state variables
  function diamondStorage() 
    internal 
    pure 
    returns (DiamondStorage storage ds) 
  {
    bytes32 position = keccak256("diamond.standard.diamond.storage");
    assembly { ds.slot := position }
  }

  // set state variables
  function setStateVariables(
    address _contractAddress, 
    string memory _name
  ) 
    internal 
  {
    DiamondStorage storage ds = diamondStorage();
    ds.contractAddress = _contractAddress;
    ds.name = _name;
  }

  // get contractAddress state variable
  function contractAddress() internal view returns (address) {
    return diamondStorage().contractAddress;
  }

  // get name state variable
  function name() internal view returns (string memory) {
    return diamondStorage().name;
  }
}

// This contract uses the library to set and retrieve state variables 
contract ContractA {

  function setState() external {
    Library.setStateVariables(address(this), "My Name");
  }

  function getState() 
    external 
    view 
    returns (address contractAddress, string memory name) 
  {
    contractAddress = Library.contractAddress();
    name = Library.name();
  }
}