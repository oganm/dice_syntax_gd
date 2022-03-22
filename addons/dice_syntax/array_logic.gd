extends GDScript
# functions meant to deal with numeric arrays


# check if all is true in an array
static func all(array:Array)->bool:
	var out = true
	for x in array:
		if !x:
			out = false
	return out

# true if any is true in an array
static func any(array:Array)->bool:
	var out = false
	for x in array:
		if x:
			out = true
	return out

# sum of trues in an array
static func sum_bool(array:Array)->int:
	var out:int = 0
	for x in array:
		if x:
			out +=1
	return out

# sum of numbers in the array
static func sum(array:Array)->float:
	var out:float = 0
	for x in array:
		out += x
	return(out)

# get mean of array
static func mean(array:Array)->float:
	var out:float = 0
	return float(sum(array))/array.size()

# multiply array elements by factor
static func multiply_array(array:Array,mult:float)->Array:
	var out:Array
	for x in array:
		out.append(x*mult)
	return out

# add a number to array elements
static func add_to_array(array:Array,add:float)->Array:
	var out:Array
	for x in array:
		out.append(x+add)
	return out

# check if elements of an array are in another array
static func array_in_array(array:Array,target:Array)->Array:
	var out:Array
	for i in range(array.size()):
		out.append(target.find(array[i]) != -1)
	return out

# return which indexes contain the elemnts of an array
static func which_in_array(array:Array,target:Array)->Array:
	var out:Array
	for i in range(array.size()):
		if target.find(array[i]) != -1:
			out.append(i)
	return out

# return true indexes in an array
static func which(array:Array)->Array:
	var out:Array
	for i in range(array.size()):
		if array[i]:
			out.append(i)
	return out

static func order(array:Array)->Array:
	var out:Array
	var sorted = array.duplicate()
	sorted.sort()
	for x in array:
		out.append(sorted.find(x))
	return out

static func array_compare(array:Array,reference:float,equal:bool = false,less:bool = false, greater:bool = false)->Array:
	var out:Array
	
	for x in array:
		var result = false
		if equal:
			if x == reference:
				result = true
		if less:
			if x < reference:
				result = true
		if greater:
			if x > reference:
				result = true
		out.append(result)
				
	
	return out

static func array_not(array:Array)->Array:
	var out:Array
	for x in array:
		out.append(not x)
	return out

static func array_subset(array:Array, indices:Array)->Array:
	var out:Array
	for i in indices:
		out.append(array[i])
	return out

static func sample(array:Array,n:int,rng:RandomNumberGenerator, replace:bool = true)->Array:
	var out:Array = []
	if not replace and n>array.size():
		push_error('Cannot take a sample larger than the population when replace = false')
		return out
	for i in range(n):
		var samp = rng.randi_range(0,array.size()-1)
		out.append(array[samp])
		if not replace:
			array.remove_at(samp)
		
	
	
	return out

# append single elements/arrays with each other
static func append(e1,e2)->Array:
	var out = []
	if typeof(e1)==TYPE_ARRAY:
		out.append_array(e1)
	else:
		out.append(e1)
	if typeof(e2)==TYPE_ARRAY:
		out.append_array(e2)
	else:
		out.append(e2)
	return out

# sample from an array using given weights
static func sample_weights(array:Array, weights: Array, n:int, rng:RandomNumberGenerator, replace:bool = true)->Array:
	var out:Array = []
	var sm = sum(weights)
	weights[0] = float(weights[0])/float(sm)
	for i in range(1,weights.size()):
		weights[i] = float(weights[i])/float(sm) + weights[i-1]
	
	
	for i in range(n):
		var rand = rng.randf()
		var curr_index = 0
		while rand > weights[curr_index]:
			curr_index += 1
		out.append(array[curr_index])
	
	return out

static func tests():
	print('testing logic functions')
	var true_true = [true,true]
	var true_false = [true,false]
	var false_false = [false,false]
	
	assert(sum_bool(true_true) == 2,"bad sum")
	assert(sum_bool(true_false) == 1,"bad sum")
	assert(sum_bool(false_false) == 0, 'bad sum')
	assert(any(true_false),'bad any')
	assert(all(true_true),'bad all')
	assert(!all(true_false),'bad all')
	assert(any(array_in_array(true_false,true_true)),'bad array_in_array')
	assert(!all(array_in_array(true_false,true_true)),'bad array_in_array')
