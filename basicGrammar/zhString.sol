// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ZhString{

    string public name = '%^&*^&*';

    function getLength()
        public
        view
        returns(uint)
    {
        return bytes(name).length;
    }

}


