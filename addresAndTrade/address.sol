 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.7;

 /**
    什么是地址
    address  160位 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 
    uint160

    部署之后会生成一个合约地址 合约地址存储在区块链上

    账户有两个 1.外部账户 2.合约账户
    地址之间可以互相比较 == < > !=
  */

contract AddressTest{
    address public account = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    function changeIt()
      public
      view
      returns(uint160)
    {
      return uint160(account);
      //会返回地址对应的uint160形式的数字 0:
      // uint160: 520786028573371803640530888255888666801131675076
    }

    function changeIt2()
      public
      view
      returns(address)
    {
      return address(uint160(account));
    }
}

