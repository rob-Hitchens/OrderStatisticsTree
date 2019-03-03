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

This implementation relies on the iterative approach to functions that seem recursive in nature, to avoid problems with stack depth. 

### Inserts and Deletes Take a Key and a Value

- `value`: The value to sort, such as price, amount, rating, etc.. These are unsigned integers. `0` is prohibited. 
- `key`: (Optional). A unique identifier for the entry. This should be meaningful at the application layer, such as ticketID, transactionID or UserID. These are `bytes32`. If there is no reason to point back to application-level records, it's safe to use `0x0` for all entries, provided there are no duplicate `value`.

Client's can store any of the scaler types in `key` after converting to the native `bytes32` type. The same principle applies to `value`. Note that value `0` is reserved for performance reasons. In the case that `0` has meaning within the application, apply an offset to ensure a `0` is never submitted for sorting. 

Since multiple users or transactions could have the same `value`, this is permitted. Consider a case of "students" with "test scores" to sort. User addresses would be re-cast as `bytes32` and the scores offset by `1` unless a score of `0` is not possible. Conversion and offset are client-side responsibilities. 

- (Alice) key: `0x123...`, (score) value: `80`
- (Bob) key: `0x456...`, (score) value: `80`

These two entries will both be organized on the node representing `value: 80`. The node contains a dynamic array of all unique `key` that "live" in node `80`. The interface provides read-access to the key count and the keys stored there. 

Roughly:
```
Node: 80
_keyCount: 2
_key: ['0x123...','0x456...']
```

Delete activities require the `value` and the `key`. This means the tree always contains an ordered list of the sorted values, and the unique identifiers of application-level details related to them. The `key` list for entries with *identical* `value` is in *no particular order* for performance reasons. 

**WARN:** The tree enforces uniqueness for `value` plus `key` but it does not enforce `key` uniqueness throughout the tree. If such a situation is non-sensical (e.g. any given transaction ID can only have one price), then this uniqueness check should be enforced at the application level. It is *not* performed here because it is not strictly required in all cases and enforcement would add complexity and increase insertion cost. 

A client application can use the `keyExists(bytes32 key, uint value)` function for such an enforcement:

```
function insertSomething(uint value, bytes32 key, args ...) ... {
  require(!keyExists(key, value);
  // carry on
```

### Functions

- `insert(bytes32 key, uint value)`: Inserts a sorted value and related key. The pair must not exist. Reverts if it does. If the sorted value already exists in the tree, then the key is appended to the list of keys in an existing node.
- `remove(bytes32 key, uint value)`: Removes a sorted value and related key. The pair must exist. Reverts if it doesn't. If multiple keys exist for the given sorted value, then the key is removed from the list of keys for the given value. If it is the last key for the given value, then the node is removed from the tree. 

Insertions and deletions always:
- recurse toward to the tree root to update the counters. 

and may:
- trigger rebalancing if a node is added or removed. 

#### View functions:

- `valueExists(uint value)`: bool. True if at least one key has the inputed sort value.
- `valueValueExists(bytes32 key, uint value)`: bool. True if the key is a member of the set of keys with the given sort value. - 
- `count()`: uint. The number of unique key/value pairs in the system. 
- `first()`: uint. The lowest sorted value.
- `last()`: uint. The highest sorted value. 
- `median()`: uint. The median sorted value. 
- `prev(uint value)`: uint. Sort value before the inputed sort value. `0` if no such record exists.
- `next(uint value)`: uint. Sort value after the inputed sort value. `0` if no such record exists.
- `above(uint value)`: uint. Count of entries above the inputed sort value. Equal entries are included.
- `below(uint value)`: uint. Count of entries below the inputed sort value. Equal entries are excluded.
- `percentile(uint value)`: uint. Percentile rank of the inputed sort value. All key entries at the given sorted value are considered equivalent and have the same percentile rank. Returns the nearest hit (where if would be) if no such value exists in the tree. 
- `permil(uint value)`: uint. Like percentile, with an extra digit of precision. 
- `atPercentile(uint _percentile):`: uint. Returns the sorted value at a percentile rank. The returned sorted value applies equally all key entries collated in the node in no particular order. Returns the nearest sorted value if no sorted value precisely matches the requested percentile.
- `atPermil(uint _permil)`: uint. Like atPercentile, with an extra digit of precision. 
- `getNode(uint value)`: Returns the tree node details enumerated below.

