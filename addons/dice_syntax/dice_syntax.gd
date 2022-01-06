extends GDScript
class_name dice_syntax




static func dice_parser(dice_string:String)->Dictionary:
	var sm = preload('string_manip.gd')
	var al = preload('array_logic.gd')
	
	var rolling_rules: Dictionary = {'error': false, 
	'msg': [],
	'add':0,
	'reroll_once': [],
	'reroll': [],
	'possible_dice': [],
	'drop_dice':0}
	var valid_tokens = '[dksr!]'
	
	dice_string = dice_string.to_lower()
	
	
	# if its an integer just add a number
	if dice_string.is_valid_integer():
		rolling_rules['add'] = int(dice_string)
		rolling_rules['dice_count'] = 0
		rolling_rules['dice_side'] = 0
		rolling_rules['sort'] = false
		rolling_rules['explode'] = []
		rolling_rules['compound'] = []
		rolling_rules['possible_dice'] =[]
		return rolling_rules
	
	
	# get the dice count or default to 1 if we just start with d.
	var result = sm.str_extract(dice_string,'^[0-9]*?(?=d)')
	dice_error(result!=null,'Malformed dice string',rolling_rules)
	if result == '':
		rolling_rules['dice_count'] = 1
	elif result.is_valid_integer():
		rolling_rules['dice_count'] = int(result)
	
	# tokenize the rest of the rolling rules. a token character, followed by the
	# next valid token character or end of string. while processing, remove
	# all processed tokens and check for anything leftower at the end
		
	var tokens = sm.str_extract_all(dice_string,
	valid_tokens + '.*?((?=' + valid_tokens + ')|$)')
	
	
	var dice_side = sm.str_extract(tokens[0],'(?<=d)[0-9]+')
	dice_error(dice_side != null, "Malformed dice string: Unable to detect dice sides",rolling_rules)
	rolling_rules['dice_side'] = int(dice_side)
	# remove dice side token to make sure it's not confused with the drop rule
	tokens.remove(0)
	
	# check for sort rule, if s exists, sort the results
	var sort_rule = tokens.find('s')
	rolling_rules['sort'] = sort_rule != -1
	if sort_rule != -1:
		tokens.remove(sort_rule)
	
	# check for drop rules, there can only be one 
	var drop_rules = sm.strs_detect(tokens,'^(d|k)(h|l)?[0-9]+$')
	dice_error(drop_rules.size() <= 1,"Malformed dice string: Can't include more than one drop rule",rolling_rules)
	if drop_rules.size() == 0:
		rolling_rules['drop_dice'] = 0
		rolling_rules['drop_lowest'] = true
	else:
		var drop_count = sm.str_extract(tokens[drop_rules[0]], '[0-9]+$')
		dice_error(drop_count!= null, 'Malformed dice string: No drop count provided',rolling_rules)
		var drop_rule = tokens[drop_rules[0]]
		match drop_rule.substr(0,1):
			'd':
				rolling_rules['drop_dice'] = int(drop_count)
			'k':
				rolling_rules['drop_dice'] = int(rolling_rules['dice_count'])-int(drop_count)	
		rolling_rules['drop_lowest'] = !(sm.str_detect(drop_rule,'dh') or sm.str_detect(drop_rule,'kl'))
		tokens.remove(drop_rules[0])
	
	# reroll rules
	var reroll_rules = sm.strs_detect(tokens,'r(?!o)')
	var reroll:Array = []
	for i in reroll_rules:
		reroll.append_array(range_determine(tokens[i], rolling_rules['dice_side']))
	var dicePossibilities = range(1,rolling_rules['dice_side']+1)
	if al.all(al.array_in_array(dicePossibilities,reroll)):
		push_error('Malformed dice string: rerolling all results')
		rolling_rules['reroll'] = []
	else:
		rolling_rules['reroll'] = reroll
	# remove reroll rules
	reroll_rules.invert()
	for i in reroll_rules:
		tokens.remove(i)
	
	# reroll once
	reroll_rules = sm.strs_detect(tokens,'ro')
	var reroll_once:Array = []
	for i in reroll_rules:
		reroll_once.append_array(range_determine(tokens[i], rolling_rules['dice_side']))
	rolling_rules['reroll_once'] = reroll_once
	
	reroll_rules.invert()
	for i in reroll_rules:
		tokens.remove(i)
	
	
	# new explode rules
	var explode_rules = sm.strs_detect(tokens,'!')
	var explode:Array = []
	var compound: Array = []
	var compound_flag:bool = false
	for i in explode_rules:
		if i != INF:
			if tokens[i] == '!' and i+1 in explode_rules:
				compound_flag = true
			elif not compound_flag:
				explode.append_array(range_determine(tokens[i], rolling_rules['dice_side'],rolling_rules['dice_side']))
			elif compound_flag:
				compound_flag = false
				compound.append_array(range_determine(tokens[i], rolling_rules['dice_side'],rolling_rules['dice_side']))
	rolling_rules['explode'] = explode
	rolling_rules['compound'] = compound
	explode_rules.invert()
	for i in explode_rules:
		tokens.remove(i)
	
	dice_error(tokens.size()==0, 'Malformed dice string: Unprocessed tokens',rolling_rules)
	var possible_dice = range(1,rolling_rules.dice_side+1)
	possible_dice = al.array_subset(possible_dice,al.which(al.array_not(al.array_in_array(possible_dice, rolling_rules.reroll))))
	dice_error(possible_dice.size()>0,"Invalid dice: No possible results",rolling_rules)
	dice_error(not al.all(al.array_in_array(possible_dice,rolling_rules.explode)),"Invalid dice: can't explode every result",rolling_rules)
	dice_error(not al.all(al.array_in_array(possible_dice,rolling_rules.compound)),"Invalid dice: can't compound every result",rolling_rules)
	rolling_rules['possible_dice'] = possible_dice
	
	dice_error(not (rolling_rules.explode.size()>0 and rolling_rules.compound.size()>0), "Invalid dice: can't explode and compound with the same dice",rolling_rules)
		
	
	return rolling_rules

