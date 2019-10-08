__precompile__()

module Helpers

using DelimitedFiles, Dates, Serialization

export readtsv, hierarchical_order, only, parse_date, save, load, get_name, combine, onedim, inturns



function save(filename::String, data)
	open(filename, "w") do f
		serialize(f, data)
	end
end

function get_name(path::String)
	t = split(path, "/")[end]
	t = split(t, ".")
	pop!(t)
	if length(t) == 1
		return t[1]
	else
		u = broadcast(*, t[1:end-1], ".")
		return join(u, t[end])
	end
end

function load(filename::String)
	return open(deserialize, filename, "r")
end

"""
    onedim(v::AbstractArray)

Check if array has information in only one dimension and return one dimensional version of the same array,
otherwise, raise an error.


# Examples
```julia-repl
julia> onedim(rand(1, 4, 1))
4-element Array{Float64,1}:
 0.8415258048874592
 0.787432396149214
 0.8292044884383356
 0.041755082648925024

```
"""
function onedim(v::AbstractArray)
	s = size(v)
	if length(s) == 1; return v; end
	isz = [i == 0 for i in s]
	if any(isz)
		@warn "There is a dimension with length zero"
	end
	goods = [i > 1 for i in s]
	if sum(goods) > 1
		@error "Array has information in more than one dimension"
	else
		return vec(v)
	end
end

function inturns(a::AbstractArray, b::AbstractArray)
	@assert length(a) == length(b) "Vectors must be of same size"
	a = onedim(a); b = onedim(b)
	if eltype(a) == eltype(b)
		out = Array{eltype(a)}(undef, 2*length(a))
	else
		out = Array{Any}(undef, 2*length(a))
	end
	evens = collect(1:length(a)) .* 2
	odds = evens .- 1
	out[odds] .= a;out[evens] .= b
	return out
end

function combine(fun::String, list::AbstractArray)
	#This should check that <fun> actually is an operator that can be used in this manner.
	println("0.1.0-beta")
	list = onedim(list)
	l = length(list)
	if l == 2
		start=string(list[1]) * fun * string(list[2])
		return eval(Meta.parse(start))
	elseif l == 1
		@error "Vector must have at least two objects!"
	end
	start=string(list[1])
	for i in list[2:end]
		start = start * fun * string(i)
	end
	return eval(Meta.parse(start))
end

end
