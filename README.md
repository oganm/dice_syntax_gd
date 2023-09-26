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
{result:11, rolls:[{error:false, msg:[], dice:[6, 4, 1], drop:[1], result:11}], error:false, msg:[]}
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
{result:11, rolls:[{error:false, msg:[], dice:[6, 4, 1], drop:[1], result:11}], error:false, msg:[]}
```

In addition to it's own syntax, the input will be parsed into an [Expression](https://docs.godotengine.org/en/stable/classes/class_expression.html)
so arbitrary operations can be performed on the dice rolled.

```
var rng = RandomNumberGenerator.new()
print(dice_syntax.roll('2d6/1d2',rng))
```
```
{result:3.5, rolls:[{error:false, msg:[], dice:[6, 1], drop:[], result:7}, {error:false, msg:[], dice:[2], drop:[], result:2}], error:false, msg:[]}
```


## Probability Calculations

You can calculate probabilities for a given dice roll.

```
print(dice_syntax.dice_probs('4d6d1'))
```
```
{3:0.00077160493827, 4:0.00308641975309, 5:0.00771604938272, 6:0.0162037037037, 7:0.02932098765432, 8:0.04783950617284, 9:0.07021604938272, 10:0.09413580246914, 11:0.1141975308642, 12:0.12885802469136, 13:0.13271604938272, 14:0.12345679012346, 15:0.10108024691358, 16:0.07253086419753, 17:0.04166666666667, 18:0.0162037037037}
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
{3:0.00077160493827, 4:0.00308641975309, 5:0.00771604938272, 6:0.0162037037037, 7:0.02932098765432, 8:0.04783950617284, 9:0.07021604938272, 10:0.09413580246914, 11:0.1141975308642, 12:0.12885802469136, 13:0.13271604938272, 14:0.12345679012346, 15:0.10108024691358, 16:0.07253086419753, 17:0.04166666666667, 18:0.0162037037037}
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
{result:0, rolls:[{error:false, msg:[], dice:[2], drop:[], result:2}], error:true, msg:[Expression fails to execute]}
```

Note that the final result will be set to 0 even if part of the dice was able to be rolled.

```
print(dice_syntax.roll("1d1r1+1d6",rng)) # first dice will return an error since all possible outcomes are rerolled.
```
```
{result:0, rolls:[{error:true, msg:[Invalid dice: No possible results], dice:[], drop:[], result:0}, {error:false, msg:[], dice:[1], drop:[], result:1}], error:true, msg:[Invalid dice: No possible results]}
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
- `4d6d=1:` roll 4d6s drop all 1s
- `4d6k>5:` roll 4d6s keep only 5s and 6s
- `4d6d<2:` roll 4d6s drop all 1s and 2s
- `4d6r1`: roll 4d6 reroll all 1s (1 is not a possible result)
- `4d6ro1`: roll 4d6 reroll 1s once
- `4d6r<2`: roll 4d6 reroll all 1s and 2s (not possible results)
- `4d6ro<2`: roll 4d6 reroll1s and 2s once
- `4d6!`: roll 4d6 explode 6s (for every six, roll again until a non six is rolled, add them to the rolls. The output will have variable number of dice)
- `4d6!!`: roll 4d6 compound 6s (for every six, roll again until a non six is rolled, combined them into a single roll in the output. The output will have 4 dice)
- `4d6!>5`: roll 4d6 explode 5s and 6s

## Breaking changes 2.2.2 to 3.0

- The syntax is checked more rigidly in this version, preventing inclusion of meaningless
symbols within dice strings. Nothing should break if inteded functionality was being
used.
- The parser checks for using invalid numeric notations normally accepted by godot
`Expressions`. A meaningless string like "5random_letters" no longer resolved to 5

## Breaking changes 1.1 to 2.0

Some function names are changed and a few moved to non-exposed files to make 
things clearer for the end user. The new format can be considered stable

- `comp_dice_parser` is now `dice_parser`
- `roll_comp` is now `roll_parsed`
- `comp_dice_probs` is now `parsed_dice_probs`

## License

This project is released under MIT license

The icon included is created by Delapouite under CC BY 3.0, taken from https://game-icons.net/
