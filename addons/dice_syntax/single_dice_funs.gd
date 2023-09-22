extends GDScript
# internal functions that parse single dice rolls


# basic dice parser for single rolls

static func base_dice_parser2(dice_string:String,regex:RegEx = RegEx.new())->Dictionary:
	var sm = preload('string_manip.gd')
	var al = preload('array_logic.gd')
	var dh = preload('dice_helpers.gd')
	var rolling_rules: Dictionary = {
	'error': false, 
	'msg': [],
	'compound':[],
	'explode':[],
	'reroll_once': [],
	'reroll': [],
	'possible_dice': [],
	'drop_dice':0,
	'drop_lowest':true,
	'drop_keep_specific': [],
	'drop_specific': true,
	'dice_side':0,
	'dice_count':0,
	'sort':false}
	var valid_tokens = '[dksr!<=>hl]'
	dice_string = dice_string.to_lower()
	var used_tokens:PackedInt32Array
	
	# get the dice count or default to 1 if we just start with d.
	regex.compile('^[0-9]*?(?=d)')
	var result = sm.str_extract_rg(dice_string,regex)
	dh.dice_error(result!=null,'Malformed dice string',rolling_rules)
	if result == '':
		rolling_rules['dice_count'] = 1
	elif result == null:
		return rolling_rules
	elif result.is_valid_int():
		rolling_rules['dice_count'] = result.to_int()
	
	# tokenize the rest of the rolling rules. a token character, followed by the
	# next valid token character or end of string. while processing, remove
	# all processed tokens and check for anything leftower at the end
	regex.compile(valid_tokens + '.*?((?=' + valid_tokens + ')|$)')
	var tokens = sm.str_extract_all_rg(dice_string,regex)
	# print(tokens)
	regex.compile('(?<=d)[0-9]+$')
	var dice_side = sm.str_extract_rg(tokens[0],regex)
	dh.dice_error(dice_side != null, "Malformed dice string: Unable to detect dice sides",rolling_rules)
	if dice_side!=null:
		rolling_rules['dice_side'] = dice_side.to_int()
	else:
		return rolling_rules
	# remove dice side token to make sure it's not confused with the drop rule
	tokens.remove_at(0)
	print(tokens)
	# check for sort rule, if s exists, sort the results
	# don't think this is useful. consider removing
	var sort_rule = tokens.find('s')
	rolling_rules['sort'] = sort_rule != -1
	if sort_rule != -1:
		used_tokens.append(sort_rule)
	# tokens.remove_at(sort_rule)
	
	# check for drop modifiers
	regex.compile('^(h|l)[0-9]+$')
	var drop_modifiers:Array =  sm.strs_detect_rg(tokens,regex)
	print(drop_modifiers)
	# check for range specifications
	regex.compile("^[<=>][0-9]+$")
	var ranges =  sm.strs_detect_rg(tokens,regex)
	print(ranges)
	# check for drop rules
	regex.compile('^(d|k)[0-9]*$')
	var drop_rules:Array = sm.strs_detect_rg(tokens,regex)
	print(drop_rules)
		
	for i in drop_rules:
		regex.compile('[0-9]+$')
		
		# look for the drop count in the current token
		var drop_count = sm.str_extract_rg(tokens[i], regex)
		var drop_rule:String = tokens[i]
		# if drop count isn't found
		if drop_count == null and i+1 in drop_modifiers:
			# next token is a drop modifier, it must come with a drop count
			dh.dice_error(rolling_rules['drop_dice'] != 0, "Malformed dice string: Can't include more than one drop count",rolling_rules)
			drop_count = sm.str_extract_rg(tokens[i+1],regex)
			drop_rule = tokens[i] + tokens[i+1]
			used_tokens.append(i+1)
		elif drop_count == null and i+1 in ranges:
			# next token is a range. drop specific results
			var drop_range = dh.range_determine(tokens[i+1],rolling_rules['dice_side'],regex,rolling_rules)
			match drop_rule.substr(0,1):
				"d": 
					dh.dice_error(rolling_rules['drop_specific'],"Malformed dice string: Can't specify both dropping and keeping specific dice",rolling_rules)
					rolling_rules['drop_specific'] = true
					pass
				'k':
					dh.dice_error(!rolling_rules['drop_specific'] and rolling_rules['drop_keep_specific'].size()>0,"Malformed dice string: Can't specify both dropping and keeping specific dice",rolling_rules)
					rolling_rules['drop_specific'] = false
					pass
			rolling_rules['drop_keep_specific'].append_array(drop_range)
		
		
	
	
	return rolling_rules

