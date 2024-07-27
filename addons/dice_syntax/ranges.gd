extends Resource

class integer_range:
## Stores integer ranges
	var ranges:Array[Vector2i]
	
	## iter vars
	var i:int = 0
	var j:int = 0
	var iter_range:Array
	var iter_current:int
	
	func _init(ranges:Array[Vector2i]):
		self.ranges = normalize_ranges(ranges)
	
	func _iter_init(arg):
		i=0
		j=0
		if ranges.size()>0:
			iter_range = range(ranges[i][0],ranges[i][1]+1)
			iter_current = iter_range[j]
			return true
		else:
			return false

	func _iter_next(arg):
		j = j+1
		if(iter_range.size()<=j):
			j = 0
			i = i+1
			if(ranges.size()<=i):
				return false
			else:
				iter_range =  range(ranges[i][0],ranges[i][1]+1)
		iter_current = iter_range[j]
		return true

	func _iter_get(arg):
		return iter_current
	
	
	func get_values():
		var out:Array
		for x in ranges:
			out.append_array(range(x[0],x[1]+1))
		return out
		
	
		
	func add_range(r:Vector2i):
		r = check_range(r)
		
		# this bit is a bit inefficient but should be good enough for dice.
		# ideally we would identify where a merge could happen then check against
		# its neighbours
		self.ranges.append(r)
		self.ranges = normalize_ranges(ranges)
		
	
	func remove_range(r:Vector2i):
		pass
		#r = check_range(r)
		#
		#var remove_list:Array[int]
		#
		#for x in self.ranges:
			#if r[1]<x[0]:
				#break
			#elif r[1]>x[0] and :
				
			
	
	static func normalize_ranges(ranges:Array[Vector2i])->Array[Vector2i]:
		var out:Array[Vector2i]
		
		ranges.sort()
		out.append(check_range(ranges[0]))
		
		for current_range in ranges.slice(1):
			var last_elem:Vector2i = check_range(out[out.size()-1])
			if current_range[0]<=last_elem[1]+1:
				var new_elem:Vector2i = Vector2i(last_elem[0],max(last_elem[1],current_range[1]))
				out[out.size()-1] = new_elem
			else:
				out.append(current_range)
		
		return out
	
	static func check_range(r:Vector2i)->Vector2i:
		if r[0]>r[1]:
			r = Vector2i(r[1],r[0])
		return r
