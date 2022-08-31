extends GDScript
class_name dice_syntax



static func dice_parser(dice:String)->Dictionary:
	var sm = preload('string_manip.gd')
	var sdf = preload('single_dice_funs.gd')
	var dh = preload('dice_helpers.gd')
	var error = false
	var msg = []
	var dice_regex = '[0-9]*d[0-9]+[dksro!<>0-9lh]*'
	
	var dice_components = sm.str_extract_all(dice,dice_regex)
	var dice_expression_compoments = sm.str_split(dice,dice_regex)
	var dice_expression = ''
	var dice_letters = []
	for i in range(dice_expression_compoments.size()):
		dice_expression += dice_expression_compoments[i]
		if i < dice_components.size():
			dice_letters.append(dh.int_to_letter(i))
			dice_expression += dice_letters[i]
	var rules_array = []
	for x in dice_components:
		var rr = sdf.base_dice_parser(x)
		if rr.error:
			error = true
			msg.append_array(rr.msg)
	
		rules_array.append(rr)
	
	var expression = Expression.new()
	expression.parse(dice_expression,dice_letters)
	
	# test execution to see if it's valid
	var test_out = []
	for i in range(dice_letters.size()):
		test_out.append(1.0)
	
	expression.execute(test_out)
	if expression.has_execute_failed() or expression.get_error_text()!='':
		error = true
		msg.append('Expression fails to execute')
	
	return {
		'rules_array':rules_array,
		'dice_expression':expression,
		'expression_string':dice_expression,
		'error':error,
		'msg':msg}

static func roll_parsed(rules:Dictionary, rng:RandomNumberGenerator)->Dictionary:
	var sdf = preload('single_dice_funs.gd')
	var results:Array
	var roll_sums:Array
	var error = rules.error
	var msg = rules.msg
	
	for i in range(rules.rules_array.size()):
		var result = sdf.base_rule_roller(rules.rules_array[i],rng)
		results.append(result)
		roll_sums.append(result.result)
	
	var sum = rules.dice_expression.execute(roll_sums)
	
	if error:
		sum = 0
	
	return {'result':sum, 'rolls':results,'error': error, 'msg': msg}

static func roll(dice:String, rng:RandomNumberGenerator)->Dictionary:
	var rules = dice_parser(dice)
	return roll_parsed(rules,rng)

static func parsed_dice_probs(rules, explode_depth:int=1)->Dictionary:
	var dh = preload('dice_helpers.gd')
	var al = preload('array_logic.gd')
	var sdf = preload('single_dice_funs.gd')
	var final_result = {}
	var error = rules.error
	for i in range(rules.rules_array.size()):
		var result = sdf.base_calc_rule_probs(rules.rules_array[i],explode_depth)
		if i == 0: # if it's the first iteration populate the dictionary
			for x in result.keys():
				final_result[[x]] = result[x]
		else:
			final_result = dh.merge_probs_keep_dice(final_result,result,false)
	
	if error:
		return {0:1.0}
	
	var processed_results = {}
	for x in final_result.keys():
		var new_key = rules.dice_expression.execute(x)
		dh.add_to_dict(processed_results,new_key,final_result[x])
	
	if final_result.size()==0:
		processed_results[float(rules.dice_expression.execute())] = 1
	
	return processed_results

static func dice_probs(dice:String,explode_depth:int=1)->Dictionary:
	var rules = dice_parser(dice)
	return parsed_dice_probs(rules,explode_depth)


static func expected_value(probs:Dictionary)->float:
	var out = 0
	for k in probs.keys():
		out += probs[k]*float(k)
	return(out)

static func standard_deviation(probs:Dictionary)->float:
	var out = 0
	var mean = expected_value(probs)
	for k in probs.keys():
		out += pow(float(k)-mean,2)*probs[k]
	return pow(out,0.5)

static func roll_from_probs(probs:Dictionary,rng:RandomNumberGenerator,n=1)->Array:
	var al = preload('array_logic.gd')
	return al.sample_weights(probs.keys(),probs.values(),n,rng)
	
