// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    动态字节数组转string
 */
contract BytesToString{

    bytes public name = 'veshen';

    function translateByteToString()
        public
        view
        returns(string memory)
    {
        return string(name);
    }

}