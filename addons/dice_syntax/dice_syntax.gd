extends GDScript
class_name dice_syntax



static func _dice_parser2(dice:String)->Dictionary:
	var sm = preload('string_manip.gd')
	var sdf = preload('single_dice_funs.gd')
	var dh = preload('dice_helpers.gd')
	
	var dice_regex = '[0-9]*d[0-9]*[dksro!<>0-9]*'
	
	var dice_components = sm.str_extract_all(dice,dice_regex)
	var dice_expression_compoments = sm.str_split(dice,dice_regex)
	var dice_expression = ''
	for i in range(dice_expression_compoments.size()):
		dice_expression += dice_expression_compoments[i]
		if i < dice_components.size():
			dice_expression += dh.int_to_letter(i)
	
	var rules_array = []
	for x in dice_components:
		var rr = sdf.base_dice_parser(x)
		rules_array.append(rr)
	
	return {'rules_array':rules_array,'dice_expression':dice_expression}

# parsing composite rolls (with +,- in the string)
static func dice_parser(dice:String)->Dictionary:
	var sm = preload('string_manip.gd')
	var sdf = preload('single_dice_funs.gd')
	
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
		var rr = sdf.base_dice_parser(x)
		rules_array.append(rr)
	
	return {'rules_array': rules_array, 'signs':component_signs}

# rolling any dice, includes parsing and rolling
static func roll(dice:String,rng:RandomNumberGenerator)->Dictionary:
	var rules = dice_parser(dice)
	return roll_parsed(rules,rng)


# roll composite rolls from parsed rules
static func roll_parsed(rules:Dictionary, rng:RandomNumberGenerator)->Dictionary:
	var sdf = preload('single_dice_funs.gd')
	var results:Array
	var error = false
	var msg = []
	
	for i in range(rules.rules_array.size()):
		var result = sdf.base_rule_roller(rules.rules_array[i],rng)
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

# calculate probabilities for composite rolls
static func parsed_dice_probs(rules,explode_depth:int = 1)->Dictionary:
	var dh = preload('dice_helpers.gd')
	var al = preload('array_logic.gd')
	var sdf = preload('single_dice_funs.gd')
	var final_result = {0:1.0}
	var error = false
	
	for i in range(rules.rules_array.size()):
		if(rules.rules_array[i].error):
			error = true
		var result = sdf.base_calc_rule_probs(rules.rules_array[i],explode_depth)
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
	var rules = dice_parser(dice)
	return parsed_dice_probs(rules, explode_depth)


static func expected_value(probs:Dictionary)->float:
	var out = 0
	for k in probs.keys():
		out += probs[k]*float(k)
	return(out)


static func roll_from_probs(probs:Dictionary,rng:RandomNumberGenerator,n=1)->Array:
	var al = preload('array_logic.gd')
	return al.sample_weights(probs.keys(),probs.values(),n,rng)
	