static func base_dice_parser(dice_string:String,regex:RegEx = RegEx.new())->Dictionary:
	var sm = preload('string_manip.gd')
	var al = preload('array_logic.gd')
	var dh = preload('dice_helpers.gd')
	
	var rolling_rules: Dictionary = {
	'error': false, 
	'msg': [],
	'compound':[],
	'explode':[],
	'reroll_once': [],
	'reroll': [],
	'possible_dice': [],
	'drop_dice':0,
	'drop_lowest':true,
	'dice_side':0,
	'dice_count':0,
	'sort':false}
	# var valid_tokens = '[dksr!]'
	var valid_tokens = '[dksr!<=>hl]'
	dice_string = dice_string.to_lower()
	var used_tokens:PackedInt32Array
	
	# get the dice count or default to 1 if we just start with d.
	regex.compile('^[0-9]*?(?=d)')
	var result = sm.str_extract_rg(dice_string,regex)
	dh.dice_error(result!=null,'Malformed dice string',rolling_rules)
	if result == '':
		rolling_rules['dice_count'] = 1
	elif result == null:
		return rolling_rules
	elif result.is_valid_int():
		rolling_rules['dice_count'] = result.to_int()
	
	# tokenize the rest of the rolling rules. a token character, followed by the
	# next valid token character or end of string. while processing, remove
	# all processed tokens and check for anything leftower at the end
	
	regex.compile(valid_tokens + '.*?((?=' + valid_tokens + ')|$)')
	var tokens = sm.str_extract_all_rg(dice_string,regex)
	# print(tokens)
	regex.compile('(?<=d)[0-9]+$')
	var dice_side = sm.str_extract_rg(tokens[0],regex)
	dh.dice_error(dice_side != null, "Malformed dice string: Unable to detect dice sides",rolling_rules)
	if dice_side!=null:
		rolling_rules['dice_side'] = dice_side.to_int()
	else:
		return rolling_rules
	# remove dice side token to make sure it's not confused with the drop rule
	tokens.remove_at(0)
	
	# check for sort rule, if s exists, sort the results
	var sort_rule = tokens.find('s')
	rolling_rules['sort'] = sort_rule != -1
	if sort_rule != -1:
		used_tokens.append(sort_rule)
		# tokens.remove_at(sort_rule)

	
	# check for drop rules, there can only be one 
	regex.compile('^(d|k)(h|l)?[0-9]+$')
	var drop_rules = sm.strs_detect_rg(tokens,regex)
	dh.dice_error(drop_rules.size() <= 1,"Malformed dice string: Can't include more than one drop rule",rolling_rules)
	if drop_rules.size() == 0:
		rolling_rules['drop_dice'] = 0
		rolling_rules['drop_lowest'] = true
	else:
		regex.compile('[0-9]+$')
		var drop_count = sm.str_extract_rg(tokens[drop_rules[0]], regex)
		dh.dice_error(drop_count!= null, 'Malformed dice string: No drop count provided',rolling_rules)
		var drop_rule = tokens[drop_rules[0]]
		match drop_rule.substr(0,1):
			'd':
				rolling_rules['drop_dice'] = drop_count.to_int()
			'k':
				rolling_rules['drop_dice'] = rolling_rules['dice_count']-drop_count.to_int()
		regex.compile('dh')
		var dl1 = sm.str_detect_rg(drop_rule,regex)
		regex.compile('kl')
		var dl2 = sm.str_detect_rg(drop_rule,regex)
		rolling_rules['drop_lowest'] = !(dl1 or dl2)
		used_tokens.append(drop_rules[0])
	# reroll rules
	regex.compile('r(?!o)')
	var reroll_rules = sm.strs_detect_rg(tokens,regex)
	var reroll:Array = []
	for i in reroll_rules:
		reroll.append_array(dh.range_determine(tokens[i], rolling_rules['dice_side'],regex,rolling_rules))
	var dicePossibilities = range(1,rolling_rules['dice_side']+1)
	# dice_error(!al.all(al.array_in_array(dicePossibilities,reroll)),'Malformed dice string: rerolling all results',rolling_rules)
	rolling_rules['reroll'] = reroll
	# remove reroll rules
	reroll_rules.reverse()
	for i in reroll_rules:
		used_tokens.append(i)
	
	# reroll once
	regex.compile('ro')
	reroll_rules = sm.strs_detect_rg(tokens,regex)
	var reroll_once:Array = []
	for i in reroll_rules:
		var to_reroll = dh.range_determine(tokens[i], rolling_rules['dice_side'],regex,rolling_rules)
		dh.dice_error(al.which_in_array(to_reroll,reroll_once).size()==0,"Malformed dice string: can't reroll the same number once more than once.",rolling_rules)
		reroll_once.append_array(to_reroll)
	rolling_rules['reroll_once'] = reroll_once
	
	reroll_rules.reverse()
	for i in reroll_rules:
		used_tokens.append(i)
	
	
	# new explode rules
	regex.compile('!')
	var explode_rules = sm.strs_detect_rg(tokens,regex)
	var explode:Array = []
	var compound: Array = []
	var compound_flag:bool = false
	for i in explode_rules:
		if i != INF:
			if tokens[i] == '!' and i+1 in explode_rules:
				compound_flag = true
			elif not compound_flag:
				explode.append_array(dh.range_determine(tokens[i], rolling_rules['dice_side'],regex,rolling_rules,rolling_rules['dice_side']))
			elif compound_flag:
				compound_flag = false
				compound.append_array(dh.range_determine(tokens[i], rolling_rules['dice_side'],regex,rolling_rules,rolling_rules['dice_side']))
	rolling_rules['explode'] = explode
	rolling_rules['compound'] = compound
	explode_rules.reverse()
	for i in explode_rules:
		used_tokens.append(i)
	
	used_tokens.sort()
	used_tokens.reverse()
	#print(used_tokens)
	for i in used_tokens:
		if i>= tokens.size():
			dh.dice_error(tokens.size()==0, 'Malformed dice string: Ambigious tokens',rolling_rules)
		else:
			tokens.remove_at(i)
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
static func base_rule_roller(rolling_rules:Dictionary,rng:RandomNumberGenerator = RandomNumberGenerator.new())->Dictionary:
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
			ordered_dice.reverse()
		for i in range(0,rolling_rules.drop_dice):
			drop.append(ordered_dice[i])
		var new_dice = []
		var drop_copy = drop.duplicate()
		for x in dice:
			if not x in drop_copy:
				new_dice.append(x)
			else:
				drop_copy.remove_at(drop_copy.find(x))
		dice = new_dice
		out['drop'] = drop
		
	
	
	out['dice'] = dice
	out['result'] = al.sum(dice)
	
	
	return out


# calucate probabilities of a single roll
static func base_calc_rule_probs(rules:Dictionary,explode_depth:int = 3)->Dictionary:
	var al = preload('array_logic.gd')
	var dh = preload('dice_helpers.gd')
	
	if rules.error:
		var probs = {0.0:1.0}
		return probs
	
	
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
				var new_key = k.slice(rules.drop_dice,k.size())
				dh.add_to_dict(post_drop,new_key,probs[k])
		else:
			for k in probs.keys():
				var new_key = k.slice(0,k.size()-rules.drop_dice)
				dh.add_to_dict(post_drop,new_key,probs[k])
		probs = post_drop.duplicate()

	
	# collapse results into single sums
	probs = dh.collapse_probs(probs, false)
	
	return probs
