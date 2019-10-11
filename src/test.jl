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
try combine(||, k)
    @error "here should be an error"
    exit()
catch e
    @info "got through with $(e)"
end
println()

@info "All tests passed succesfully"
