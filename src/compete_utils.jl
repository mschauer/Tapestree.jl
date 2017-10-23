#=

Utilities for Data Augmented Competition model

Ignacio Quintero Mächler

t(-_-t)

May 01 2017

=#




"""
    logdexp(x::Float64, λ::Float64)

Compute the logarithmic transformation of the 
**Exponential** density with mean `λ` for `x`.
"""
logdexp(x::Float64, λ::Float64) = @fastmath log(λ) - λ * x




"""
    logdnorm(x::Float64, μ::Float64, σ²::Float64)
  
Compute the logarithmic transformation of the 
**Normal** density with mean `μ` and variance `σ²` for `x`.
"""
logdnorm(x::Float64, μ::Float64, σ²::Float64) = 
  @fastmath -(0.5*log(2.0π) + 0.5*log(σ²) + abs2(x - μ)/(2.0 * σ²))




"""
    logdhcau(x::Float64, scl::Float64)

Compute the logarithmic transformation of the 
**Half-Cauchy** density with scale `scl` for `x`.
"""
logdhcau(x::Float64, scl::Float64) = 
  @fastmath log(2 * scl/(π *(x * x + scl * scl)))




"""
    logdhcau1(x::Float64)
  
Compute the logarithmic transformation of the 
**Half-Cauchy** density with scale of 1 for `x`.
"""
logdhcau1(x::Float64) = 
  @fastmath log(2/(π * (x * x + 1)))




"""
    rexp(λ::Float64)

Generate one sample from a random **Exponential** variable
with mean `λ`. 
"""
rexp(λ::Float64) = @fastmath (log(rand()) * -(1.0/λ))::Float64





"""
    coinsamp(p0::Float64) 
  
Generate one sample from a random **Binomial** variable
with probability of failure `p0`. 
"""
coinsamp(p0::Float64) = rand() < p0 ? 0 : 1





"""
    normlize(pt1::Float64, pt2::Float64)

Normalize probabilities to 1.
"""
normlize(pt1::Float64, pt2::Float64) = pt1/(pt1 + pt2)





"""
    Ptrfast(λ1::Float64, λ0::Float64, t::Float64)

Return Markov chain probabilities for 
two states through fast analytical solution
after time `t` for rates of gain `λ1` and loss `λ0`.
"""
function Ptrfast(λ1::Float64, λ0::Float64, t::Float64)
  
  @fastmath begin

    sumλ ::Float64 = λ1 + λ0
    ex   ::Float64 = exp(-sumλ*t)
    sd1  ::Float64 = 1/sumλ
    λ1ex ::Float64 = λ1*ex
    λ0ex ::Float64 = λ0*ex

    ((sd1*(λ0 + λ1ex), sd1*(λ1 - λ1ex)), 
     (sd1*(λ0 - λ0ex), sd1*(λ1 + λ0ex)))
  end
end






"""
    Ptrfast(λ1::Float64, ω1::Float64, λ0::Float64, ω0::Float64, avg_Δx::Float64, t::Float64)

Return Markov chain probabilities for 
two states through fast analytical solution
after time `t` for rates of gain `λ1(t) = λ1*exp(ω1*avg_Δx)` and 
loss `λ0(t) = λ0*exp(ω0*avg_Δx)`, conditional on a start value.
"""
function Ptrfast(λ1    ::Float64, 
                 ω1    ::Float64,
                 λ0    ::Float64,
                 ω0    ::Float64,
                 avg_Δx::Float64,
                 t     ::Float64)
  
  @fastmath begin

    λt1  ::Float64 = λ1*exp(ω1*avg_Δx)
    λt0  ::Float64 = λ0*exp(ω0*avg_Δx)
    sumλ ::Float64 = λt1 + λt0
    ex   ::Float64 = exp(-sumλ*t)
    sd1  ::Float64 = 1/sumλ
    λt1ex::Float64 = λt1*ex
    λt0ex::Float64 = λt0*ex

    ((sd1*(λt0 + λt1ex), sd1*(λt1 - λt1ex)), 
     (sd1*(λt0 - λt0ex), sd1*(λt1 + λt0ex)))

  end
end





