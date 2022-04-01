extends "res://addons/gut/test.gd"

var rng = RandomNumberGenerator.new()


func before_all():
	rng.seed = 0

func mean_tester(dice:String, n = 1000):
	var rolls = 0
	for _i in range(n):
		rolls += dice_syntax.roll(dice,rng).result
	rolls = rolls/n
	return rolls


func test_maths_parsing():
	var parsed = dice_syntax.dice_parser('pow(1d2,1d2)')
	assert_true(parsed.rules_array.size()==2)
	assert_true(parsed.expression_string == 'pow(z,a)')
	assert_true(parsed.dice_expression.execute([2,2])==4)
	
	var probs = dice_syntax.parsed_dice_probs(parsed)
	assert_almost_eq(probs[1.0],0.5,0.0001, "wrong probabilities")
	assert_almost_eq(probs[2.0],0.25,0.0001, "wrong probabilities")
