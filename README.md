## Hitchens Order Statistics Tree

[https://github.com/rob-Hitchens/OrderStatisticsTree](https://github.com/rob-Hitchens/OrderStatisticsTree)

Solidity Library that implements a self-balancing binary search tree (BST) with [Order Statistics Tree](https://en.wikipedia.org/wiki/Order_statistic_tree) extensions. The Library implements [Bokky Poobah's Red Black Tree](https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary) with additional properties. 

Adds O(1) order statistics to each node and the tree itself:

- report a value position in sorted list.  
- report the count of values above and below a certain value
- report percentile, median, rank, etc.
- find the value with a given percentile rank.

### Red Black Tree Organization

A BST maintains an ordered list. A BST aims for O(log n) performance for insertions and removals but only if the tree remains balanced. Balancing is accomplished through local reorganizations (rotations). 

[Ideally balanced trees](https://en.wikipedia.org/wiki/AVL_tree) optimize read operations by ensuring optimal balance as sorted data is inserted and removed. This method invests considerable energy (meaning gas) keeping the list perfectly balanced.

Ethereum's `mapping` largely negates the need for crawling a tree to find a particular node. This implementation completes most read operations, including reporting statistics, in one operation. On the other hand, write operations in Ethereum are exceptionally expensive relative to reads. Consequently, we should optimize for insertion efficiency over read efficiency. Balance is important, but mostly in terms of insertion and deletion cost. This is roughly the opposite of most database systems that are optimized for read-back efficiency.

A [Red Black Tree](https://en.wikipedia.org/wiki/Red%E2%80%93black_tree) optimizes the cost of insertion and removal by tolerating limited imbalance. Tolerating limited imbalance reduces the frequency and depth of tree reorganizations which reduces insert and delete cost.  

### Inserts and Deletes Take a "UID" and a "sortVal"

- `_sortVal`: The value to sort, such as price, amount, rating, etc.. These are unsigned integers. `0` is prohibited. 
- `_uid`: A unique identifier for the entry. This should be meaningful at the application layer, such as ticketID, transactionID or UserID. These are `bytes32`.

Client's can store any of the scaler types in `_uid` after converting to the native `bytes32` type. The same principle applies to `_sortVal`. Note that `0` is reserved for performance reasons. In the case that `0` has meaning within the application, apply an offset to ensure a `0` is never submitted for sorting. 

Since multiple users or transactions could have the same `_sortVal`, this is permitted. Consider a case of "users" with "scores" to sort. User addresses would be re-cast as `bytes32` and the scores offset by `1` unless a score of `0` is not possible. Those are client-side responsibilities. 

- (Alice) _uid: `0x123...`, (score) _sortVal: `80`
- (Bob) _uid: `0x456...`, (score) _sortVal: `80`

These two entries will both be organized on the node representing `_sortVal: 80`. The node contains a dynamic array of all unique `_uid` that "live" in node `80`. The interface provides read-access to the count and the keys stored there. 

Roughly:
```
Node: 80
_uidCount: 2
_uid: ['0x123...','0x456...']
```

Delete activities require the `_sortVal` and the `_uid`. This means the tree always contains an ordered list of the sorted values, and the unique identifiers of application-level details related to them. The `_uid` list for entries with *identical* `_sortVal` is in *no particular order* for performance reasons. 

**WARN:** The tree enforces uniqueness for `_sortVal` plus `_uid` but it does not enforce `_uid` uniqueness throughout the tree. If such a situation is non-sensical (e.g. any given transaction ID can only have one price), then this uniqueness check should be enforced at the application level. It is *not* performed here because it is not strictly required in all cases and enforcement would add complexity and increase insertion cost. 

A client application can use the `sortValValueExists(bytes32 _uid, uint _sortVal)` function for such an enforcement:

```
function insertSomething(uint value, bytes32 id, args ...) ... {
  require(!sortValValueExists(id, value);
  // carry on
```

### Functions

- `insertSortValUid(bytes32 _uid, uint _sortVal)`: Inserts a sorted value and related UID. The pair must not exist. Reverts if it does.
- `removeSortValUid(bytes32 _uid, uint _sortVal)`: Removes a sorted value and related UID. The pair must exist. Reverts if it does.
- `sortValExists(uint _sortVal)`: bool. True if at least one UID has the inputed sort value.
- `sortValValueExists(bytes32 _uid, uint _sortVal)`: bool. True if the UID is a member of the set of UIDs with the given sort value. 
- `sortValCount()`: uint. The number of unique sorted value plus UID pairs in the system. 
- `firstSortVal()`: uint. The lowest sorted value.
- `lastSortVal()`: uint. The highest sorted value. 
- `medianSortVal()`: uint. The median sorted value. 
- `prevSortVal(uint _sortVal)`: uint. Sort value before the inputed sort value. `0` if no such record exists.
- `nextSortVal(uint _sortVal)`: uint. Sort value after the inputed sort value. `0` if no such record exists.
- `sortValAbove(uint _sortVal)`: uint. Count of entries above the inputed sort value. Equal entries are excluded.
- `sortValBelow(uint _sortVal)`: uint. Count of entries below the inputed sort value. Equal entries are excluded.
- `sortValPercentile(uint _sortVal)`: uint. Percentile rank of the inputed sort value. All UID entries at the given sorted value are considered equivalent and have the same Percentile rank. Returns the nearest hit (where if would be) if no such value exists in the tree. 
- `sortValPermil(uint )sortVal)`: uint. Like Percentile, with an extra digit of precision. 
- `sortValAtPercentile(uint _percentile):`: uint. Returns the sorted value at a percentile rank. The returned sorted value applies equally all UID entries collated in the node in no particular order. Returns the nearest sorted value if no sorted value precisely matches the requested percentile.
- `sortValAtPermil(uint _permil)`: uint. Like atPercentile, with an extra digit of precision. 
- `getNode(uint _sortVal)`: Returns the tree node details enumerated below.

#### getNode(uint _sortVal) and treeRootNode()

Returns the tree node data including tree structure. There must be at least one sorted value with this value for the node to exist in the tree. Reverts if the node doesn't exist. 

```
Node {
  parent: uint,
  left: uint,
  right: uint,
  red: bool,
  uidCount: uint,
  count: uint
}
```

For applications, the only value that would be generally useful to an application is:

- `getNode(uint _sortVal).uidCount `: This is the number of UID entries with the same sorted value. For example, identical test scores from multiple students. This informs a client that wishes to iterate the list using:

- `getNodeUid(uint _sortVal, row)`: bytes32. The UID associated with the sort value at a given row. 

The remaining values in the `getNode` response expose the internal structure of the tree. This is expected to be useful only for study of the internal structure or constructing other methods of tree exploration.

`parent`, `left` and `right` describe tree organization. `count` (do not confuse with `uidCount`) is the sum of the `uidCount` for all nodes in the subtree inclusive of this node. This is not expected to be useful for an application. 

- `treeRootNode()`: This is the root of the Order Statistics Tree. It is not expected to be useful at an application level. It is the summit of the tree and the only node with no parent. 

#### Owner() and changeOwner()

Simple access control for write operations. 

### Reorganization

The root node and node left, right, parent values are subject to change with each insertion or removal transaction. The tree uses the Red Black Tree algorithm to maintain acceptable tree balance. 

### Finite Tree Growth

While it is not a requirement, it is recommended to devise a strategy to ensure a finite number of nodes. This would usually imply limiting precision in the sorted values, limiting the age of the entries or a purpose-built strategy that reliably limits the number of nodes that can exist. In other words, you should be able to show that the maximum number of nodes *possible* will never exceed an acceptable limit.

For example, consider a data set of integers with a possible range of `51-100`. The tree size will be limited to 50 nodes. The nodes will accept unlimited records and it will be possible to estimate a worst-case insertion/deletion cost *at any scale* for a tree with worst-case imbalance at a fixed maximum size.

As a reminder, all entries collated in a particular node are organized *in no particular order*. That is, there would be no ordering assurance for all records stored in the same node, e.g. `53`. *This property makes the maximum insertion/deletion cost manageable*. 

If higher stastical resolution is required, then the same data set could be scaled as set of values in the range of `501-1000`. In effect, `51.0-100.0`. In this case the ordering and statistical analysis will yield an extra decimal of precision. Doing so will result in a maximum possible tree size of 1,000 nodes and a corresponding increase in the maximum gas cost for insertion and removal operations owing to increased tree depth. 

Other tree growth limiting strategies are possible. For example, a reputation system might expire votes on a FIFO basis, simply discarding the oldest vote when the tree size exceeds a set limit. The growth-limiting strategy is an application-level concern. 

Bokky has informally tested the basic tree up to 10,000 nodes. Do NOT expect the same performance here. This implementation adds additional data (`count`) and recursive processes that maintain it, so a gas cost increase is unavoidable. *The gas cost for these processes scales with tree depth.*

## Code Examples

The example Solidity file contains two example contract implementations in flattened form. The first, shown below, exposes the Library functions for a single Tree (`...Tree`).

If you have trouble getting started, use the singular implementation and:

- `insertSortValUid: ("0xaa",1)`
- `insertSortValUid: ("0xab",2)`

Then explore the stats. 

You cannot:

- `insertSortValUid: ("0xab",2)` because that entry already exists. 

You can:

`removeSortValUid: ("0xaa",1)` because it exists. 

You will see that `2` has become the `treeRoot()` because of the automatic reorganization. 

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
## Multiple indexes 

The second implementation adds a topics dimension so a single contract can manage n indices (`...Trees`).  

The function signatures are the same except the inputs are prefexied with a `bytes32` to identify the index context. A single contract can manage n indices. In other words, a single index manager contract can manage an unlimited number of indices for separate concerns within the same application or even for multiple applications. 

## Motivation

Although I'm a strong believer that the sorting concern can (and should) nearly almost always be externalized from Solidity contracts, this is a generalized approach for those cases when it has to be done. The focus is on gas cost optimization. In particular, developer control of the desired statistical and sort-order resolution so that ordered lists don't necessarily carry unnecessary and unacceptable cost. It allows for the idea of "good enough" sorting, "good enough" tree balance and "close enough" statistics that are suitable for many cases where contract logic depends on a sorted list or statistic (median, min, max, etc.) and *there is expected to be a large number of entries*. 

"Good enough" sorting means able to find the *exact median* (or percentile, etc.) value with known precision. Since the Order Tree holds the keys for the sorted entries, applications would normally consult authoratative records (without rounding) to find the exact values if any rounding is performed before inserting into the tree. 

This systems gives developers fine-grained control over resolution and performance. 

## Tests

NO TESTING OF ANY KIND HAS BEEN PERFORMED AND YOU USE THIS LIBRARY AT YOUR OWN EXCLUSIVE RISK. 

## Contributors

Optimization and clean-up is ongoing. 

The author welcomes pull requests, feature requests, testing assistance and feedback. Contact for author if you would like assistance with customization or calibrating the code for a specific application or gathering of different statistics.

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

Portions based on BokkyPooBahsRedBlackTreeLibrary, 
https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary

