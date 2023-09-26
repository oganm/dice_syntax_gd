extends GDScript


static func str_extract(string:String,pattern:String,regex:RegEx = RegEx.new()):
	regex.compile(pattern)
	return str_extract_rg(string,regex)


static func str_extract_rg(string:String,regex:RegEx):
	var result:RegExMatch = regex.search(string)
	if result == null:
		return null
	else:
		return  result.get_string()

static func str_extract_all(string:String,pattern:String,regex:RegEx = RegEx.new())-> PackedStringArray:
	regex.compile(pattern)
	return str_extract_all_rg(string,regex)


static func str_extract_all_rg(string:String,regex:RegEx) -> PackedStringArray:
	var out:PackedStringArray
	for x in regex.search_all(string):
		out.append(x.get_string())
	return(out)


static func str_detect(string:String, pattern:String,regex:RegEx = RegEx.new()) -> bool:
	regex.compile(pattern)
	return str_detect_rg(string,regex)


static func str_detect_rg(string:String, regex:RegEx)-> bool:
	var out:bool
	var result:RegExMatch = regex.search(string)
	return result != null


static func str_split(string:String, pattern:String,regex:RegEx = RegEx.new())-> PackedStringArray:
	regex.compile(pattern) # Negated whitespace character class.
	return str_split_rg(string,regex)

static func str_split_rg(string:String, regex:RegEx) -> PackedStringArray:
	var out:PackedStringArray = []
	var start = 0
	var end = 0
	var next = 0
	for result in regex.search_all(string):
		end = result.get_start()
		next = result.get_end()
		out.append(string.substr(start,end-start))
		start = next
	out.append(string.substr(start,-1))
	
	return out


# vectorized over an array of strings to return indexes of matching
static func strs_detect(strings:Array,pattern:String,regex:RegEx = RegEx.new()) -> PackedInt64Array:
	regex.compile(pattern)
	return strs_detect_rg(strings,regex)

static func strs_detect_rg(strings:Array,regex:RegEx) -> PackedInt64Array:
	var out:PackedInt64Array
	for i in range(strings.size()):
		if str_detect_rg(strings[i],regex):
			out.append(i)
	
	return out