"""
    Ptrfast_start(λ1::Float64, λ0::Float64, t::Float64, state::Int64)

Return Markov chain probabilities for 
two states through fast analytical solution
after time `t` for rates of gain `λ1` and loss `λ0`,
conditional on a start value.
"""
function Ptrfast_start(λ1::Float64, λ0::Float64, t::Float64, state::Int64)
  
  @fastmath begin

    sumλ ::Float64 = λ1 + λ0
    ex   ::Float64 = exp(-sumλ*t)
    sd1  ::Float64 = 1/sumλ
    λ1ex ::Float64 = λ1*ex
    λ0ex ::Float64 = λ0*ex

    if state == 0
      sd1*(λ0 + λ1ex), sd1*(λ1 - λ1ex) 
    else
      sd1*(λ0 - λ0ex), sd1*(λ1 + λ0ex)
    end
  end
end




"""
    Ptrfast_start(λ1::Float64, ω1::Float64, λ0::Float64, ω0::Float64, avg_Δx::Float64, t::Float64, state::Int64)

Return Markov chain probabilities for 
two states through fast analytical solution
after time `t` for rates of gain `λ1(t) = λ1*exp(ω1*avg_Δx)` and 
loss `λ0(t) = λ0*exp(ω0*avg_Δx)`, conditional on a start value.
"""
function Ptrfast_start(λ1    ::Float64, 
                       ω1    ::Float64,
                       λ0    ::Float64,
                       ω0    ::Float64,
                       avg_Δx::Float64,
                       t     ::Float64, 
                       state ::Int64)
  
  @fastmath begin

    λt1  ::Float64 = λ1*exp(ω1*avg_Δx)
    λt0  ::Float64 = λ0*exp(ω0*avg_Δx)
    sumλ ::Float64 = λt1 + λt0
    ex   ::Float64 = exp(-sumλ*t)
    sd1  ::Float64 = 1/sumλ
    λt1ex::Float64 = λt1*ex
    λt0ex::Float64 = λt0*ex
    
    if state == 0
      sd1*(λt0 + λt1ex), sd1*(λt1 - λt1ex) 
    else
      sd1*(λt0 - λt0ex), sd1*(λt1 + λt0ex)
    end

  end
end





"""
    Ptrfast_end(λ1::Float64, λ0::Float64, t::Float64, state::Int64)

Return Markov chain probabilities for 
two states through fast analytical solution
after time `t` for rates of gain `λ1` and loss `λ0`,
conditional on a end value.
"""
function Ptrfast_end(λ1::Float64, λ0::Float64, t::Float64, state::Int64)
  
  @fastmath begin

    sumλ ::Float64 = λ1 + λ0
    ex   ::Float64 = exp(-sumλ*t)
    sd1  ::Float64 = 1/sumλ
    λ1ex ::Float64 = λ1*ex
    λ0ex ::Float64 = λ0*ex

    if state == 0
      sd1*(λ0 + λ1ex), sd1*(λ0 - λ0ex)
    else
      sd1*(λ1 - λ1ex), sd1*(λ1 + λ0ex)
    end
  end
end





"""
    Ptrfast_end(λ1::Float64, ω1::Float64, λ0::Float64, ω0::Float64, avg_Δx::Float64, t::Float64, state::Int64)

Return Markov chain probabilities for 
two states through fast analytical solution
after time `t` for rates of gain `λ1(t) = λ1*exp(ω1*avg_Δx)` and 
loss `λ0(t) = λ0*exp(ω0*avg_Δx)`, conditional on a end value.
"""
function Ptrfast_end(λ1    ::Float64, 
                     ω1    ::Float64,
                     λ0    ::Float64,
                     ω0    ::Float64,
                     avg_Δx::Float64,
                     t     ::Float64, 
                     state ::Int64)
  
  @fastmath begin

    λt1  ::Float64 = λ1*exp(ω1*avg_Δx)
    λt0  ::Float64 = λ0*exp(ω0*avg_Δx)
    sumλ ::Float64 = λt1 + λt0
    ex   ::Float64 = exp(-sumλ*t)
    sd1  ::Float64 = 1/sumλ
    λt1ex::Float64 = λt1*ex
    λt0ex::Float64 = λt0*ex

    if state == 0
      sd1*(λt0 + λt1ex), sd1*(λt0 - λt0ex)
    else
      sd1*(λt1 - λt1ex), sd1*(λt1 + λt0ex)
    end
  end
end






