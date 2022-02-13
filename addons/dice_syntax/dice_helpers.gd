extends GDScript


static func merge_probs(prob1:Dictionary, prob2:Dictionary)-> Dictionary:
	var out:Dictionary
	for i in prob1.keys():
		for j in prob2.keys():
			add_to_dict(out,i+j,prob1[i]*prob2[j])
	return out

static func merge_probs_keep_dice(prob1:Dictionary, prob2:Dictionary)->Dictionary:
	var al = preload('array_logic.gd')
	var out:Dictionary
	for i in prob1.keys():
		for j in prob2.keys():
			var new_key:Array = al.append(i,j)
			out[new_key] = prob1[i]*prob2[j]
	return out

static func add_to_dict(dict:Dictionary,key,value):
	if dict.has(key):
		dict[key] += value
	else:
		dict[key] = value


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
