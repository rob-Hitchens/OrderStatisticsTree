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
    function first(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if(_key == EMPTY) return 0;
        while (self.nodes[_key].left != EMPTY) {
            _key = self.nodes[_key].left;
        }
    }
    function last(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if(_key == EMPTY) return 0;
        while (self.nodes[_key].right != EMPTY) {
            _key = self.nodes[_key].right;
        }
    }
    function next(Tree storage self, uint key) internal view returns (uint _cursor) {
        require(key != EMPTY);
        if (self.nodes[key].right != EMPTY) {
            _cursor = treeMinimum(self, self.nodes[key].right);
        } else {
            _cursor = self.nodes[key].parent;
            while (_cursor != EMPTY && key == self.nodes[_cursor].right) {
                key = _cursor;
                _cursor = self.nodes[_cursor].parent;
            }
        }
    }
    function prev(Tree storage self, uint key) internal view returns (uint _cursor) {
        require(key != EMPTY);
        if (self.nodes[key].left != EMPTY) {
            _cursor = treeMaximum(self, self.nodes[key].left);
        } else {
            _cursor = self.nodes[key].parent;
            while (_cursor != EMPTY && key == self.nodes[_cursor].left) {
                key = _cursor;
                _cursor = self.nodes[_cursor].parent;
            }
        }
    }
    function exists(Tree storage self, uint key) internal view returns (bool _exists) {
        if(key == EMPTY) return false;
        if(key == self.root) return true;
        if(self.nodes[key].parent != EMPTY) return true;
        return false;       
    }
    function valueExists(Tree storage self, uint key, bytes32 value) internal view returns (bool _exists) {
        if(!exists(self, key)) return false;
        return self.nodes[key].values[self.nodes[key].valueMap[value]] == value;
    } 
    function getNode(Tree storage self, uint key) internal view returns (uint _ReturnKey, uint _parent, uint _left, uint _right, bool _red, uint values, uint count) {
        require(exists(self,key));
        Node storage gn = self.nodes[key];
        uint len = gn.values.length;
        return(key, gn.parent, gn.left, gn.right, gn.red, len, len+gn.count);
    }
    function getNodeCount(Tree storage self, uint key) internal view returns(uint count) {
        Node storage gn = self.nodes[key];
        uint len = gn.values.length;
        return len+gn.count;
    }
    function getNodeValueAtIndex(Tree storage self, uint key, uint index) internal view returns(bytes32 value) {
        require(exists(self,key));
        return self.nodes[key].values[index];
    }
    function count(Tree storage self) internal view returns(uint _count) {
        return getNodeCount(self,self.root);
    }
    function percentile(Tree storage self, uint key) internal view returns(uint _percentile) {
        uint denominator = count(self);
        uint numerator = rank(self, key);
        _percentile = ((uint(1000) * numerator)/denominator+(uint(5)))/uint(10);
    }
    function permil(Tree storage self, uint key) internal view returns(uint _permil) {
        uint denominator = count(self);
        uint numerator = rank(self, key);
        _permil = ((uint(10000) * numerator)/denominator+(uint(5)))/uint(10);
    }
    function atPercentile(Tree storage self, uint _percentile) internal view returns(uint key) {
        uint findRank = (((_percentile * count(self))/uint(10)) + 5) / uint(10);
        return atRank(self,findRank);
    }
    function atPermil(Tree storage self, uint _permil) internal view returns(uint key) {
        uint findRank = (((_permil * count(self))/uint(100)) + 5) / uint(10);
        return atRank(self,findRank);
    }    
    function median(Tree storage self) internal view returns(uint key) {
        return atPercentile(self,50);
    }
    function rank(Tree storage self, uint key) internal view returns(uint _rank) {
        if(count(self) > 0) {
            bool finished;
            uint cursor = self.root;
            Node storage c = self.nodes[cursor];
            uint smaller = getNodeCount(self,c.left);
            while (!finished) {
                uint valueCount = c.values.length;
                if(cursor == key) {
                    finished = true;
                } else {
                    if(cursor < key) {
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
    function atRank(Tree storage self, uint _rank) internal view returns(uint key) {
        bool finished;
        uint cursor = self.root;
        Node storage c = self.nodes[cursor];
        uint smaller = getNodeCount(self,c.left);
        while (!finished) {
            key = cursor;
            c = self.nodes[cursor];
            uint valueCount = c.values.length;
            if(smaller + 1 >= _rank && smaller + valueCount <= _rank) {
                key = cursor;
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
    function insert(Tree storage self, uint key, bytes32 value) internal {
        require(key != EMPTY);
        require(!valueExists(self,key,value));
        uint cursor;
        uint probe = self.root;
        while (probe != EMPTY) {
            cursor = probe;
            if (key < probe) {
                probe = self.nodes[probe].left;
            } else if (key > probe) {
                probe = self.nodes[probe].right;
            } else if (key == probe) {
                self.nodes[probe].valueMap[value] = self.nodes[probe].values.push(value) -1;
                return;
            }
            self.nodes[cursor].count++;
        }
        Node storage nKey = self.nodes[key];
        nKey.parent = cursor;
        nKey.left = EMPTY;
        nKey.right = EMPTY;
        nKey.red = true;
        nKey.valueMap[value] = nKey.values.push(value) -1;
        if (cursor == EMPTY) {
            self.root = key;
        } else if (key < cursor) {
            self.nodes[cursor].left = key;
        } else {
            self.nodes[cursor].right = key;
        }
        insertFixup(self, key);
    }
    function remove(Tree storage self, uint key, bytes32 value) internal {
        require(key != EMPTY);
        require(valueExists(self,key,value));
        Node storage nKey = self.nodes[key];
        uint rowToDelete = nKey.valueMap[value];
        nKey.values[rowToDelete] = nKey.values[nKey.values.length-1];
        nKey.valueMap[value]=rowToDelete;
        nKey.values.length--;
        uint probe;
        uint cursor;
        if(nKey.values.length == 0) {
            if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
                cursor = key;
            } else {
                cursor = self.nodes[key].right;
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
            if (cursor != key) {
                replaceParent(self, cursor, key); 
                self.nodes[cursor].left = self.nodes[key].left;
                self.nodes[self.nodes[cursor].left].parent = cursor;
                self.nodes[cursor].right = self.nodes[key].right;
                self.nodes[self.nodes[cursor].right].parent = cursor;
                self.nodes[cursor].red = self.nodes[key].red;
                (cursor, key) = (key, cursor);
            }
            fixCountRecurse(self,cursorParent);
            if (doFixup) {
                removeFixup(self, probe);
            }
            delete self.nodes[cursor];
        }
    }
    function fixCountRecurse(Tree storage self, uint key) private {
        while (key != EMPTY) {
           self.nodes[key].count = getNodeCount(self,self.nodes[key].left) + getNodeCount(self,self.nodes[key].right);
           key = self.nodes[key].parent;
        }
    }
    function treeMinimum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }
    function treeMaximum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }
    function rotateLeft(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].right;
        uint parent = self.nodes[key].parent;
        uint cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = parent;
        if (parent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[parent].left) {
            self.nodes[parent].left = cursor;
        } else {
            self.nodes[parent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
        self.nodes[key].count = getNodeCount(self,self.nodes[key].left) + getNodeCount(self,self.nodes[key].right);
        self.nodes[cursor].count = getNodeCount(self,self.nodes[cursor].left) + getNodeCount(self,self.nodes[cursor].right);
    }
    function rotateRight(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].left;
        uint parent = self.nodes[key].parent;
        uint cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = parent;
        if (parent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[parent].right) {
            self.nodes[parent].right = cursor;
        } else {
            self.nodes[parent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
        self.nodes[key].count = getNodeCount(self,self.nodes[key].left) + getNodeCount(self,self.nodes[key].right);
        self.nodes[cursor].count = getNodeCount(self,self.nodes[cursor].left) + getNodeCount(self,self.nodes[cursor].right);
    }
    function insertFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            uint keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                      key = keyParent;
                      rotateLeft(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                      key = keyParent;
                      rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(self, self.nodes[keyParent].parent);
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
    function removeFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && !self.nodes[key].red) {
            uint keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].right;
                }
                if (!self.nodes[self.nodes[cursor].left].red && !self.nodes[self.nodes[cursor].right].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].left;
                }
                if (!self.nodes[self.nodes[cursor].right].red && !self.nodes[self.nodes[cursor].left].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
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

    event Log(string action, uint key, bytes32 value);

    constructor() public {
    }
    function root() public view returns (uint _key) {
        _key = tree.root;
    }
    function first() public view returns (uint _key) {
        _key = tree.first();
    }
    function last() public view returns (uint _key) {
        _key = tree.last();
    }
    function next(uint key) public view returns (uint _key) {
        _key = tree.next(key);
    }
    function prev(uint key) public view returns (uint _key) {
        _key = tree.prev(key);
    }
    function exists(uint key) public view returns (bool _exists) {
        _exists = tree.exists(key);
    }
    function exists(bytes32 value, uint key) public view returns(bool _exists) {
        _exists = tree.valueExists(key, value);
    }
    function node(uint _key) public view returns (uint key, uint parent, uint left, uint right, bool red, uint values, uint count) {
        (key, parent, left, right, red, values, count) = tree.getNode(_key);
    }
    function nodeValue(uint key, uint row) public view returns(bytes32 _value) {
        _value = tree.getNodeValueAtIndex(key,row);
    }
    function count() public view returns(uint _count) {
        _count = tree.count();
    }
    function percentile(uint key) public view returns(uint _percentile) {
        _percentile = tree.percentile(key);
    }
    function permil(uint key) public view returns(uint _permil) {
        _permil = tree.percentile(key);
    }  
    function atPercentile(uint _percentile) public view returns(uint _key) {
        _key = tree.atPercentile(_percentile);
    }
    function atPermil(uint key) public view returns(uint _key) {
        _key = tree.atPermil(key);
    }
    function median() public view returns(uint _key) {
        return tree.median();
    }
    function rank(uint key) public view returns(uint _rank) {
        _rank = tree.rank(key);
    }
    function below(uint key) public view returns(uint _below) {
        if(tree.count() > 0 && key > 0) _below = tree.rank(key)-1;
    }
    function above(uint key) public view returns(uint _above) {
        if(tree.count() > 0) _above = tree.count()-tree.rank(key);
    }    
    function atRank(uint _rank) public view returns(uint _key) {
        _key = tree.atRank(_rank);
    }
    function insert(bytes32 _value, uint _key) public onlyOwner {
        emit Log("insert", _key, _value);
        tree.insert(_key, _value);
    }
    function remove(bytes32 _value, uint _key) public onlyOwner {
        emit Log("delete", _key, _value);
        tree.remove(_key, _value);
    }
}

contract HitchensOrderStatisticsTrees is Owned {
    using HitchensOrderStatisticsTreeLibrary for HitchensOrderStatisticsTreeLibrary.Tree;

    struct Topic {
        HitchensOrderStatisticsTreeLibrary.Tree tree;
    }
    
    mapping(bytes32 => Topic) topics;

    event Log(bytes32 topic, string action, uint key, bytes32 value);

    constructor() public {
    }
    function root(bytes32 topic) public view returns (uint _key) {
        _key = topics[topic].tree.root;
    }
    function first(bytes32 topic) public view returns (uint _key) {
        _key = topics[topic].tree.first();
    }
    function last(bytes32 topic) public view returns (uint _key) {
        _key = topics[topic].tree.last();
    }
    function next(bytes32 topic, uint key) public view returns (uint _key) {
        _key = topics[topic].tree.next(key);
    }
    function prev(bytes32 topic, uint key) public view returns (uint _key) {
        _key = topics[topic].tree.prev(key);
    }
    function exists(bytes32 topic, uint key) public view returns (bool _exists) {
        _exists = topics[topic].tree.exists(key);
    }
    function exists(bytes32 topic, bytes32 value, uint key) public view returns(bool _exists) {
        _exists = topics[topic].tree.valueExists(key, value);
    }
    function node(bytes32 topic, uint _key) public view returns (uint key, uint parent, uint left, uint right, bool red, uint values, uint count) {
        (key, parent, left, right, red, values, count) = topics[topic].tree.getNode(_key);
    }
    function nodeValue(bytes32 topic, uint key, uint row) public view returns(bytes32 _value) {
        _value = topics[topic].tree.getNodeValueAtIndex(key,row);
    }
    function count(bytes32 topic) public view returns(uint _count) {
        _count = topics[topic].tree.count();
    } 
    function percentile(bytes32 topic, uint key) public view returns(uint _percentile) {
        _percentile = topics[topic].tree.percentile(key);
    }
    function permil(bytes32 topic, uint key) public view returns(uint _permil) {
        _permil = topics[topic].tree.percentile(key);
    } 
    function atPercentile(bytes32 topic, uint _percentile) public view returns(uint _key) {
        _key = topics[topic].tree.atPercentile(_percentile);
    }
    function atPermil(bytes32 topic, uint key) public view returns(uint _key) {
        _key = topics[topic].tree.atPermil(key);
    }
    function median(bytes32 topic) public view returns(uint _key) {
        return topics[topic].tree.median();
    }
    function rank(bytes32 topic, uint key) public view returns(uint _rank) {
        _rank = topics[topic].tree.rank(key);
    }
    function below(bytes32 topic, uint key) public view returns(uint _below) {
        if(topics[topic].tree.count() > 0 && key > 0) _below = topics[topic].tree.rank(key)-1;
    }
    function above(bytes32 topic, uint key) public view returns(uint _above) {
        if(topics[topic].tree.count() > 0) _above = topics[topic].tree.count()-topics[topic].tree.rank(key);
    }     
    function atRank(bytes32 topic, uint _rank) public view returns(uint _key) {
        _key = topics[topic].tree.atRank(_rank);
    }
    function insert(bytes32 topic, bytes32 _value, uint _key) public onlyOwner {
        emit Log(topic, "insert", _key, _value);
        topics[topic].tree.insert(_key, _value);
    }
    function remove(bytes32 topic, bytes32 _value, uint _key) public onlyOwner {
        emit Log(topic, "delete", _key, _value);
        topics[topic].tree.remove(_key, _value);
    }
}
