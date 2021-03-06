using RCall
using Base.Test,DataArrays,DataFrames

lsv = reval("ls()")
@test length(lsv) == 0
@test isa(lsv, RCall.StrSxp)

lsd = reval("ls(\"package:datasets\")")
@test isa(lsv, RCall.StrSxp)
@test length(lsd) > 50
@test rcopy(lsd[2]) == "airmiles"

v110 = DataArray(reval("x <- 1:10"))
@test isa(v110,DataVector)
@test eltype(v110) == Cint

attenu = DataFrame(:attenu)
@test isa(attenu,DataFrame)
@test size(attenu) == (182,5)

dist = attenu[:dist]
@test isa(dist,DataArray{Float64})

psexp = sexp("p")
@test isa(psexp,RCall.StrSxp)
@test length(psexp) == 1
@test rcopy(psexp[1]) == "p"

pqsexp = sexp(["p","q"])
@test isa(pqsexp,RCall.StrSxp)
@test length(pqsexp) == 2
@test rcopy(pqsexp[1]) == "p"

@test DataArray(reval("c(NA,TRUE)")).na == @data([NA,true]).na
@test DataArray(reval("c(NA,1)")).na == @data([NA,1.0]).na
@test DataArray(reval("c(NA,1+0i)")).na == @data([NA,1.0+0.0*im]).na
@test DataArray(reval("c(NA,1L)")).na == @data([NA,one(Int32)]).na
@test DataArray(reval("c(NA,'NA')")).na == @data([NA,"NA"]).na
@test_throws ErrorException DataArray(reval("as.factor(c('a','a','c'))"))
@test PooledDataArray(reval("as.factor(c('a','a','c'))")).pool == ["a","c"]

@test DataArray(sexp(@data([NA,true]))).na == @data([NA,true]).na
@test DataArray(sexp(@data([NA,1]))).na == @data([NA,1]).na
@test DataArray(sexp(@data([NA,1.]))).na == @data([NA,1.]).na
@test DataArray(sexp(@data([NA,1.+0*im]))).na == @data([NA,1.+0*im]).na
@test DataArray(sexp(@data([NA,NA,"a","b"]))).na == @data([NA,NA,"a","b"]).na
pda = PooledDataArray(repeat(["a", "b"], inner = [5]))
@test PooledDataArray(sexp(pda)).refs == repeat([1,2], inner = [5])

@test rcopy(rcall(:dim,sexp(attenu))) == [182,5]

langsexp = RCall.lang(:solve, sexp([1 2; 0 4]))
@test length(langsexp) == 2
@test rcopy(reval(langsexp)) == [1 -0.5; 0 0.25]
@test rcopy(langsexp[1]) == :solve
langsexp[1] = sexp(:det)
langsexp[2] = sexp([1 2; 0 0])
@test rcopy(reval(langsexp))[1] == 0

globalEnv[:x] = sexp([1,2,3])
globalEnv[:y] = sexp([4,5,6])
@test rcopy(rcall(symbol("+"),:x,:y)) == [5,7,9]

@rimport MASS as mass
@test round(rcopy(rcall(mass.ginv, sexp([1 2; 0 4]))),5) == [1 -0.5; 0 0.25]

# graphics
f = tempname()
rcall(:png,f)
rcall(:plot,1:10)
rcall(symbol("dev.off"))
@test isfile(f)
