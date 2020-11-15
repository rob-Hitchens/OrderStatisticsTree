pragma solidity 0.5.1;

/* 
Hitchens Order Statistics Tree v0.99

A Solidity Red-Black Tree library to store and maintain a sorted data
structure in a Red-Black binary search tree, with O(log 2n) insert, remove
and search time (and gas, approximately)

https://github.com/rob-Hitchens/OrderStatisticsTree

Copyright (c) Rob Hitchens. the MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Significant portions from BokkyPooBahsRedBlackTreeLibrary, 
https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary

THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/

import "./Owned.sol";
import "./HitchensOrderStatisticsTreeLib.sol";


/* 
Hitchens Order Statistics Tree v0.99

A Solidity Red-Black Tree library to store and maintain a sorted data
structure in a Red-Black binary search tree, with O(log 2n) insert, remove
and search time (and gas, approximately)

https://github.com/rob-Hitchens/OrderStatisticsTree

Copyright (c) Rob Hitchens. the MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Portions from BokkyPooBahsRedBlackTreeLibrary, 
https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary

THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/

contract HitchensOrderStatisticsTree is Owned {
    using HitchensOrderStatisticsTreeLib for HitchensOrderStatisticsTreeLib.Tree;

    HitchensOrderStatisticsTreeLib.Tree tree;

    event Log(string action, bytes32 key, uint value);

    constructor() public {
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
    function insertKeyValue(bytes32 key, uint value) public onlyOwner {
        emit Log("insert", key, value);
        tree.insert(key, value);
    }
    function removeKeyValue(bytes32 key, uint value) public onlyOwner {
        emit Log("delete", key, value);
        tree.remove(key, value);
    }
}

