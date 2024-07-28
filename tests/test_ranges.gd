extends GutTest

var ranges = preload('res://addons/dice_syntax/int_range.gd')



func test_basics():
	var input:Array[Vector2i] = [Vector2i(1,5)]
	var r = ranges.new(input)
	assert_true(r.get_values() == [1,2,3,4,5])
	
	
	var j:int = 1
	for i in r:
		assert_true(i == j)
		j = j+1


func test_multirange():
	var input:Array[Vector2i] = [Vector2i(1,3),Vector2i(3,6),Vector2i(10,12)]
	var r = ranges.new(input)
	
	assert_true(r.ranges.size()== 2)
	assert_true(r.get_values() == [1,2,3,4,5,6,10,11,12])
	
	r.add_range(Vector2i(7,9))
	assert_true(r.ranges.size()== 1)
	assert_true(r.get_values() == [1,2,3,4,5,6,7,8,9,10,11,12])
	
	r.remove_range(Vector2i(3,9))
	assert_true(r.ranges.size()== 2)
	assert_true(r.get_values() == [1,2,10,11,12])
