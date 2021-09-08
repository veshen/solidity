pragma solidity ^0.8.7;

contract Helloworld {
    string Myname = "helloworld";

    /**
        view 不消耗eth
     */
    function getName() public view returns (string memory) {
        return Myname;
    }

    function changeName(string memory _newName) public {
        Myname = _newName;
    }

    /**
        pure 不会读取数据 固定的输入输出 不消耗
     */
    function pureTest(string memory _name) public pure returns (string memory) {
        return _name;
    }
}
