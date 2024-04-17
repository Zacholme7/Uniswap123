pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";




// inherit from the ERC20 token contract 
contract Token is ERC20 {
  // construct a new token
  // takes a name, symbol, inital supply and calls the ERC20
  // token constructor and then mints the initial supply to
  // the owners address
  constructor(
    string memory name,
    string memory symbol,
    uint256 initlaSupply
  ) ERC20(name, symbol) {
    _mint(msg.sender, initialSupply);
  }
}



