__precompile__()
#TODO:
#-
module Helpers

using DelimitedFiles, Dates, Serialization

export only, parse_date, save, load, get_name, combine, onedim, inturns



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

"""
    combine(fun::Function, list::AbstractArray)

Put expression <fun> between each item of <list> and execute.


# Examples
```julia-repl
julia> combine(<, [1, 4, 15, 46]) #This creates 1<4<15<46 and executes it
true
```
"""
function combine(func::Function, list::AbstractArray)
	#This should check that <fun> actually is an operator that can be used in this manner.
	list = onedim(list)
	t = typeof(list[1])
	for k in list[2:end]
		if typeof(k) != t
			@error "All elements must be of same type"
		end
	end

	try func(list[1], list[2])

	catch
		@error "Your function can not be used with $(list[1]) and $(list[2])"
	end

	if length(list) == 2
		s = func(list[1], list[2])
	else
		s = func(list[1], list[2])
		for k in list[3:end]
			s = func(s, k)
		end
	end
	return s
end

remove_nans(arr::AbstractArray) = filter(x -> !isnan(x), arr)

# FIXME: This is helpful because broadcasting does not work for Pair or Regex
# objects in Julia 1.0. Can be dropped after those limitations are lifted.
Base.replace(strings::AbstractArray, pattern, sub) =
	map(s -> replace(s, pattern => sub), strings)
Base.replace(s::AbstractString, pattern, sub) = replace(s, pattern => sub)

# These allow in() and the in-operator to be used to test if a string
# contains a pattern (where pattern can be a string or regular expression).
Base.in(pattern::String, s::AbstractString) = occursin(pattern, s)
Base.in(r::Regex, s::AbstractString) = occursin(r, s)
#Base.broadcastable(r::Regex) = Ref(r)  # Built into Julia-1.1.0

readtsv(tsv_file::IO; text=false) = readdlm(tsv_file, '\t', text ? String : Any)
readtsv(cmd::Base.AbstractCmd; kwargs...) =
	open(f -> readtsv(f; kwargs...), cmd)
readtsv(tsv_path::AbstractString; kwargs...) =
	tsv_path == "-" ? readtsv(STDIN; kwargs...) : open(f -> readtsv(f; kwargs...), expanduser(tsv_path))
#=
function hierarchical_order(args...)
	for a in 2:length(args); @assert(length(args[a]) == length(args[1])); end
	function lt(a, b)
		for c in 1:length(args)
			if args[c][a] < args[c][b]; return true; end
			if args[c][a] > args[c][b]; return false; end
		end
	else
		start=string(list[1])
		for i in list[2:end]
			start = start * fun * string(i)
		end
	end
	return eval(Meta.parse(start))
end=#

end
