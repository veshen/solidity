// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


/**
    改变固定长度字节数组
 */
contract ChangeFixBytes{

    bytes6 public name = 'veshen';

    function changeBytes1()
        public
        view
        returns(bytes3)
    {
        return bytes3(name);
    }

}