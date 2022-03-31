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



func test_dice_mean():
	var roll = dice_syntax.roll('100d10',rng).result
	assert_between(roll,454.0,646.0,'basic mean')
	
	var m_roll = mean_tester('4d6k3')
	assert_between(m_roll,11.5,13.0,'drop lowest')
	
	m_roll = mean_tester('4d6kl3')
	assert_between(m_roll,7.0,10.5,'keep lowest')
	
	m_roll = mean_tester('1d20+1')
	assert_between(m_roll,11.0,12.0,'add value')
	
	m_roll = mean_tester('1d20-1')
	assert_between(m_roll,9.0,10.0,'subtract value')
	
	m_roll = mean_tester('1d6r1r2r3r4r5')
	assert_true(m_roll==6.0,'reroll')
	
	m_roll = mean_tester('1d6r<5')
	assert_true(m_roll==6.0,'reroll range')
	
	m_roll = mean_tester('1d6ro1')
	assert_between(m_roll,3.9,4.1,'reroll once')
	
	m_roll = mean_tester('1d6!')
	assert_between(m_roll,4.1,4.3,'explode')



func test_probs():
	
	var probs = dice_syntax.dice_probs('1d4')
	assert_true(probs[1.0] == 0.25,'wrong probabilies')
	
	probs = dice_syntax.dice_probs('4d6d1')
	assert_almost_eq(probs[3.0],0.000772,0.0001,"wrong probabilities")
	
	probs = dice_syntax.dice_probs('13')
	assert_almost_eq(probs[13.0],1,0.0001, "wrong probabilities")

func test_parsing():
	var parsed = dice_syntax.dice_parser('3d6+2d6')
	assert_true(typeof(parsed) == TYPE_DICTIONARY)
	assert_true(parsed.rules_array.size() == 2)
	
	var rolled = dice_syntax.roll_parsed(parsed,rng)
	assert_true(typeof(rolled) == TYPE_DICTIONARY)
	assert_true(rolled.rolls.size() == 2)
	
	assert_false(rolled.error)