"""
    idxlessthan(x::Array{Float64,1}, val::Float64)

Get index in sorted vector `x` corresponding to the value 
that is closest to but less than `val` in sorted arrays 
using a sort of uniroot algorithm.
"""
function idxlessthan(x::Array{Float64,1}, val::Float64) 
  
  @inbounds begin

    a  ::Int64 = 1
    b  ::Int64 = endof(x)
  
    if x[b] < val
      return b
    end

    mid::Int64 = div(b,2)  

    while b-a > 1
      val < x[mid] ? b = mid : a = mid
      mid = div(b + a, 2)
    end

  end

  return a
end 





"""
    indmindif_sorted(x::Array{Float64,1}, val::Float64)

Get index in sorted vector `x` corresponding to the value 
that is closest to `val` in sorted arrays 
using a sort of uniroot algorithm.
"""
function indmindif_sorted(x::Array{Float64,1}, val::Float64) 
  a::Int64   = 1
  b::Int64   = endof(x)
  mid::Int64 = div(b,2)  

  while b-a > 1
    val < x[mid] ? b = mid : a = mid
    mid = div(b + a, 2)
  end

  abs(x[a] - val) < abs(x[b] - val) ? a : b
end 






"""
    indmindif_sorted(x::Array{Int64,1}, val::Int64)

Get index in sorted vector `x` corresponding to the value 
that is closest to `val` in sorted arrays 
using a sort of uniroot algorithm. For `Int64`.
"""
function indmindif_sorted(x::Array{Int64,1}, val::Int64) 
  a::Int64   = 1
  b::Int64   = endof(x)
  mid::Int64 = div(b,2)  

  while b-a > 1
    val < x[mid] ? b = mid : a = mid
    mid = div(b + a, 2)
  end

  abs(x[a] - val) < abs(x[b] - val) ? a : b
end 





"""
    make_edgeind(childs::Array{Int64,1}, B::Array{Float64,2})
  
Make ragged array with indexes for each edge in `Y`.
"""
function make_edgeind(childs::Array{Int64,1}, B::Array{Float64,2}, ntip::Int64)

  bridx = Array{Int64,1}[]
  for b in childs
    bidinces = find(b .== B)
    if b != (ntip+1)
      unshift!(bidinces, bidinces[1] - 1)
    end
    push!(bridx, bidinces)
  end

  bridx
end





"""
    make_edgeδt(bridx::Array{Array{Int64,1},1}, δt::Array{Float64,1}, m ::Int64)

Make ragged array of the cumulative δtimes for each branch.
"""
function make_edgeδt(bridx::Array{Array{Int64,1},1}, 
                     δt   ::Array{Float64,1}, 
                     m    ::Int64)
  
  brδt = Array{Float64,1}[]
  
  for j in 1:(length(bridx)-1)
    bi = copy(bridx[j][1:(end-1)])
    for i in eachindex(bi)
      bi[i] = rowind(bi[i], m)
    end
    push!(brδt, unshift!(cumsum(δt[bi]),0))
  end
  
  brδt
end





"""
    maketriads(edges::Array{Int64,2})

Make branch triads:
returns a separate vector with indexes for each 
branch connecting to a node.
First number is the parent branch
second and third numbers each the daughters.
"""
function maketriads(edges::Array{Int64,2})

  # internal nodes
  ins::Array{Int64,1} = unique(edges[:,1])[1:(end-1)]
  lins = length(ins)

  trios = Array{Int64,1}[]

  # for all internal nodes
  for i = Base.OneTo(lins)
    ndi  = ins[i]
    daus = find(edges[:,1] .== ndi)
    unshift!(daus, find(edges[:,2] .== ndi)[1])
    push!(trios, daus)
  end

  trios
end





"""
    create_wcol(X::Array{Float64,2})

Returns indices for columns along `m` timesteps.
"""
function create_wcol(X::Array{Float64,2})

  X_fornan  = deepcopy(X)
  wNaN_x    = .!isnan.(X_fornan[Base.OneTo(end),:])

  # make ragged array for non-NaN columns
  wcol = Array{Int64,1}[]
  for i = Base.OneTo(size(X,1))
    push!(wcol,find(wNaN_x[i,:]))
  end

  wcol
end




"""
    collision(λ1::Float64, λ0::Float64, nδts  ::Array{Float64,1})

Estimates the probability of at least one collision
along the whole tree.
"""
function collision(λ1   ::Float64, 
                   λ0   ::Float64, 
                   nδts  ::Array{Float64,1})

  @fastmath begin

    p = 1.0
    for t in nδts
      p *= 1.0 - Pc(λ1, λ0, t)
    end

    return 1.0 - p
  end
end















