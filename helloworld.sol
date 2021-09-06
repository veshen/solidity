pragma solidity ^0.4.0;

contract Helloworld {
    string Myname = "helloworld";

    function getName() public view returns (string) {
        return Myname;
    }

    function changeName(string _newName) public {
        Myname = _newName;
    }
}
