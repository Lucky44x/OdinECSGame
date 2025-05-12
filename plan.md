# Planning Document

### Player Stats
- Health                (How much Health does the player have)
- Speed                 (How fast the player can move)
- BaseDamage            (Dmaage of gun = BaseDamage + BulletDamage)
- Strength              (How much can the player carry -- each Item has a weight)

### Modifiers
Could be defined via JSON:   
```JSON
{
    "id": "TMP",
    "effects": [
        {
            "stat": "",
            "operation": "",
            "value": 5
        }
    ]
}
```