## Hitchens Order Statistics Tree, Solidity v0.8.17

### Tests
We use Brownie framework for developing and unit test. For run tests
first please [install it](https://eth-brownie.readthedocs.io/en/stable/install.html)  
To run long tests you must rename test files in tests folder before running (delete "long_").

```bash
#brownie pm install OpenZeppelin/openzeppelin-contracts@4.7.3
brownie test
```

Now tests are running in very verbose mode. For off this mode please edit `pyproject.toml`
in the root folder.

At commit moment (2022-10-31) test coverage was 83%
```bash
  contract: MockHOSTV1 - 83.8%
    HitchensOrderStatisticsTreeLibV1.exists - 100.0%
    HitchensOrderStatisticsTreeLibV1.getNode2 - 100.0%
    HitchensOrderStatisticsTreeLibV1.insertFixup - 100.0%
    HitchensOrderStatisticsTreeLibV1.keyExists - 100.0%
    HitchensOrderStatisticsTreeLibV1.prev - 100.0%
    HitchensOrderStatisticsTreeLibV1.rotateLeft - 100.0%
    HitchensOrderStatisticsTreeLibV1.rotateRight - 100.0%
    HitchensOrderStatisticsTreeLibV1.valueKeyAtIndex - 100.0%
    HitchensOrderStatisticsTreeLibV1.atRank - 96.4%
    HitchensOrderStatisticsTreeLibV1.insert - 95.0%
    HitchensOrderStatisticsTreeLibV1.rank - 88.2%
    HitchensOrderStatisticsTreeLibV1.below - 87.5%
    HitchensOrderStatisticsTreeLibV1.next - 80.0%
    HitchensOrderStatisticsTreeLibV1.above - 75.0%
    HitchensOrderStatisticsTreeLibV1.getNode - 75.0%
    HitchensOrderStatisticsTreeLibV1.removeFixup - 73.7%
    HitchensOrderStatisticsTreeLibV1.remove - 63.3%
    HitchensOrderStatisticsTreeLibV1.replaceParent - 0.0%

```


### Gas
```bash
MockHOSTV1 <Contract>
   ├─ constructor    -  avg: 1945401  avg (confirmed): 1945401  low: 1945401  high: 1945401
   ├─ insertKeyValue -  avg:  136848  avg (confirmed):  141383  low:   23985  high:  260610
   └─ removeKeyValue -  avg:   75151  avg (confirmed):   79721  low:   23941  high:  174703
```
