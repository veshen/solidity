// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract modifierTest2{

    uint public level = 0;
    string public name = '';
    uint public DNA = 0;

    modifier viLevel(uint _level){
        require(level>=_level);
        _;
    }

    function changeName(string memory _name)
        public
        viLevel(2)
    {
        name = _name;
    }

    function changeDNA(uint _DNA)
        public
        viLevel(10)
    {
        DNA = _DNA;
    }
}