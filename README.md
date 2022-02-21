# dice_syntax_gd

## Basic Usage

This addon adds the `dice_syntax` class, only populated with static functions. Simplest
way to use involves using `dice_syntax.roll` with a string and a `RandomNumberGenerator` as an input.

```
var rng = RandomNumberGenerator.new()
print(dice_syntax.roll('4d6k3',rng)) # roll 4d6, keep the highest 3
```
```
{result:9, rolls:[{dice:[2, 3, 4], drop:[1], error:False, msg:, result:9}]}
```

The output is a `Dictionary` where `result` is the sum of all the dice rolled while `rolls`
includes additional details about the roll.

Alternatively dice parsing and rolling can be separated from each other.

```
var rng = RandomNumberGenerator.new()
var parsed_dice = dice_syntax.comp_dice_parser('4d6k3')
print(dice_syntax.roll_comp(parsed_dice,rng))
```
```
{result:9, rolls:[{dice:[2, 3, 4], drop:[1], error:False, msg:, result:9}]}
```
## Probability Calculations

You can calculate probabilities for a given dice roll.

```
print(dice_syntax.dice_probs('4d6d1'))
```
```
{10:0.094136, 11:0.114198, 12:0.128858, 13:0.132716, 14:0.123457, 15:0.10108, 16:0.072531, 17:0.041667, 18:0.016204, 3:0.000772, 4:0.003086, 5:0.007716, 6:0.016204, 7:0.029321, 8:0.04784, 9:0.070216}
```

Use `dice_syntax.expected_value` to get the mean result
```
var probs = dice_syntax.dice_probs('4d6d1')
print(dice_syntax.expected_value(probs))
```
```
12.244599
```

As with rolling you can separate parsing and calculation of probabilities.
```
var parsed_dice = dice_syntax.comp_dice_parser('4d6d1')
print(dice_syntax.comp_dice_probs(parsed_dice))
```
```
{10:0.094136, 11:0.114198, 12:0.128858, 13:0.132716, 14:0.123457, 15:0.10108, 16:0.072531, 17:0.041667, 18:0.016204, 3:0.000772, 4:0.003086, 5:0.007716, 6:0.016204, 7:0.029321, 8:0.04784, 9:0.070216}
```

## Error handling

If the parser fails to parse any component of the dice, you will get a console error
which is also added to the output object

```
print(dice_syntax.roll("help i'm trapped in a dice factory+1d6",rng))
```
```
{error:True, msg:[Malformed dice string], result:0, rolls:[{dice:[], drop:[], error:True, msg:[Malformed dice string], result:0}, {dice:[4], drop:[], error:False, msg:[], result:4}]}
```

Note that the final result is set to 0 even if part of the dice was able to be rolled.

Probability calculations will return a `{0:1}` if the input dice contains an error
```
print(dice_syntax.dice_probs("help i'm trapped in a dice factory+1d6"))
```
```
{0:1}
```

## Supported Syntax

- `4d6`: roll 4 six sided dice
- `4d6s`: roll 4d6 sort the results
- `4d6+3d3`: roll 4d6 and 3d3, sum the results
- `4d6-3d3`: Same as above, subtract 3d3 from 4d6.
- `4d6+1`: roll 4d6 add 1 to the result
- `4d6d1`: roll 4d6, drop the lowest one
- `4d6dh1`: roll 4d6, drop the highest one
- `4d6k1`: roll 4d6, keep the highest one
- `4d6kl1:` roll 4d6, keep the lowest one
- `4d6r1`: roll 4d6 reroll all 1s (1 is not a possible result)
- `4d6ro1`: roll 4d6 reroll 1s once
- `4d6r<2`: roll 4d6 reroll all 1s and 2s (not possible results)
- `4d6ro<2`: roll 4d6 reroll1s and 2s once
- `4d6!`: roll 4d6 explode 6s (for every six, roll again until a non six is rolled, add them to the rolls. The output will have variable number of dice)
- `4d6!!`: roll 4d6 compound 6s (for every six, roll again until a non six is rolled, combined them into a single roll in the output. The output will have 4 dice)
- `4d6!>5`: roll 4d6 explode 5s and 6s

## License

This project is released under MIT license

The icon included is created by Delapouite under CC BY 3.0, taken from https://game-icons.net/
