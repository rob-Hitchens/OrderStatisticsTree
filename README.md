## Hitchens Order Statistics Tree

Solidity Library that implements a self-balancing binary search tree (BST) with specialized properties. The Libeary implements [Bokky Poobah's Red Black Tree](https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary) with additional properties. 

Adds O(1) order statistics to each node and the tree itself:

- rank: Report key position, in sorted list.  
- atRank: Inverse of rank. Reports the key stored at a certain height.
- above: Keys above, in sorted list
- below: Keys below, sorted list
- percentile & permil: The percentile and permil rank of a key
- median: List median

### Red Black Tree Organization

A BST maintains an ordered list. A BST can guarantee O(log n) performance for insertions and removals but only if the tree remains balanced. Balancing is accomplished through local reorganizations. 

[Ideally balanced trees](https://en.wikipedia.org/wiki/AVL_tree) optimize read operations by ensuring optimal balance as sorted data is inserted and removed. This methods invests considerable energy keeping the list perfectly balanced.

A Red Black Tree optimizes the cost of insertion and removal by tolerating limited imbalances. This type of tree minimizes the gas cost of insert while maintaining a BST with acceptable balance.

### Inserts and Deletes Take a "Key" and a "Value"

In the context of the Tree, a "Key" is the value to sort, and the "Value" is meaningful only to the client application. It would correspond to the user, orders, assets, etc. that are being sorted.

The system optimizes storage with a novel internal organization. 

### Node()

- Key: Same as the input
- parent: Internal
- left: Internal
- right: Internal
- red: Internal
- values: The number of unique values (records, identifiers) stored here.
- count: Internal

### NodeValue()

- Fetches one value from a given key, from a given row. 

### Finite Tree Growth

While it is not a requirement, it is recommended to devise a strategy to ensure a finite number of nodes. This would usually involve limiting precision in the keys. For example, consider a data set with a possible range of 50-100. With no decimals, the tree size will limit to 50 nodes, and unlimited insertions. This is the resolution of *statistics* the tree will be able to generate. If a high resolution is needed, the precision can be increased. Adjust precision on the client side so the possible range is 500-1000, for a maximum tree size of 500 nodes *and unlimited insertions.*

Since we are dealing with Ethereum, is not recommended to use this tool on an unbounded list. You must prevent unlimited growth, either by expiring old entries (removal) limiting the population or some other strategy. It is strongly recommended that you test the "worst case" tree organization on the largest possible dataset to confirm normal operation and acceptable in all parts of your application.

Bokky has informally tested the basic tree up to 10,000 nodes. Do NOT expect the same performance here. Although every effort has been made to be miserly on gas, this implementation adds additional data and processes so an increase is unavoidable.

## Code Examples

The source file contains two example implementations in flattened form. The first, shown below, exposes the Library functions for a single Tree.

The second adds a topics dimension so a single contract can manage n indices. The flattened structure is suitable for loading in Remix. 

If you have trouble getting started:

- insert: "0xaa",1
- insert: "0xaa",2

Then explore the stats. 

You cannot:

- insert: "0xaa",2 because that entry already exists. 

You can:

delete: "0xaa",1 because it exists. 

You will see that 2 has become the first record. 

The second implementation adds a topics dimension so a single contract can manage n indices. The flattened structure is suitable for loading in Remix. 

The function signatures are the same except the inputs are prefexied with a `bytes32` to identify the index context. A single contract can manage n indices. 

```
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
```


## Motivation

Although I'm a strong believer that the sorting concern can (and should) nearly almost always be externalized from Solidity contracts, this a generalized approach for those cases when it has to be done. 

## Tests

Describe and show how to run the tests with code examples.

## Contributors

Welcoming pull requests and feedback. If you happen to include this in an audited project, I'd love to know about it. 

## License

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