static func range_determine(token:String,dice_side:int, default:int = 1)->Array:
	var sm = preload('string_manip.gd')
	var out:Array = []
	var number = sm.str_extract(token, '[0-9]*$')
	# dice_error(!(sm.str_detect(token,'<|>') and number ==''),'Malformed dice string: Using  "<" or ">" identifiers requires an integer',rolling_rules)
	# dice_error(!(sm.str_detect(token,'<') and sm.str_detect(token,'>')),'Malformed dice string: A range clause can only have one of "<" or ">"',rolling_rules)
	if !sm.str_detect('<|>',token) and number == '':
		out.append(default)
	elif number != '' and !sm.str_detect(token, '<|>'):
		out.append(int(number))
	elif sm.str_detect(token, '<') and number != '':
		out.append_array(range(1,int(number)+1))
	elif sm.str_detect(token, '>') and number != '':
		out.append_array(range(int(number),dice_side+1))
	
	return out

# add error information to the output if something goes wrong.
# dictionaries are passed by reference
static func dice_error(condition:bool,message:String,rolling_rules:Dictionary):
	if(!condition):
		push_error(message)
		rolling_rules['error'] = true
		rolling_rules['msg'].append(message)


static func roll_param(rolling_rules:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var al = preload('array_logic.gd')
	var out:Dictionary = {'error': false,
	 'msg': '',
	'dice': [],
	'drop': [],
	'result':0}
	
	if rolling_rules.error:
		out['error'] = true
		out['msg'] = rolling_rules.msg
		return out
	
	# setting the possible results with rerolls removed from possible results
	var possible_dice = rolling_rules.possible_dice
	
	# initial roll
	var dice = al.sample(possible_dice,rolling_rules.dice_count,rng)

	
	# reroll once
	var to_reroll = al.which_in_array(dice,rolling_rules.reroll_once)

	for i in to_reroll:
		dice[i] = al.sample(possible_dice,1,rng)[0]
	
	
	if rolling_rules.explode.size()>0:
		var exploded_dice = []
		for d in dice:
			var x = d
			exploded_dice.append(d)
			while x in rolling_rules.explode:
				x = al.sample(possible_dice,1,rng)[0]
				# if new roll is in the reroll once list, reroll
				if x in rolling_rules.reroll_once:
					x = al.sample(possible_dice,1,rng)[0]
				exploded_dice.append(x)
		dice = exploded_dice
	
	if rolling_rules.compound.size()>0:
		var compounded_dice = []
		for d in dice:
			var com_result = d
			var x = d
			while x in rolling_rules.compound:
				x = al.sample(possible_dice,1,rng)[0]
				if x in rolling_rules.reroll_once:
					x = al.sample(possible_dice,1,rng)[0]
				com_result += x
			compounded_dice.append(com_result)
		dice = compounded_dice
	
	if rolling_rules.sort:
		dice.sort()
	
	if rolling_rules.drop_dice>0:
		var ordered_dice = dice.duplicate()
		ordered_dice.sort()
		var drop = []
		if !rolling_rules.drop_lowest:
			ordered_dice.invert()
		for i in range(0,rolling_rules.drop_dice):
			drop.append(ordered_dice[i])
		var new_dice = []
		var drop_copy = drop.duplicate()
		for x in dice:
			if not x in drop_copy:
				new_dice.append(x)
			else:
				drop_copy.remove(drop_copy.find(x))
		dice = new_dice
		out['drop'] = drop
		
	
	
	out['dice'] = dice
	out['result'] = al.sum(dice)
	
	out['result'] += rolling_rules.add
	
	return out


static func composite_dice_parser(dice:String)->Dictionary:
	var sm = preload('string_manip.gd')
	
	var dice_components = sm.str_split(dice,'\\+|-')
	var string_signs = sm.str_extract_all(dice,'\\+|-')
	var component_signs = []
	if dice.begins_with('-'):
		dice_components.remove(0)
	elif dice.begins_with('+'):
		dice_components.remove(0)
	else:
		component_signs.append(1)
	
	for i in range(string_signs.size()):
		component_signs.append(int(string_signs[i] + '1'))
	var rules_array = []
	
	for x in dice_components:
		var rr = dice_parser(x)
		rules_array.append(rr)
	
	return {'rules_array': rules_array, 'signs':component_signs}

static func roll(dice:String,rng:RandomNumberGenerator,return_rolls = true):
	var results:Array
	var rules = composite_dice_parser(dice)
	for i in range(rules.rules_array.size()):
		var result = roll_param(rules.rules_array[i],rng)
		result.result *= rules.signs[i]
		results.append(result)
	
	var sum = 0
	for x in results:
		sum += x.result
	
	var out = {'result':sum, 'rolls':results}
	
	return out
	


static func _test(rng:RandomNumberGenerator):
	print('running dice tests')
	rng.randomize()
	# basic dice
	var roll = roll('100d10',rng).result
	assert(roll>454,'bad mean roll')
	assert(roll<646,'bad mean roll')
	# keep drop	
	var rolls = 0
	for i in range(1000):
		rolls += roll('4d6k3',rng).result
	rolls = rolls/1000
	assert(rolls>11.5,'bad mean roll')
	assert(rolls<13,'bad mean roll')
	rolls = 0
	for i in range(1000):
		rolls += roll('4d6kl3',rng).result
	rolls = rolls/1000
	assert(rolls>7,'bad mean roll')
	assert(rolls<10.5,'bad mean roll')
	# plus minus
	rolls = 0
	for i in range(1000):
		rolls+= roll('1d20+1',rng).result
	rolls = rolls/1000
	assert(rolls>11,'bad mean roll')
	assert(rolls<12,'bad mean roll')
	rolls = 0
	for i in range(1000):
		rolls+= roll('1d20-1',rng).result
	rolls = rolls/1000
	assert(rolls>9,'bad mean roll')
	assert(rolls<10,'bad mean roll')
	# reroll
	rolls = 0
	for i in range(1000):
		rolls+= roll('10d6r1r2r3r4r5',rng).result
	rolls = rolls/1000
	assert(rolls == 60)
	rolls = 0
	for i in range(1000):
		rolls+= roll('10d6r<5',rng).result
	rolls = rolls/1000
	assert(rolls == 60)
	for i in range(1000):
		rolls+= roll('10d6ro1',rng).result
	rolls = rolls/1000
	assert(rolls>39,'bad mean roll')
	assert(rolls<41,'bad mean roll')
