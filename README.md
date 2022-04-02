# dice_syntax_gd

Table of Contents
=================

   * [Basic Usage](#basic-usage)
   * [Probability Calculations](#probability-calculations)
   * [Rolling from probabilities](#rolling-from-probabilities)
   * [Error handling](#error-handling)
   * [Supported Syntax](#supported-syntax)
   * [Breaking changes 1.1 to 2.0](#breaking-changes-11-to-20)
   * [License](#license)


## Basic Usage

This addon adds the `dice_syntax` class, only populated with static functions. Simplest
way to use involves using `dice_syntax.roll` with a string and a `RandomNumberGenerator` as an input.

```
var rng = RandomNumberGenerator.new()
print(dice_syntax.roll('4d6k3',rng)) # roll 4d6, keep the highest 3
```
```
{error:False, msg:[], result:11, rolls:[{dice:[6, 4, 1], drop:[1], error:False, msg:[], result:11}]}
```

The output is a `Dictionary` where `result` is the sum of all the dice rolled while `rolls`
includes additional details about the roll.

Alternatively dice parsing and rolling can be separated from each other. You can use
this if you run into bottlenecks since parsing is more expensive than rolling.

```
var rng = RandomNumberGenerator.new()
var parsed_dice = dice_syntax.dice_parser('4d6k3')
print(dice_syntax.roll_parsed(parsed_dice,rng))
```
```

{error:False, msg:[], result:11, rolls:[{dice:[6, 4, 1], drop:[1], error:False, msg:[], result:11}]
```

In addition to it's own syntax, the input will be parsed into an [Expression](https://docs.godotengine.org/en/stable/classes/class_expression.html)
so arbitrary operations can be performed on the dice rolled.

```
var rng = RandomNumberGenerator.new()
print(dice_syntax.roll('2d6/1d2',rng))
```
```
{error:False, msg:[], result:3.5, rolls:[{dice:[6, 1], drop:[], error:False, msg:[], result:7}, {dice:[2], drop:[], error:False, msg:[], result:2}]}
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
var parsed_dice = dice_syntax.dice_parser('4d6d1')
print(dice_syntax.parsed_dice_probs(parsed_dice))
```
```
{10:0.094136, 11:0.114198, 12:0.128858, 13:0.132716, 14:0.123457, 15:0.10108, 16:0.072531, 17:0.041667, 18:0.016204, 3:0.000772, 4:0.003086, 5:0.007716, 6:0.016204, 7:0.029321, 8:0.04784, 9:0.070216}
```

## Rolling from probabilities

Random numbers can be generated from arbitrary dictionaries that include keys as outcomes
and values as weights, matching the output of probability calculation functions.

```
var dict = {1:0.5,2:0.5}
print(dice_syntax.roll_from_probs(dict,rng,10))
```
```
[2, 2, 1, 2, 2, 1, 1, 2, 1, 1]
```

```
var probs = dice_syntax.dice_probs('1d2')
print(dice_syntax.roll_from_probs(probs,rng,10))
```
```
[2, 1, 1, 2, 1, 1, 1, 1, 1, 2]
```



## Error handling

If the parser fails to parse any component of the dice, you will get a console error
which is also added to the output object

```
print(dice_syntax.roll("help i'm trapped in a dice factory+1d6",rng))
```
```
{error:True, msg:[Expression fails to execute], result:0, rolls:[{dice:[2], drop:[], error:False, msg:[], result:2}]}
```

Note that the final result will be set to 0 even if part of the dice was able to be rolled.

```
print(dice_syntax.roll("1d1r1+1d6",rng)) # first dice will return an error since all possible outcomes are rerolled.
```
```
{error:True, msg:[Invalid dice: No possible results], result:0, rolls:[{dice:[], drop:[], error:True, msg:[Invalid dice: No possible results], result:0}, {dice:[1], drop:[], error:False, msg:[], result:1}]}
```

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
- `4d6+2d5/2`: perform arbitrary mathematical operations. The statements are turned into [Expressions](https://docs.godotengine.org/en/stable/classes/class_expression.html) so everything supported by them will work fine. Note that outputs of dice will always be `float`s.
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

## Breaking changes 1.1 to 2.0

Some function names are changed and a few moved to non-exposed files to make 
things clearer for the end user. The new format can be considered stable

- `comp_dice_parser` is now `dice_parser`
- `roll_comp` is now `roll_parsed`
- `comp_dice_probs` is now `parsed_dice_probs`

## License

This project is released under MIT license

The icon included is created by Delapouite under CC BY 3.0, taken from https://game-icons.net/
