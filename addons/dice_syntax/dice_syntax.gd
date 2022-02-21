extends GDScript
class_name dice_syntax



# basic dice parser for single rolls
static func dice_parser(dice_string:String)->Dictionary:
	var sm = preload('string_manip.gd')
	var al = preload('array_logic.gd')
	var dh = preload('dice_helpers.gd')
	
	var rolling_rules: Dictionary = {'error': false, 
	'msg': [],
	'add':0,
	'reroll_once': [],
	'reroll': [],
	'possible_dice': [],
	'drop_dice':0,
	'drop_lowest':true}
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
	dh.dice_error(result!=null,'Malformed dice string',rolling_rules)
	if result == '':
		rolling_rules['dice_count'] = 1
	elif result == null:
		return rolling_rules
	elif result.is_valid_integer():
		rolling_rules['dice_count'] = int(result)
	
	# tokenize the rest of the rolling rules. a token character, followed by the
	# next valid token character or end of string. while processing, remove
	# all processed tokens and check for anything leftower at the end
		
	var tokens = sm.str_extract_all(dice_string,
	valid_tokens + '.*?((?=' + valid_tokens + ')|$)')
	
	
	var dice_side = sm.str_extract(tokens[0],'(?<=d)[0-9]+')
	dh.dice_error(dice_side != null, "Malformed dice string: Unable to detect dice sides",rolling_rules)
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
	dh.dice_error(drop_rules.size() <= 1,"Malformed dice string: Can't include more than one drop rule",rolling_rules)
	if drop_rules.size() == 0:
		rolling_rules['drop_dice'] = 0
		rolling_rules['drop_lowest'] = true
	else:
		var drop_count = sm.str_extract(tokens[drop_rules[0]], '[0-9]+$')
		dh.dice_error(drop_count!= null, 'Malformed dice string: No drop count provided',rolling_rules)
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
		reroll.append_array(dh.range_determine(tokens[i], rolling_rules['dice_side']))
	var dicePossibilities = range(1,rolling_rules['dice_side']+1)
	# dice_error(!al.all(al.array_in_array(dicePossibilities,reroll)),'Malformed dice string: rerolling all results',rolling_rules)
	rolling_rules['reroll'] = reroll
	# remove reroll rules
	reroll_rules.invert()
	for i in reroll_rules:
		tokens.remove(i)
	
	# reroll once
	reroll_rules = sm.strs_detect(tokens,'ro')
	var reroll_once:Array = []
	for i in reroll_rules:
		var to_reroll = dh.range_determine(tokens[i], rolling_rules['dice_side'])
		dh.dice_error(al.which_in_array(to_reroll,reroll_once).size()==0,"Malformed dice string: can't reroll the same number once more than once.",rolling_rules)
		reroll_once.append_array(dh.range_determine(tokens[i], rolling_rules['dice_side']))
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
				explode.append_array(dh.range_determine(tokens[i], rolling_rules['dice_side'],rolling_rules['dice_side']))
			elif compound_flag:
				compound_flag = false
				compound.append_array(dh.range_determine(tokens[i], rolling_rules['dice_side'],rolling_rules['dice_side']))
	rolling_rules['explode'] = explode
	rolling_rules['compound'] = compound
	explode_rules.invert()
	for i in explode_rules:
		tokens.remove(i)
	
	dh.dice_error(tokens.size()==0, 'Malformed dice string: Unprocessed tokens',rolling_rules)
	var possible_dice = range(1,rolling_rules.dice_side+1)
	possible_dice = al.array_subset(possible_dice,al.which(al.array_not(al.array_in_array(possible_dice, rolling_rules.reroll))))
	dh.dice_error(possible_dice.size()>0,"Invalid dice: No possible results",rolling_rules)
	dh.dice_error(not (al.all(al.array_in_array(possible_dice,rolling_rules.explode)) and rolling_rules.explode.size()>0),"Invalid dice: can't explode every result",rolling_rules)
	dh.dice_error(not (al.all(al.array_in_array(possible_dice,rolling_rules.compound)) and rolling_rules.compound.size()>0),"Invalid dice: can't compound every result",rolling_rules)
	dh.dice_error(al.which_in_array(rolling_rules.explode,rolling_rules.compound).size()==0,"Invalid dice: Can't explode what you compound.",rolling_rules)
	dh.dice_error(rolling_rules.drop_dice<rolling_rules.dice_count,'Invalid dice: cannot drop all the dice you have',rolling_rules)
	rolling_rules['possible_dice'] = possible_dice
	
	dh.dice_error(not (rolling_rules.explode.size()>0 and rolling_rules.compound.size()>0), "Invalid dice: can't explode and compound with the same dice",rolling_rules)
		
	
	return rolling_rules

