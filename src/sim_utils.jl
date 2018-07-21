#=

Utility functions for simulations for tribe

Ignacio Quintero Mächler

August 29 2017

t(-_-t)

=#



X_initial = 0.0
nareas    = 3
tree_file = homedir()*"/data/turnover/example_tree_5.tre"
ωx        = 0.0
σ         = 0.5
λ1        = 2.0
λ0        = 1.0
ω1        = 0.0
ω0        = 0.0
const_δt  = 1e-4



"""
    simulate_tribe(X_initial::Float64,
                   nareas   ::Int64,
                   tree_file::String;
                   ωx       = 0.0,
                   σ        = 0.5,
                   λ1       = 0.5,
                   λ0       = 0.2,
                   ω1       = 0.0,
                   ω0       = 0.0,
                   const_δt = 1e-4)

Simulate tribe model.
"""
function simulate_tribe(X_initial::Float64,
                        nareas   ::Int64,
                        tree_file::String;
                        ωx       = 0.0,
                        σ        = 0.5,
                        λ1       = 0.5,
                        λ0       = 0.2,
                        ω1       = 0.0,
                        ω0       = 0.0,
                        const_δt = 1e-4)

  Y_initial = 
    [rand() < λ1/(λ1 + λ0) ? 1 : 0 for i in Base.OneTo(nareas)]::Array{Int64,1}

  while iszero(sum(Y_initial))
    Y_initial = 
      [rand() < λ1/(λ1 + λ0) ? 1 : 0 for i in Base.OneTo(nareas)]::Array{Int64,1}
  end

  tree, bts = read_tree(tree_file)

  const br = branching_times(tree)

  # sort according to branching times
  const brs = sortrows(br, by = x->(x[5]), rev = true)

  # sort branching times
  sort!(bts, rev = true)

  # add present
  push!(bts, 0.0)

  # number of speciation events
  nbt = endof(bts) - 1

  # calculate speciation waiting times
  const swt = Array{Float64,1}(nbt)
  for i in Base.OneTo(nbt)
    swt[i] = bts[i] - bts[i+1]
  end

  # initial values
  Xt = fill(X_initial, 2)

  Y_initial = reshape(vec(Y_initial), 1, :)
  Yt = vcat(Y_initial, Y_initial)

  # start of alive
  @inbounds alive  = sortrows(br, by = x->(x[1]))[1:2,2]
  nalive = length(alive)

  # loop through waiting times
  for j in Base.OneTo(nbt)

    nreps = reps_per_period(swt[j], const_δt)

    # simulate during the speciation waiting time
    nconst_sim!(Xt, Yt, nreps, const_δt, ωx, σ, λ1, λ0, ω1, ω0)






    if j == nbt
      break
    end

    # which lineage speciates
    wsp = brs[j,2]

    # where to insert
    wti = find(wsp .== alive)[1]

    # index to insert
    idx = sort(push!(collect(1:nalive), wti))

    # insert in Xt & Yt
    Xt = Xt[idx]
    Yt = Yt[idx,:]

    # update alive
    chs = brs[find(wsp .== brs[:,1]),2]

    alive[wti] = chs[1]
    insert!(alive, wti+1, chs[2])

    nalive = length(alive)

  end

  tip_traits = 
    Dict(convert(Int64, alive[i]) => Xt[i]   for i = Base.OneTo(nalive))
  tip_areas  = 
    Dict(convert(Int64, alive[i]) => Yt[i,:] for i = Base.OneTo(nalive))

  pop!(bts)

  return tip_traits, tip_areas, tree, bts

end





"""
    reps_per_period(br_length::Float64, const_δt::Float64)

Estimate number of repetitions for each speciation waiting time.
"""
reps_per_period(br_length::Float64, const_δt::Float64) = 
  round(Int64,cld(br_length,const_δt))





"""
    nconst_sim!(Xt   ::Array{Float64,1}, 
                Yt   ::Array{Int64,2},
                nreps::Int64,
                δt   ::Float64,
                ωx   ::Float64, 
                σ    ::Float64, 
                λ1   ::Float64, 
                λ0   ::Float64, 
                ω1   ::Float64, 
                ω0   ::Float64)

Simulate biogeographic and trait evolution along a 
speciation waiting time.
"""
function nconst_sim!(Xt   ::Array{Float64,1}, 
                     Yt   ::Array{Int64,2},
                     nreps::Int64,
                     δt   ::Float64,
                     ωx   ::Float64, 
                     σ    ::Float64, 
                     λ1   ::Float64, 
                     λ0   ::Float64, 
                     ω1   ::Float64, 
                     ω0   ::Float64)

  # n species and k areas
  const n, narea = size(Yt)
  const Ytp      = similar(Yt)
  const nch      = zeros(Int64, n)

  # allocate memory for lineage averages and differences
  δX = zeros(n, n)     # X pairwise differences
  δY = zeros(n, n)     # Y pairwise differences
  la = zeros(n)        # lineage averages
  ld = zeros(n,k)      # area specific lineage rates

  for i in Base.OneTo(nreps)

    # estimate area and lineage averages and area occupancy
    δXY_la_ld!(δX, δY, la, ld, Xt, Yt, n, narea)

    # trait step
    traitsam_1step!(Xt, la, δt, ωx, σ, n)


    # biogeographic step
    copy!(Ytp, Yt)
    biogeosam_1step!(ω1, ω0, λ1, λ0, ld, Ytp, nch, δt, n, narea)

    while check_sam(Ytp, nch, n, narea)
      copy!(Ytp, Yt)
      biogeosam_1step!(ω1, ω0, λ1, λ0, ld, Ytp, nch, δt, n, narea)
    end

    copy!(Yt,Ytp)
  end

  return nothing
