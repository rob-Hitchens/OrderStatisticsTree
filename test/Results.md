## steps_1.json


Notice 
valueRank(276) returns 5 
valueRank(290) returns 5
valueKeyCount() returns 43

```
element, rank, rankReal, keycount
32 1 1986 43 44
52 2 1946 43 43
121 3 1885 43 42
170 4 1839 43 41
276 5 1836 43 40
290 5 1836 43 39
312 6 1823 43 38
379 7 1822 43 37
415 8 1800 43 36
505 9 1719 43 35
538 10 1701 43 34
567 11 1632 43 33
589 12 1580 43 32
628 13 1574 43 31
631 14 1462 43 30
739 15 1323 43 29
766 16 1276 43 28
824 17 1229 43 27
859 18 1174 43 26
885 19 1112 43 25
896 20 1014 43 24
973 21 1005 43 23
980 22 980 43 22
1005 23 973 43 21
1014 24 896 43 20
1112 25 885 43 19
1174 26 859 43 18
1229 27 824 43 17
1276 28 766 43 16
1323 29 739 43 15
1462 30 631 43 14
1574 31 628 43 13
1580 32 589 43 12
1632 33 567 43 11
1701 34 538 43 10
1719 35 505 43 9
1800 36 415 43 8
1822 37 379 43 7
1823 38 312 43 6
1836 39 290 43 5
1839 40 170 43 4
1885 41 121 43 3
1946 42 52 43 2
1986 43 32 43 1
```

```
Tree Properties
Count 43
First 32
Last 1986
Root Value 1276
```

valueAtRank(4) returns 170
valueAtRank(5) returns 290

```
ValueAtRank
element, value, real
1 32 1986
2 52 1946
3 121 1885
4 170 1839
5 290 1836
6 312 1823
```

Notice value 276 is in the tree

```
Node Details, (crawled in order), value, parent, left, right, red, keyCount, count
32 52 0 0 true 1 1
52 121 32 0 false 1 2
121 290 52 276 false 1 4
170 276 0 0 true 1 1
276 121 170 0 false 1 1
290 739 121 415 true 1 14
312 379 0 0 true 1 1
379 415 312 0 false 1 2
```

## steps_2.json
This simply removes the 276 value as the last step
Notic the Count in Tree Properties does not change

```
Tree Properties
Count 43
First 32
Last 1986
Root Value 1276
```

## steps_3.json
This inserts 276 after the delete which was done in `steps_2.json`

Tree works as expected

```
Tree Properties
Count 44
First 32
Last 1986
Root Value 1276
```

`valueRank()` works as expected

```
element, rank, rankReal, keycount
32 1 1986 44 45
52 2 1946 44 44
121 3 1885 44 43
170 4 1839 44 42
276 5 1836 44 41
290 6 1823 44 40
312 7 1822 44 39
379 8 1800 44 38
```

`valueAtRank()` works as expected

```
ValueAtRank
element, value, real
1 32 1986
2 52 1946
3 121 1885
4 170 1839
5 276 1836
6 290 1823
7 312 1822
8 379 1800
```


