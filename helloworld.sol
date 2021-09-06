pragma solidity ^0.4.0;

contract Helloworld {
    string Myname = "helloworld";

    /**
        view 不消耗eth
     */
    function getName() public view returns (string) {
        return Myname;
    }

    function changeName(string _newName) public {
        Myname = _newName;
    }

    /**
        pure 不会读取数据 固定的输入输出 不消耗
     */
    function pureTest(string _name) public pure returns (string) {
        return _name;
    }
}
