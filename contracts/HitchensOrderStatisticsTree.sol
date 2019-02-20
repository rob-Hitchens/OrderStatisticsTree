pragma solidity 0.4.25;

/* 
Hitchens Order Statistics Tree v0.96

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

library HitchensOrderStatisticsTreeLibrary {
    uint private constant EMPTY = 0;
    struct Node {
        uint parent;
        uint left;
        uint right;
        bool red;
        bytes32[] values;
        mapping(bytes32 => uint) valueMap;
        uint count;
    }
    struct Tree {
        uint root;
        mapping(uint => Node) nodes;
    }
    function first(Tree storage self) internal view returns (uint _sortVal) {
        _sortVal = self.root;
        if(_sortVal == EMPTY) return 0;
        while (self.nodes[_sortVal].left != EMPTY) {
            _sortVal = self.nodes[_sortVal].left;
        }
    }
    function last(Tree storage self) internal view returns (uint _sortVal) {
        _sortVal = self.root;
        if(_sortVal == EMPTY) return 0;
        while (self.nodes[_sortVal].right != EMPTY) {
            _sortVal = self.nodes[_sortVal].right;
        }
    }
    function next(Tree storage self, uint sortVal) internal view returns (uint _cursor) {
        require(sortVal != EMPTY);
        if (self.nodes[sortVal].right != EMPTY) {
            _cursor = treeMinimum(self, self.nodes[sortVal].right);
        } else {
            _cursor = self.nodes[sortVal].parent;
            while (_cursor != EMPTY && sortVal == self.nodes[_cursor].right) {
                sortVal = _cursor;
                _cursor = self.nodes[_cursor].parent;
            }
        }
    }
    function prev(Tree storage self, uint sortVal) internal view returns (uint _cursor) {
        require(sortVal != EMPTY);
        if (self.nodes[sortVal].left != EMPTY) {
            _cursor = treeMaximum(self, self.nodes[sortVal].left);
        } else {
            _cursor = self.nodes[sortVal].parent;
            while (_cursor != EMPTY && sortVal == self.nodes[_cursor].left) {
                sortVal = _cursor;
                _cursor = self.nodes[_cursor].parent;
            }
        }
    }
    function exists(Tree storage self, uint sortVal) internal view returns (bool _exists) {
        if(sortVal == EMPTY) return false;
        if(sortVal == self.root) return true;
        if(self.nodes[sortVal].parent != EMPTY) return true;
        return false;       
    }
    function valueExists(Tree storage self, uint sortVal, bytes32 value) internal view returns (bool _exists) {
        if(!exists(self, sortVal)) return false;
        return self.nodes[sortVal].values[self.nodes[sortVal].valueMap[value]] == value;
    } 
    function getNode(Tree storage self, uint sortVal) internal view returns (uint _parent, uint _left, uint _right, bool _red, uint uidCount, uint count) {
        require(exists(self,sortVal));
        Node storage gn = self.nodes[sortVal];
        return(gn.parent, gn.left, gn.right, gn.red, gn.values.length, gn.values.length+gn.count);
    }
    function getNodeCount(Tree storage self, uint sortVal) internal view returns(uint count) {
        Node storage gn = self.nodes[sortVal];
        return gn.values.length+gn.count;
    }
    function getNodeValueAtIndex(Tree storage self, uint sortVal, uint index) internal view returns(bytes32 value) {
        require(exists(self,sortVal));
        return self.nodes[sortVal].values[index];
    }
    function count(Tree storage self) internal view returns(uint _count) {
        return getNodeCount(self,self.root);
    }
    function percentile(Tree storage self, uint sortVal) internal view returns(uint _percentile) {
        uint denominator = count(self);
        uint numerator = rank(self, sortVal);
        _percentile = ((uint(1000) * numerator)/denominator+(uint(5)))/uint(10);
    }
    function permil(Tree storage self, uint sortVal) internal view returns(uint _permil) {
        uint denominator = count(self);
        uint numerator = rank(self, sortVal);
        _permil = ((uint(10000) * numerator)/denominator+(uint(5)))/uint(10);
    }
    function atPercentile(Tree storage self, uint _percentile) internal view returns(uint sortVal) {
        uint findRank = (((_percentile * count(self))/uint(10)) + 5) / uint(10);
        return atRank(self,findRank);
    }
    function atPermil(Tree storage self, uint _permil) internal view returns(uint sortVal) {
        uint findRank = (((_permil * count(self))/uint(100)) + 5) / uint(10);
        return atRank(self,findRank);
    }    
    function median(Tree storage self) internal view returns(uint sortVal) {
        return atPercentile(self,50);
    }
    function below(Tree storage self, uint sortVal) public view returns(uint _below) {
        if(count(self) > 0 && sortVal > 0) _below = rank(self,sortVal)-1;
    }
    function above(Tree storage self, uint sortVal) public view returns(uint _above) {
        if(count(self) > 0) _above = count(self)-rank(self,sortVal);
    } 
    function rank(Tree storage self, uint sortVal) internal view returns(uint _rank) {
        if(count(self) > 0) {
            bool finished;
            uint cursor = self.root;
            Node storage c = self.nodes[cursor];
            uint smaller = getNodeCount(self,c.left);
            while (!finished) {
                uint valueCount = c.values.length;
                if(cursor == sortVal) {
                    finished = true;
                } else {
                    if(cursor < sortVal) {
                        cursor = c.right;
                        c = self.nodes[cursor];
                        smaller += valueCount + getNodeCount(self,c.left);
                    } else {
                        cursor = c.left;
                        c = self.nodes[cursor];
                        smaller -= (valueCount + getNodeCount(self,c.right));
                    }
                }
                if (!exists(self,cursor)) {
                    finished = true;
                }
            }
            return smaller + 1;
        }
    }
    function atRank(Tree storage self, uint _rank) internal view returns(uint sortVal) {
        bool finished;
        uint cursor = self.root;
        Node storage c = self.nodes[cursor];
        uint smaller = getNodeCount(self,c.left);
        while (!finished) {
            sortVal = cursor;
            c = self.nodes[cursor];
            uint valueCount = c.values.length;
            if(smaller + 1 >= _rank && smaller + valueCount <= _rank) {
                sortVal = cursor;
                finished = true;
            } else {
                if(smaller + valueCount <= _rank) {
                    cursor = c.right;
                    c = self.nodes[cursor];
                    smaller += valueCount + getNodeCount(self,c.left);
                } else {
                     cursor = c.left;
                     c = self.nodes[cursor];
                    smaller -= (valueCount + getNodeCount(self,c.right));
                }
            }
            if (!exists(self,cursor)) {
                finished = true;
            }
        }
    }
    function insert(Tree storage self, uint sortVal, bytes32 value) internal {
        require(sortVal != EMPTY);
        require(!valueExists(self,sortVal,value));
        uint cursor;
        uint probe = self.root;
        while (probe != EMPTY) {
            cursor = probe;
            if (sortVal < probe) {
                probe = self.nodes[probe].left;
            } else if (sortVal > probe) {
                probe = self.nodes[probe].right;
            } else if (sortVal == probe) {
                self.nodes[probe].valueMap[value] = self.nodes[probe].values.push(value) -1;
                return;
            }
            self.nodes[cursor].count++;
        }
        Node storage nSortVal = self.nodes[sortVal];
        nSortVal.parent = cursor;
        nSortVal.left = EMPTY;
        nSortVal.right = EMPTY;
        nSortVal.red = true;
        nSortVal.valueMap[value] = nSortVal.values.push(value) -1;
        if (cursor == EMPTY) {
            self.root = sortVal;
        } else if (sortVal < cursor) {
            self.nodes[cursor].left = sortVal;
        } else {
            self.nodes[cursor].right = sortVal;
        }
        insertFixup(self, sortVal);
    }
    function remove(Tree storage self, uint sortVal, bytes32 value) internal {
        require(sortVal != EMPTY);
        require(valueExists(self,sortVal,value));
        Node storage nSortVal = self.nodes[sortVal];
        uint rowToDelete = nSortVal.valueMap[value];
        nSortVal.values[rowToDelete] = nSortVal.values[nSortVal.values.length-1];
        nSortVal.valueMap[value]=rowToDelete;
        nSortVal.values.length--;
        uint probe;
        uint cursor;
        if(nSortVal.values.length == 0) {
            if (self.nodes[sortVal].left == EMPTY || self.nodes[sortVal].right == EMPTY) {
                cursor = sortVal;
            } else {
                cursor = self.nodes[sortVal].right;
                while (self.nodes[cursor].left != EMPTY) { 
                    cursor = self.nodes[cursor].left;
                }
            } 
            if (self.nodes[cursor].left != EMPTY) {
                probe = self.nodes[cursor].left; 
            } else {
                probe = self.nodes[cursor].right; 
            }
            uint cursorParent = self.nodes[cursor].parent;
            self.nodes[probe].parent = cursorParent;
            if (cursorParent != EMPTY) {
                if (cursor == self.nodes[cursorParent].left) {
                    self.nodes[cursorParent].left = probe;
                } else {
                    self.nodes[cursorParent].right = probe;
                }
            } else {
                self.root = probe;
            }
            bool doFixup = !self.nodes[cursor].red;
            if (cursor != sortVal) {
                replaceParent(self, cursor, sortVal); 
                self.nodes[cursor].left = self.nodes[sortVal].left;
                self.nodes[self.nodes[cursor].left].parent = cursor;
                self.nodes[cursor].right = self.nodes[sortVal].right;
                self.nodes[self.nodes[cursor].right].parent = cursor;
                self.nodes[cursor].red = self.nodes[sortVal].red;
                (cursor, sortVal) = (sortVal, cursor);
            }
            fixCountRecurse(self,cursorParent);
            if (doFixup) {
                removeFixup(self, probe);
            }
            delete self.nodes[cursor];
        }
    }
    function fixCountRecurse(Tree storage self, uint sortVal) private {
        while (sortVal != EMPTY) {
           self.nodes[sortVal].count = getNodeCount(self,self.nodes[sortVal].left) + getNodeCount(self,self.nodes[sortVal].right);
           sortVal = self.nodes[sortVal].parent;
        }
    }
    function treeMinimum(Tree storage self, uint sortVal) private view returns (uint) {
        while (self.nodes[sortVal].left != EMPTY) {
            sortVal = self.nodes[sortVal].left;
        }
        return sortVal;
    }
    function treeMaximum(Tree storage self, uint sortVal) private view returns (uint) {
        while (self.nodes[sortVal].right != EMPTY) {
            sortVal = self.nodes[sortVal].right;
        }
        return sortVal;
    }
    function rotateLeft(Tree storage self, uint sortVal) private {
        uint cursor = self.nodes[sortVal].right;
        uint parent = self.nodes[sortVal].parent;
        uint cursorLeft = self.nodes[cursor].left;
        self.nodes[sortVal].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = sortVal;
        }
        self.nodes[cursor].parent = parent;
        if (parent == EMPTY) {
            self.root = cursor;
        } else if (sortVal == self.nodes[parent].left) {
            self.nodes[parent].left = cursor;
        } else {
            self.nodes[parent].right = cursor;
        }
        self.nodes[cursor].left = sortVal;
        self.nodes[sortVal].parent = cursor;
        self.nodes[sortVal].count = getNodeCount(self,self.nodes[sortVal].left) + getNodeCount(self,self.nodes[sortVal].right);
        self.nodes[cursor].count = getNodeCount(self,self.nodes[cursor].left) + getNodeCount(self,self.nodes[cursor].right);
    }
    function rotateRight(Tree storage self, uint sortVal) private {
        uint cursor = self.nodes[sortVal].left;
        uint parent = self.nodes[sortVal].parent;
        uint cursorRight = self.nodes[cursor].right;
        self.nodes[sortVal].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = sortVal;
        }
        self.nodes[cursor].parent = parent;
        if (parent == EMPTY) {
            self.root = cursor;
        } else if (sortVal == self.nodes[parent].right) {
            self.nodes[parent].right = cursor;
        } else {
            self.nodes[parent].left = cursor;
        }
        self.nodes[cursor].right = sortVal;
        self.nodes[sortVal].parent = cursor;
        self.nodes[sortVal].count = getNodeCount(self,self.nodes[sortVal].left) + getNodeCount(self,self.nodes[sortVal].right);
        self.nodes[cursor].count = getNodeCount(self,self.nodes[cursor].left) + getNodeCount(self,self.nodes[cursor].right);
    }
    function insertFixup(Tree storage self, uint sortVal) private {
        uint cursor;
        while (sortVal != self.root && self.nodes[self.nodes[sortVal].parent].red) {
            uint sortValParent = self.nodes[sortVal].parent;
            if (sortValParent == self.nodes[self.nodes[sortValParent].parent].left) {
                cursor = self.nodes[self.nodes[sortValParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[sortValParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[sortValParent].parent].red = true;
                    sortVal = self.nodes[sortValParent].parent;
                } else {
                    if (sortVal == self.nodes[sortValParent].right) {
                      sortVal = sortValParent;
                      rotateLeft(self, sortVal);
                    }
                    sortValParent = self.nodes[sortVal].parent;
                    self.nodes[sortValParent].red = false;
                    self.nodes[self.nodes[sortValParent].parent].red = true;
                    rotateRight(self, self.nodes[sortValParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[sortValParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[sortValParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[sortValParent].parent].red = true;
                    sortVal = self.nodes[sortValParent].parent;
                } else {
                    if (sortVal == self.nodes[sortValParent].left) {
                      sortVal = sortValParent;
                      rotateRight(self, sortVal);
                    }
                    sortValParent = self.nodes[sortVal].parent;
                    self.nodes[sortValParent].red = false;
                    self.nodes[self.nodes[sortValParent].parent].red = true;
                    rotateLeft(self, self.nodes[sortValParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }
    function replaceParent(Tree storage self, uint a, uint b) private {
        uint bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }
    function removeFixup(Tree storage self, uint sortVal) private {
        uint cursor;
        while (sortVal != self.root && !self.nodes[sortVal].red) {
            uint sortValParent = self.nodes[sortVal].parent;
            if (sortVal == self.nodes[sortValParent].left) {
                cursor = self.nodes[sortValParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[sortValParent].red = true;
                    rotateLeft(self, sortValParent);
                    cursor = self.nodes[sortValParent].right;
                }
                if (!self.nodes[self.nodes[cursor].left].red && !self.nodes[self.nodes[cursor].right].red) {
                    self.nodes[cursor].red = true;
                    sortVal = sortValParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[sortValParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[sortValParent].red;
                    self.nodes[sortValParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, sortValParent);
                    sortVal = self.root;
                }
            } else {
                cursor = self.nodes[sortValParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[sortValParent].red = true;
                    rotateRight(self, sortValParent);
                    cursor = self.nodes[sortValParent].left;
                }
                if (!self.nodes[self.nodes[cursor].right].red && !self.nodes[self.nodes[cursor].left].red) {
                    self.nodes[cursor].red = true;
                    sortVal = sortValParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[sortValParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[sortValParent].red;
                    self.nodes[sortValParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, sortValParent);
                    sortVal = self.root;
                }
            }
        }
        self.nodes[sortVal].red = false;
    }
}

/* 
Hitchens Order Statistics Tree v0.96

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
    using HitchensOrderStatisticsTreeLibrary for HitchensOrderStatisticsTreeLibrary.Tree;

    HitchensOrderStatisticsTreeLibrary.Tree tree;

    event Log(string action, uint sortVal, bytes32 value);

    constructor() public {
    }
    function treeRootNode() public view returns (uint _sortVal) {
        _sortVal = tree.root;
    }
    function firstSortVal() public view returns (uint _sortVal) {
        _sortVal = tree.first();
    }
    function lastSortVal() public view returns (uint _sortVal) {
        _sortVal = tree.last();
    }
    function nextSortVal(uint sortVal) public view returns (uint _sortVal) {
        _sortVal = tree.next(sortVal);
    }
    function prevSortVal(uint sortVal) public view returns (uint _sortVal) {
        _sortVal = tree.prev(sortVal);
    }
    function sortValExists(uint sortVal) public view returns (bool _exists) {
        _exists = tree.exists(sortVal);
    }
    function sortValValueExists(bytes32 value, uint sortVal) public view returns(bool _exists) {
        _exists = tree.valueExists(sortVal, value);
    }
    function getNode(uint _sortVal) public view returns (uint parent, uint left, uint right, bool red, uint uidCount, uint count) {
        (parent, left, right, red, uidCount, count) = tree.getNode(_sortVal);
    }
    function getNodeUid(uint sortVal, uint row) public view returns(bytes32 _uid) {
        _uid = tree.getNodeValueAtIndex(sortVal,row);
    }
    function sortValCount() public view returns(uint _count) {
        _count = tree.count();
    }
    function sortValPercentile(uint sortVal) public view returns(uint _percentile) {
        _percentile = tree.percentile(sortVal);
    }
    function sortValPermil(uint sortVal) public view returns(uint _permil) {
        _permil = tree.permil(sortVal);
    }  
    function sortValAtPercentile(uint _percentile) public view returns(uint _sortVal) {
        _sortVal = tree.atPercentile(_percentile);
    }
    function sortValAtPermil(uint sortVal) public view returns(uint _sortVal) {
        _sortVal = tree.atPermil(sortVal);
    }
    function medianSortVal() public view returns(uint _sortVal) {
        return tree.median();
    }
    function sortValRank(uint sortVal) public view returns(uint _rank) {
        _rank = tree.rank(sortVal);
    }
    function sortValBelow(uint sortVal) public view returns(uint _below) {
        _below = tree.below(sortVal);
    }
    function sortValAbove(uint sortVal) public view returns(uint _above) {
        _above = tree.above(sortVal);
    }    
    function sortValAtRank(uint _rank) public view returns(uint _sortVal) {
        _sortVal = tree.atRank(_rank);
    }
    function insertSortValUid(bytes32 _uid, uint _sortVal) public onlyOwner {
        emit Log("insert", _sortVal, _uid);
        tree.insert(_sortVal, _uid);
    }
    function removeSortValUid(bytes32 _uid, uint _sortVal) public onlyOwner {
        emit Log("delete", _sortVal, _uid);
        tree.remove(_sortVal, _uid);
    }
}

contract HitchensOrderStatisticsTrees is Owned {
    using HitchensOrderStatisticsTreeLibrary for HitchensOrderStatisticsTreeLibrary.Tree;

    struct Topic {
        HitchensOrderStatisticsTreeLibrary.Tree tree;
    }
    
    mapping(bytes32 => Topic) topics;

    event Log(bytes32 topic, string action, uint sortVal, bytes32 value);

    constructor() public {
    }
    function treeRootNode(bytes32 topic) public view returns (uint _sortVal) {
        _sortVal = topics[topic].tree.root;
    }
    function firstSortVal(bytes32 topic) public view returns (uint _sortVal) {
        _sortVal = topics[topic].tree.first();
    }
    function lastSortVal(bytes32 topic) public view returns (uint _sortVal) {
        _sortVal = topics[topic].tree.last();
    }
    function nextSortVal(bytes32 topic, uint sortVal) public view returns (uint _sortVal) {
        _sortVal = topics[topic].tree.next(sortVal);
    }
    function prevSortVal(bytes32 topic, uint sortVal) public view returns (uint _sortVal) {
        _sortVal = topics[topic].tree.prev(sortVal);
    }
    function sortValExists(bytes32 topic, uint sortVal) public view returns (bool _exists) {
        _exists = topics[topic].tree.exists(sortVal);
    }
    function sortValValueExists(bytes32 topic, bytes32 value, uint sortVal) public view returns(bool _exists) {
        _exists = topics[topic].tree.valueExists(sortVal, value);
    }
    function getNode(bytes32 topic, uint _sortVal) public view returns (uint parent, uint left, uint right, bool red, uint uidCount, uint count) {
        (parent, left, right, red, uidCount, count) = topics[topic].tree.getNode(_sortVal);
    }
    function getNodeUid(bytes32 topic, uint sortVal, uint row) public view returns(bytes32 _uid) {
        _uid = topics[topic].tree.getNodeValueAtIndex(sortVal,row);
    }
    function sortValCount(bytes32 topic) public view returns(uint _count) {
        _count = topics[topic].tree.count();
    } 
    function sortValPercentile(bytes32 topic, uint sortVal) public view returns(uint _percentile) {
        _percentile = topics[topic].tree.percentile(sortVal);
    }
    function sortValPermil(bytes32 topic, uint sortVal) public view returns(uint _permil) {
        _permil = topics[topic].tree.permil(sortVal);
    } 
    function sortValAtPercentile(bytes32 topic, uint _percentile) public view returns(uint _sortVal) {
        _sortVal = topics[topic].tree.atPercentile(_percentile);
    }
    function sortValAtPermil(bytes32 topic, uint sortVal) public view returns(uint _sortVal) {
        _sortVal = topics[topic].tree.atPermil(sortVal);
    }
    function medianSortVal(bytes32 topic) public view returns(uint _sortVal) {
        return topics[topic].tree.median();
    }
    function sortValRank(bytes32 topic, uint sortVal) public view returns(uint _rank) {
        _rank = topics[topic].tree.rank(sortVal);
    }
    function sortValBelow(bytes32 topic, uint sortVal) public view returns(uint _below) {
        if(topics[topic].tree.count() > 0 && sortVal > 0) _below = topics[topic].tree.rank(sortVal)-1;
    }
    function sortValAbove(bytes32 topic, uint sortVal) public view returns(uint _above) {
        if(topics[topic].tree.count() > 0) _above = topics[topic].tree.count()-topics[topic].tree.rank(sortVal);
    }     
    function sortValAtRank(bytes32 topic, uint _rank) public view returns(uint _sortVal) {
        _sortVal = topics[topic].tree.atRank(_rank);
    }
    function insertSortValUid(bytes32 topic, bytes32 _uid, uint _sortVal) public onlyOwner {
        emit Log(topic, "insert", _sortVal, _uid);
        topics[topic].tree.insert(_sortVal, _uid);
    }
    function removeSortValUid(bytes32 topic, bytes32 _uid, uint _sortVal) public onlyOwner {
        emit Log(topic, "delete", _sortVal, _uid);
        topics[topic].tree.remove(_sortVal, _uid);
    }
}
