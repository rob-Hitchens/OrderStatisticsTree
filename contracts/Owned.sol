pragma solidity 0.4.25;

interface OwnedInterface {
    function getOwner() external view returns(address owner);
    function changeOwner(address newOwner) external returns (bool success);
}

contract Owned is OwnedInterface {
    
    address private contractOwner;
  
    event LogOwnerChanged(
        address newOwner);

    modifier onlyOwner {
        require(msg.sender == contractOwner);
        _;
    } 
  
    constructor() public {
        contractOwner = msg.sender;
    }

    function getOwner() public view returns(address owner) {
        return contractOwner;
    }
  
    function changeOwner(address newOwner) 
        public
        onlyOwner 
        returns(bool success) 
    {
        require(newOwner != 0);
        emit LogOwnerChanged(newOwner);
        contractOwner = newOwner;
        return true;
    }
}