end





"""
    δXY_la_ld!(δX   ::Array{Float64,2},
               δY   ::Array{Float64,2},
               la   ::Array{Float64,1},
               ld   ::Array{Float64,2},
               Xt   ::Array{Float64,1}, 
               Yt   ::Array{Int64,2}, 
               n    ::Int64,
               narea::Int64)

Estimate area and lineage specific averages given sympatry configuration.
"""
function δXY_la_ld!(δX   ::Array{Float64,2},
                    δY   ::Array{Float64,2},
                    la   ::Array{Float64,1},
                    ld   ::Array{Float64,2},
                    Xt   ::Array{Float64,1}, 
                    Yt   ::Array{Int64,2}, 
                    n    ::Int64,
                    narea::Int64)
  @inbounds begin

    # estimate pairwise distances
    for j = Base.OneTo(n), i = Base.OneTo(n)
      i == j && continue
      # δX differences
      δX[i,j] = Xt[i] - Xt[j]
      # δY differences
      sk        = 0.0
      δY[i,j] = 0.0
      @simd for k = Base.OneTo(narea)
        if Yt[j,k] == 1
            sk += 1.0
            δY[i,j] += Float64(Yt[i,k])
        end
      end
      δY[i,j] /= sk
    end

    # estimate lineage averages
    la[:] = 0.0
    for j = Base.OneTo(n), i = Base.OneTo(n)
        i == j && continue
        la[i] += sign(δX[j,i]) * δY[j,i] * exp(-abs(δX[j,i]))
    end

    # estimate lineage sum of distances
    ld[:] = 0.0
    for k = Base.OneTo(narea), i = Base.OneTo(n), j = Base.OneTo(n)
      j == i && continue
      ld[i,k] += abs(δX[j,i])*Float64(Yt[j,k])
    end
  end

  return nothing
end





"""
    traitsam_1step((Xt::Array{Float64,1}, μ ::Array{Float64,1}, δt::Float64, ωx::Float64, σ::Float64, n::Int64)

Sample one step for trait evolution history: `X(t + δt)`.
"""
function traitsam_1step!(Xt::Array{Float64,1}, 
                         la::Array{Float64,1}, 
                         δt::Float64, 
                         ωx::Float64, 
                         σ ::Float64,
                         n ::Int64)

  @inbounds @fastmath begin
    
    for i in Base.OneTo(n)
      Xt[i] += Eδx(la[i], ωx, δt) + randn()*σ*sqrt(δt)
    end

  end
end





"""
    biogeosam_1step!(ω1   ::Float64,
                     ω0   ::Float64,
                     λ1   ::Float64,
                     λ0   ::Float64,
                     ld   ::Array{Float64,2},
                     Ytp  ::Array{Int64,2},
                     nch  ::Array{Int64,1},
                     δt   ::Float64,
                     n    ::Int64,
                     narea::Int64)

Sample one step for biogeographic history: `Y(t + δt)`.
"""
function biogeosam_1step!(ω1   ::Float64,
                          ω0   ::Float64,
                          λ1   ::Float64,
                          λ0   ::Float64,
                          ld   ::Array{Float64,2},
                          Ytp  ::Array{Int64,2},
                          nch  ::Array{Int64,1},
                          δt   ::Float64,
                          n    ::Int64,
                          narea::Int64)

  @inbounds begin

    nch[:] = 0
    for k = Base.OneTo(narea), i = Base.OneTo(n)
      if iszero(Ytp[i,k])
        if rand() < f_λ1(λ1,ω1,ld[i,k])*δt
          setindex!(Ytp,1,i,k)
          nch[i] += 1
        end
      else 
        if rand() < f_λ0(λ0,ω0,ld[i,k])*δt
          setindex!(Ytp,0,i,k)
          nch[i] += 1 
        end
      end
    end

  end

  return nothing
end





"""
    check_sam(Ytc::Array{Int64,2}, nch::Array{Int64,1}, n::Int64, k::Int64)

Returns false if biogeographic step consists of *only one* change 
or if the species does *not* go globally extinct. 
"""
function check_sam(Ytp::Array{Int64,2}, nch::Array{Int64,1}, n::Int64, nareas::Int64)

  @fastmath @inbounds begin

    # check lineage did not go extinct
    for i in Base.OneTo(n)
      s = 0
      for j in Base.OneTo(nareas)
        s += Ytp[i,j]
      end
      if iszero(s)
        return true
      end
    end


    # check that, at most, only one event happened per lineage
    for i in nch
      if i > 1
        return true
      end
    end

    return false
  end
end









