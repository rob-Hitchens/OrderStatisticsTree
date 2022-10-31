// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../HOSTLib.sol";

contract MockHOSTV1 {
    using HitchensOrderStatisticsTreeLibV1 for HitchensOrderStatisticsTreeLibV1.Tree;

    HitchensOrderStatisticsTreeLibV1.Tree tree;

    event Log(string action, bytes32 key, uint value);

    constructor()  {
    }
    function treeRootNode() public view returns (uint _value) {
        _value = tree.root;
    }
    function firstValue() public view returns (uint _value) {
        _value = tree.first();
    }
    function lastValue() public view returns (uint _value) {
        _value = tree.last();
    }
    function nextValue(uint value) public view returns (uint _value) {
        _value = tree.next(value);
    }
    function prevValue(uint value) public view returns (uint _value) {
        _value = tree.prev(value);
    }
    function valueExists(uint value) public view returns (bool _exists) {
        _exists = tree.exists(value);
    }
    function keyValueExists(bytes32 key, uint value) public view returns(bool _exists) {
        _exists = tree.keyExists(key, value);
    }
    function getNode(uint value) public view returns (uint _parent, uint _left, uint _right, bool _red, uint _keyCount, uint _count) {
        (_parent, _left, _right, _red, _keyCount, _count) = tree.getNode(value);
    }
    
    function getNode2(uint value) public view returns (uint _parent, uint _left, uint _right, bool _red, uint _keyCount, uint _count) {
        HitchensOrderStatisticsTreeLibV1.Node storage node = tree.getNode2(value); 
        _parent = node.parent; 
        _left = node.left; 
        _right = node.right; 
        _red = node.red; 
        _keyCount = node.keys.length; 
        _count = node.count;
    }

    function getNodeKeysCount(uint256 value) public view returns(uint256 keysCount) {
        return tree.getNodeKeysLength(value);
    }
    function getValueKey(uint value, uint row) public view returns(bytes32 _key) {
        _key = tree.valueKeyAtIndex(value,row);
    }
    function valueKeyCount() public view returns(uint _count) {
        _count = tree.count();
    } 
    function valuePercentile(uint value) public view returns(uint _percentile) {
        _percentile = tree.percentile(value);
    }
    function valuePermil(uint value) public view returns(uint _permil) {
        _permil = tree.permil(value);
    }  
    function valueAtPercentile(uint _percentile) public view returns(uint _value) {
        _value = tree.atPercentile(_percentile);
    }
    function valueAtPermil(uint value) public view returns(uint _value) {
        _value = tree.atPermil(value);
    }
    function medianValue() public view returns(uint _value) {
        return tree.median();
    }
    function valueRank(uint value) public view returns(uint _rank) {
        _rank = tree.rank(value);
    }
    function valuesBelow(uint value) public view returns(uint _below) {
        _below = tree.below(value);
    }
    function valuesAbove(uint value) public view returns(uint _above) {
        _above = tree.above(value);
    }    
    function valueAtRank(uint _rank) public view returns(uint _value) {
        _value = tree.atRank(_rank);
    }
    function valueAtRankReverse(uint _rank) public view returns(uint _value) {
        _value = tree.atRank(tree.count() - (_rank - 1));
    }
    function valueRankReverse(uint value) public view returns(uint _rank) {
        _rank = tree.count() - (tree.rank(value) - 1);
    }
    function insertKeyValue(bytes32 key, uint value) public  {
        emit Log("insert", key, value);
        tree.insert(key, value);
    }
    function removeKeyValue(bytes32 key, uint value) public  {
        emit Log("delete", key, value);
        tree.remove(key, value);
    }

    //  Mock functions
    function mock1(uint256 p1) public view returns(uint256) {
        return (((p1 * tree.getNodeCount(tree.root))/uint(100)) + uint(5)) / uint(10);
    }

    //  Mock functions
    function mock2(uint256 p1, uint256 p2) public view returns(uint256) {
        return (((p1 * p2)/uint(100)) + uint(5)) / uint(10);
    }
}
