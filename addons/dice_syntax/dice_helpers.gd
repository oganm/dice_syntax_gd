extends GDScript


# keys are dice totals
static func merge_probs(prob1:Dictionary, prob2:Dictionary)-> Dictionary:
	var out:Dictionary
	for i in prob1.keys():
		for j in prob2.keys():
			add_to_dict(out,i+j,prob1[i]*prob2[j])
	return out

# keys are individual dice
static func merge_probs_keep_dice(prob1:Dictionary, prob2:Dictionary)->Dictionary:
	var al = preload('array_logic.gd')
	var out:Dictionary
	for i in prob1.keys():
		for j in prob2.keys():
			var new_key:Array = al.append(i,j)
			new_key.sort()
			add_to_dict(out,new_key,prob1[i]*prob2[j])
			
			# out[new_key] = prob1[i]*prob2[j]
	return out

# if element exists in dictionary, add to the existing value, if not create element
static func add_to_dict(dict:Dictionary,key,value):
	if dict.has(key):
		dict[key] += value
	else:
		dict[key] = value

# calculations for exploding and compounding dice
static func blow_up(probs:Dictionary,blow_dice:Array, depth = 3)-> Dictionary:
	var base_probs = probs.duplicate()
	for d in range(depth-1):
		var blown_up:Dictionary
		for k in probs.keys():
			if k.back() in blow_dice:
				for i in base_probs.keys():
					var new_key = k.duplicate()
					new_key.append_array(i)
					var new_value = base_probs[i]*probs[k]
					blown_up[new_key] = new_value
			else:
				blown_up[k] = probs[k]
		probs = blown_up
	
	return probs

static func collapse_probs(probs:Dictionary, array_keys:bool = true)-> Dictionary:
	var al = preload('array_logic.gd')
	var out: Dictionary
	var temp: Dictionary
	for k in probs.keys():
		var new_key = al.sum(k)
		add_to_dict(temp,new_key,probs[k])
	
	# if returned dictionary should have arrays as keys, re-transform
	if array_keys:
		for k in temp.keys():
			out[[k]] = temp[k] 
	else:
		out = temp
	
	return out

# add error information to the output if something goes wrong.
# dictionaries are passed by reference
static func dice_error(condition:bool,message:String,rolling_rules:Dictionary):
	if(!condition):
		push_error(message)
		rolling_rules['error'] = true
		rolling_rules['msg'].append(message)


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