#### getNode(uint value) and root()

Returns the tree node data including tree structure. There must be at least one sorted value with this value for the node to exist in the tree. Reverts if the node doesn't exist. 

```
Node {
  parent: uint,
  left: uint,
  right: uint,
  red: bool,
  keyCount: uint,
  count: uint
}
```

For applications, the only value that would be generally useful to an application is:

- `getNode(uint value).keyCount `: This is the number of key entries with the same sorted value. For example, identical test scores from multiple students. This informs a client that wishes to iterate the list using:

- `valueKeyAtIndex(uint value, row)`: bytes32. The key associated with the sort value at a given row. 

The remaining values in the `getNode` response expose the internal structure of the tree. This is expected to be useful only for study of the internal structure or constructing other methods of tree exploration.

`parent`, `left` and `right` describe tree organization. `count` (do not confuse with `keyCount`) is the sum of `keyCount` for all nodes in the subtree inclusive of this node. This is not expected to be useful for an application. 

- `root()`: This is the root of the Order Statistics Tree. It is not expected to be useful at an application level. It is the summit of the tree and the only node with no parent. 

#### Owner() and changeOwner()

Simple access control for write operations in the example contract. 

### Reorganization

The root node and node left, right, parent values are subject to change with each insertion or removal transaction. The tree uses the Red Black Tree algorithm to maintain acceptable tree balance. 

### Finite Tree Growth

While it is not a requirement, it is recommended to devise a strategy to ensure a finite number of nodes. This would usually imply limiting precision in the sorted values, limiting the age of the entries or a purpose-built strategy that reliably limits the number of nodes that can exist. In other words, you should be able to show that the maximum number of nodes *possible* will never exceed an acceptable limit.

For example, consider a data set of integers with a possible range of `51-100`. The tree size will be limited to 50 nodes. The nodes will accept unlimited records and it will be possible to estimate a worst-case insertion/deletion cost *at any scale* for a tree with worst-case imbalance at a fixed maximum size.

As a reminder, all entries collated in a particular node are organized *in no particular order*. That is, there would be no ordering assurance for all records stored in the same node, e.g. `53`. *This property makes the maximum insertion/deletion cost manageable*. 

If higher statistical resolution is required, then the same data set could be scaled as set of values in the range of `501-1000`. In effect, `50.1-100.0`. In this case the ordering and statistical analysis will yield an extra decimal of precision. Doing so will result in a maximum possible tree size of 500 nodes and a corresponding increase in the maximum gas cost for insertion and removal operations owing to increased tree depth. 

Other tree growth limiting strategies are possible. For example, a reputation system might expire votes on a FIFO basis, simply discarding the oldest vote when the tree size exceeds a set limit. The growth-limiting strategy is an application-level concern. 

Bokky has informally tested the basic tree up to 10,000 nodes. Do NOT expect the same performance here. This implementation adds additional data (`count`) and recursive logic (implemented as iterative processes) that maintain them, so a gas cost increase is unavoidable. *The gas cost for these processes scales with tree depth.*

## Code Example

The example Solidity file contains an example contract in flattened form. This exposes the Library functions for a single Tree (`...Tree`). Just pull the works into Remix and play. 

If you have trouble getting started, use the singular implementation and:

- `insert: ("0xaa",1)`
- `insert: ("0xab",2)`

Then explore the stats. 

You cannot:

- `insert: ("0xab",2)` because that entry already exists. 

You can:

`remove: ("0xaa",1)` because it does exist. 

