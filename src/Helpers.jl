__precompile__()

module Helpers

using DelimitedFiles, Dates, Serialization

export readtsv, findone, hierarchical_order, remove_nans, only, parse_date, info, warn, read_vcf, VCF, save, load, get_name, combine, onedim, inturns

info(msg::String) = println(stderr, msg)
warn(msg::String) = println(stderr, "WARNING: $msg")

Base.findfirst(s::AbstractString, c::Char) = Base.findfirst(isequal(c), s)

mutable struct VCF
	sample::Vector{String}
	chromosome::Vector{String}
	position::Vector{Int32}
	ref_allele::Vector{String}
	alt_allele::Vector{String}
	gene::Vector{String}
	effect::Vector{String}
	alt::Matrix{Int32}
	total::Matrix{Int32}
	star::BitArray
	mapq::Matrix{Int32}
	baseq::Matrix{Int32}
	sidedness::Matrix{Int32}
end

function read_vcf(vcf::Union{IO,AbstractString})
	d = readdlm(vcf, '\t')

	# Delete comment rows (if any)
	n_comment_rows = 0
	while startswith(d[ n_comment_rows+1, 1], "#")
		n_comment_rows += 1
	end
	d = d[n_comment_rows+1:end, :]

	# Process header
	headers = d[1, :][:]; d = d[2:end, :];
	notes_col = findone(headers, "NOTES")
	samples = map(x -> "$x", headers[notes_col+1:end])
	S = length(samples)
	chromosome = String.(d[:, 1])
	position = convert(Vector{Int32}, d[:, 2])
	ref_allele = String.(d[:, 3])
	alt_allele = String.(d[:, 4])
	V = length(chromosome)

	gene_col = findone(headers, "GENE")
	gene = gene_col != nothing ? d[:, gene_col] : fill("", V)

	effect_col = findone(headers, "EFFECT")
	effect = effect_col != nothing ? d[:, effect_col] : fill("", V)

	alt = zeros(Int32, size(d, 1), S)
	total = zeros(Int32, size(d, 1), S)
	mapq = zeros(Int32, size(d, 1), S)
	baseq = zeros(Int32, size(d, 1), S)
	sidedness = zeros(Int32, size(d, 1), S)
	star = falses(size(d, 1), S)

	for r in 1:size(d, 1)
		for s in 1:S
			parts = split(d[r, notes_col + s], ':')
			if length(parts) <= 3
				# Call1
				star[r, s] = parts[end] == "*"
				alt[r, s] = parse(Int32, parts[1])
				total[r, s] = parse(Int32, parts[2])
			else
				# Call2
				star[r, s] = parts[end] == "*"
				alt[r, s] = parse(Int32, parts[1])
				total[r, s] = parse(Int32, parts[2])
				mapq[r, s] = parse(Int32, parts[3])
				baseq[r, s] = parse(Int32, parts[4])
				sidedness[r, s] = parse(Int32, parts[5])
			end
		end
	end
	return VCF(samples, chromosome, position, ref_allele, alt_allele, gene, effect, alt, total, star, mapq, baseq, sidedness)
end

function findone(predicate::Function, collection::AbstractVector)
	idx = 0
	for k in 1:length(collection)
		if predicate(collection[k])
			if idx > 0
				error("At least two elements $(collection[idx]) and $(collection[k]) fulfill the predicate.")
			end
			idx = k
		end
	end
	return idx == 0 ? nothing : idx
end

function findone(collection::AbstractVector, elem)
	idx = 0
	for k in 1:length(collection)
		if collection[k] == elem
			if idx > 0
				error("Element '$elem' is found in at least two positions $idx and $k.")
			end
			idx = k
		end
	end
	return idx == 0 ? nothing : idx
end

function only(predicate::Function, collection::AbstractVector)
	idx = findone(predicate, collection)
	if idx == 0; error("No elements fulfill the predicate."); end
	return collection[idx]
end

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
	#This should check that <fun> actually is an operator that can be used in this manner
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

function hierarchical_order(args...)
	for a in 2:length(args); @assert(length(args[a]) == length(args[1])); end
	function lt(a, b)
		for c in 1:length(args)
			if args[c][a] < args[c][b]; return true; end
			if args[c][a] > args[c][b]; return false; end
		end
		return false
	end
	return sortperm(1:length(args[1]), lt=lt)
end

function parse_date(x::AbstractString, century::Int)
	if x == "" || x == "."; return nothing; end
	if r"[0-9][0-9]-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-[0-9]+" in x
		d = try Date(x, "d-u-y") catch; error("Invalid date: $(x)") end
	elseif r"\d+/\d+/\d+" in x
		d = try Date(x, "m/d/y") catch; error("Invalid date: $(x)") end
	else
		error("Invalid date: $(x)")
	end
	return d + Dates.Year(century)
end

end
