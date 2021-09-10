// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Crowdfunding{
    //受益者
    struct needer{
        address NeederAddress; //众筹者address
        uint goal; //总众筹金额
        uint amount; //已众筹金额
        uint funderAccount; //捐赠者数量
        // mapping(uint => funder) map;
    }
    //捐赠者
    struct funder{
        address FunderAddress;
        uint goal;
        uint amount;
    }
    uint neederAmount = 0;
    mapping(uint => needer) neederMap;
    //创建募捐者
    function newNedder(address _addr,uint _goal)
        public
    {
        neederAmount++;
        neederMap[neederAmount] = needer(_addr,_goal,0,0);

        // Needer storage c = neederMap[amountTotal];
        // c.NeederAddress = _addr;
        // c.goal = _goal;
    }
    // 捐赠
    function contribute(uint _neederAmount)
        public
        payable
        isCompelete(_neederAmount)
    {
        needer storage _needer = neederMap[_neederAmount];
        _needer.amount += msg.value;
        _needer.funderAccount ++;
        _needer.map[_needer.funderAccount] = funder(msg.sender, msg.value);
        if(_needer.amount >= _needer.goal){
            _needer.NeederAddress.transfer(_needer.amount);
        }
    }
    //判断是否众筹完成
    modifier isCompelete(uint _neederAmount){
        needer storage _needer = neederMap[_neederAmount];
        require(_needer.amount < _needer.goal);
        _;
    }

}