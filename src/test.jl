#push!(push!(LOAD_PATH, "."))
include("./Helpers.jl")
using .Helpers_test

@info "This should not invoke error"
k = rand(7)
a = combine(<, k)
@info "passed"
println()

k = ["qwe", println, 7]
try combine(<, k)
    @error "combine should invoke an error here"
    exit()
catch e
    @info "combine got through fine"
end
println()

@info "testing bad function"
k = [5, 4]
try combine(.|, k)
    @error "here should be an error"
    exit()
catch e
    @info "got through with $(e)"
end
println()

@info "testing ascending"
k = collect(1:1_000_000)
try combine(<, k)
    @info "got through"
catch e
    @info "got through with $(e)"
    exit()
end
println()

@info "testing equality"
k = ones(1_000_000)
try combine(==, k)
    @info "got through"
catch e
    @info "got through with $(e)"
    exit()
end
if !combine(==, k); @error "== does not work"; exit(); end
println()

@info "Testing keep fins"
if length(keep_fins(ones(1_000_000))) != 1_000_000
    @error "$(length(keep_fins(ones(1_000_000))))"
    exit()
end

if length(keep_fins(vcat(ones(1_000_000), [NaN, Inf]))) != 1_000_000
    @error "$(length(vcat(keep_fins(ones(1_000_000)), [NaN, Inf])))"
    exit()
end


@info "All tests passed succesfully"
