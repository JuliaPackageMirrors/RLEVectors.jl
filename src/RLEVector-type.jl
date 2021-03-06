### RLEVectors Type

"""
# RLEVectors
`RLEVectors` is an alternate implementation of the Rle type from Bioconductor's
IRanges package by H. Pages, P. Aboyoun and M. Lawrence. RLEVectors represent a
vector with repeated values as the ordered set of values and repeat extents. In
the field of genomics, data of various types measured across the ~3 billion
letters in the human genome can often be represented in a few thousand runs.
It is useful to know the bounds of genome regions covered by these runs, the
values associated with these runs, and to be able to perform various
mathematical operations on these values.

`RLEVectors` can be created from a single vector or a vector of values and a
vector of run ends. In either case runs of values or zero length runs will
be compressed out. RLEVectors can be expanded to a full vector like a
`Range` with `collect`.

### Examples
 * `x = RLEVector([1,1,2,2,3,3,4,4,4])`
 * `x = RLEVector([4,5,6],[3,6,9])`

"""
## Types and constructors

type RLEVector{T1,T2 <: Integer} <: AbstractArray{T1, 1}
  runvalues::Vector{T1}
  runends::Vector{T2}
  function RLEVector(runvalues, runends)
    rle = new(runvalues,runends)
    return(rle)
  end
end

function RLEVector{T1,T2 <: Integer}(runvalues::Vector{T1}, runends::Vector{T2})
  nrun = numruns(runvalues,runends)
  if nrun != length(runends)
    runvalues, runends = ree(runvalues,runends,nrun)
  end
  RLEVector{T1,T2}(runvalues, runends)
end

function RLEVector{T2 <: Integer}(runvalues::BitVector, runends::Vector{T2})
  nrun = numruns(runvalues,runends)
  if nrun != length(runends)
    runvalues, runends = ree(runvalues,runends,nrun)
  end
  RLEVector{Bool,T2}(runvalues, runends)
end

function RLEVector(vec::Vector)
  runvalues, runends = ree(vec)
  RLEVector(runvalues, runends)
end

#  Having specific types of Rle would be useful for lists of the same type, but Julia does a good job noticing that
#  Could also be useful for method definitions
typealias FloatRle RLEVector{Float64,UInt32}
typealias IntegerRle RLEVector{Int64,UInt32}
typealias BoolRle RLEVector{Bool,UInt32}
typealias StringRle RLEVector{String,UInt32}

# similar
function similar(x::RLEVector, element_type::Type, dims::Dims)
    len = dims[1]
    if len == 0
        return( RLEVector(element_type[], eltype(x.runends)[]) )
    else
        return( RLEVector(zeros(element_type, 1), eltype(x.runends)[len]) )
    end
end

# show
Base.show(io::IO, ::MIME"text/plain",  a::RLEVector) = show(io, a)
function show(io::IO, x::RLEVector)
    t = typeof(x)::DataType
    show(io, t)
    print("\n")
    n = nrun(x)
    if n > 10
        rv = x.runvalues
        re = x.runends
        print("run values: [$(rv[1]),$(rv[2]),$(rv[5]) \u2026 $(rv[n-4]),$(rv[n-1]),$(rv[n])]\n")
        print("run ends:   [$(re[1]),$(re[2]),$(re[5]) \u2026 $(re[n-4]),$(re[n-1]),$(re[n])]")
    else
        println("run values: ", x.runvalues)
        println("run ends:   ", x.runends)
    end
end

# conversions
convert(::Type{Vector}, x::RLEVector) = collect(x)
convert(::Type{Set}, x::RLEVector) = Set(rvalue(x))
promote_rule(::Type{Set}, ::Type{RLEVector}) = Set

# the basics
function collect(x::RLEVector)
  inverse_ree(x.runvalues,x.runends)
end

function isequal(x::RLEVector, y::RLEVector)
  isequal(x.runends,y.runends) && isequal(x.runvalues, y.runvalues)
end

Base.hash(a::RLEVector) = hash(a.runvalues, hash(a.runlengths, hash(:RLEVector)))
==(a::RLEVector, b::RLEVector) = isequal(a.runvalues, b.runvalues) && isequal(a.runends, b.runends) && true