# rolling a single roll from a parsed rules
static func roll_param(rolling_rules:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var al = preload('array_logic.gd')
	var out:Dictionary = {'error': false,
	 'msg': [],
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

# parsing composite rolls (with +,- in the string)
static func comp_dice_parser(dice:String)->Dictionary:
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

# rolling any dice, includes parsing and rolling
static func roll(dice:String,rng:RandomNumberGenerator)->Dictionary:
	var rules = comp_dice_parser(dice)
	return roll_comp(rules,rng)


# roll composite rolls from parsed rules
static func roll_comp(rules:Dictionary, rng:RandomNumberGenerator)->Dictionary:
	var results:Array
	var error = false
	var msg = []
	
	for i in range(rules.rules_array.size()):
		var result = roll_param(rules.rules_array[i],rng)
		result.result *= rules.signs[i]
		results.append(result)
		if(rules.rules_array[i].error):
			error = true
		msg.append_array(rules.rules_array[i].msg)
	
	var sum = 0
	for x in results:
		sum += x.result
	
	if error:
		sum = 0
	
	var out = {'result':sum, 'rolls':results,'error': error, 'msg': msg}
	return out

# calucate probabilities of a single roll
static func calc_probs(rules:Dictionary,explode_depth:int = 3)->Dictionary:
	var al = preload('array_logic.gd')
	var dh = preload('dice_helpers.gd')
	
	if rules.error:
		var probs = {0:1}
		return probs
	
	# add can only appear alone
	if rules.add>0:
		return {rules.add:1}
	
	var base_prob = 1.0/rules.possible_dice.size()
	
	# base probabilities
	var probs:Dictionary
	for x in rules.possible_dice:
		probs[x] = base_prob
		
	
	# reroll once adjustment
	var reroll_prob = pow(base_prob, 2.0)
	var prob_to_add = 0
	for x in rules.reroll_once:
		probs[x] = 0
		prob_to_add += reroll_prob
	
	for x in probs.keys():
		probs[x] += prob_to_add
	
	
	# transform keys into arrays for further processing
	var new_probs: Dictionary
	for x in probs.keys():
		new_probs[[x]] = probs[x] 
	probs = new_probs
	
	
	if rules.explode.size()>0:
		probs = dh.blow_up(probs,rules.explode, explode_depth)
	
	if rules.compound.size()>0:
		probs = dh.blow_up(probs,rules.compound, explode_depth)
		probs = dh.collapse_probs(probs,true)
		pass
	
	
	# rolling multiple dice
	var original_probs = probs.duplicate()
	for i in range(rules.dice_count-1):
		probs = dh.merge_probs_keep_dice(probs,original_probs)
		pass
	
	# drop dice
	if rules.drop_dice>0:
		var post_drop:Dictionary
		if rules.drop_lowest:
			for k in probs.keys():
				var new_key = k.slice(rules.drop_dice,k.size()-1)
				dh.add_to_dict(post_drop,new_key,probs[k])
		else:
			for k in probs.keys():
				var new_key = k.slice(0,k.size()-1-rules.drop_dice)
				dh.add_to_dict(post_drop,new_key,probs[k])
		probs = post_drop.duplicate()

	
	# collapse results into single sums
	probs = dh.collapse_probs(probs, false)
	
	return probs

# calculate probabilities for composite rolls
static func comp_dice_probs(rules,explode_depth:int = 1)->Dictionary:
	var dh = preload('dice_helpers.gd')
	var al = preload('array_logic.gd')
	var final_result = {0:1.0}
	var error = false
	
	for i in range(rules.rules_array.size()):
		if(rules.rules_array[i].error):
			error = true
		var result = calc_probs(rules.rules_array[i],explode_depth)
		var new_keys = al.multiply_array(result.keys(),rules.signs[i])
		var new_values = result.values()
		result.clear()
		for j in range(new_keys.size()):
			result[int(new_keys[j])] = new_values[j]
		
		
		final_result = dh.merge_probs(final_result,result)
	
	if error:
		return {0:1.0}
	
	return final_result

# calculate probabilties of any roll, includes parsing and calculating
static func dice_probs(dice:String,explode_depth:int=3)->Dictionary:
	var rules = comp_dice_parser(dice)
	return comp_dice_probs(rules, explode_depth)


static func expected_value(probs:Dictionary)->float:
	var out = 0
	for k in probs.keys():
		out += probs[k]*float(k)
	return(out)


static func roll_from_probs(probs:Dictionary,rng:RandomNumberGenerator,n=1)->Array:
	var al = preload('array_logic.gd')
	return al.sample_weights(probs.keys(),probs.values(),n,rng)
	
