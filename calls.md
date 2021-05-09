# Code patterns

```
t =CRDL.deploy(100,100,100,10,10,15,chain.time(), 86400, 86400, 84000, {'from':accounts[0]})
t.commit(34800169113441137656655510613550640410253994535886922253593317958438436228110, {'from':accounts[1], 'value
': 221})
chain.sleep(86400)
accounts[1].balance()
t.reveal(5,654,{'from':accounts[1]})
chain.sleep(86400)
accounts[1].balance()
t.countRewards({'from':accounts[1]})
```