You will see that `2` has become the `root()` because of automatic tree reorganization. 

```
contract HitchensOrderStatisticsTree is Owned {
    using HitchensOrderStatisticsTreeLibrary for HitchensOrderStatisticsTreeLibrary.Tree;

    HitchensOrderStatisticsTreeLibrary.Tree tree;

    event Log(string action, bytes32 key, uint value);

    constructor() public {
    }
    function root() public view returns (uint _value) {
        _value = tree.root;
    }
    function first() public view returns (uint _value) {
        _value = tree.first();
    }
    function last() public view returns (uint _value) {
        _value = tree.last();
    }
    function next(uint value) public view returns (uint _value) {
        _value = tree.next(value);
    }
    function prev(uint value) public view returns (uint _value) {
        _value = tree.prev(value);
    }
    function exists(uint value) public view returns (bool _exists) {
        _exists = tree.exists(value);
    }
    function keyExists(bytes32 key, uint value) public view returns(bool _exists) {
        _exists = tree.keyExists(key, value);
    }
    function getNode(uint value) public view returns (uint _parent, uint _left, uint _right, bool _red, uint _keyCount, uint _count) {
        (_parent, _left, _right, _red, _keyCount, _count) = tree.getNode(value);
    }
    function valueKeyAtIndex(uint value, uint row) public view returns(bytes32 _key) {
        _key = tree.valueKeyAtIndex(value,row);
    }
    function count() public view returns(uint _count) {
        _count = tree.count();
    } 
    function percentile(uint value) public view returns(uint _percentile) {
        _percentile = tree.percentile(value);
    }
    function permil(uint value) public view returns(uint _permil) {
        _permil = tree.permil(value);
    }  
    function atPercentile(uint _percentile) public view returns(uint _value) {
        _value = tree.atPercentile(_percentile);
    }
    function atPermil(uint value) public view returns(uint _value) {
        _value = tree.atPermil(value);
    }
    function median() public view returns(uint _value) {
        return tree.median();
    }
    function rank(uint value) public view returns(uint _rank) {
        _rank = tree.rank(value);
    }
    function below(uint value) public view returns(uint _below) {
        _below = tree.below(value);
    }
    function above(uint value) public view returns(uint _above) {
        _above = tree.above(value);
    }    
    function atRank(uint _rank) public view returns(uint _value) {
        _value = tree.atRank(_rank);
    }
    function insert(bytes32 key, uint value) public onlyOwner {
        emit Log("insert", key, value);
        tree.insert(key, value);
    }
    function remove(bytes32 key, uint value) public onlyOwner {
        emit Log("delete", key, value);
        tree.remove(key, value);
    }
}
```

## Motivation

Although I'm a strong believer that the sorting concern can (and should) nearly almost always be externalized from Solidity contracts, this is a generalized approach for those cases when it must be done. The focus is on gas cost optimization. In particular, developer control of the desired statistical and sort-order resolution so that ordered lists don't necessarily carry unnecessary and unacceptable cost. It allows for the idea of "good enough" sorting, "good enough" tree balance and "close enough" statistics that are suitable for many cases where contract logic depends on a sorted list or statistic (median, min, max, etc.) and *there is expected to be a large number of entries*. 

"Good enough" sorting means able to find the *exact median* (or percentile, etc.) value with known precision. Since the Order Tree holds the keys for the sorted entries, applications would normally consult authoratative records (without rounding) to find the exact values if any rounding is performed before inserting into the tree. 

This system gives developers fine-grained control over precision and performance. 

## Tests

NO TESTING OF ANY KIND HAS BEEN PERFORMED AND YOU USE THIS LIBRARY AT YOUR OWN EXCLUSIVE RISK. 

## Contributors

Optimization and clean-up is ongoing. 

The author welcomes pull requests, feature requests, testing assistance and feedback. Contact the author if you would like assistance with customization or calibrating the code for a specific application or gathering of different statistics.

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

Hope it helps.
