#=

Wrapper

Ignacio Quintero Mächler

t(-_-t)

September 26 2017

=#


"""
    ESSE(states_file ::String,
         tree_file   ::String,
         envdata_file::String,
         cov_mod     ::NTuple{M,String},
         out_file    ::String,
         h           ::Int64;
         constraints ::NTuple{N,String}  = (" ",),
         niter       ::Int64             = 10_000,
         nthin       ::Int64             = 10,
         λpriors     ::Float64           = .1,
         μpriors     ::Float64           = .1,
         gpriors     ::Float64           = .1,
         lpriors     ::Float64           = .1,
         qpriors     ::Float64           = .1,
         βpriors     ::NTuple{2,Float64} = (0.0, 10.0),
         hpriors     ::Float64           = .1,
         optimal_w   ::Float64           = 0.8,
         screen_print::Int64             = 5)

Wrapper for running a SSE model.
"""
function ESSE(states_file ::String,
              tree_file   ::String,
              envdata_file::String,
              cov_mod     ::NTuple{M,String},
              out_file    ::String,
              h           ::Int64;
              constraints ::NTuple{N,String}  = (" ",),
              niter       ::Int64             = 10_000,
              nthin       ::Int64             = 10,
              nburn       ::Int64             = 200,
              ntakew      ::Int64             = 100,
              winit       ::Float64             = 2.0,
              scale_y     ::NTuple{2,Bool}    = (true, false),
              algorithm   ::String            = "pruning",
              λpriors     ::Float64           = .1,
              μpriors     ::Float64           = .1,
              gpriors     ::Float64           = .1,
              lpriors     ::Float64           = .1,
              qpriors     ::Float64           = .1,
              βpriors     ::NTuple{2,Float64} = (0.0, 10.0),
              hpriors     ::Float64           = .1,
              optimal_w   ::Float64           = 0.8,
              screen_print::Int64             = 5,
              Eδt         ::Float64           = 1e-3,
              ti          ::Float64           = 0.0,
              E0          ::Array{Float64,1}  = [0.0,0.0]) where {M,N}

  # read data 
  tv, ed, el, bts, x, y = 
    read_data_esse(states_file, tree_file, envdata_file)

  printstyled("Data successfully read \n", color = :green)

  # scale y
  if scale_y[1]
    # if scale each function separately or together
    if scale_y[2]
      ymin = minimum(y)
      ymax = maximum(y)
      for j in axes(y,2), i in axes(y,1)
        y[i,j] = (y[i,j] - ymin)/(ymax - ymin)
      end
    else
      ymin = minimum(y, dims = 1)
      ymax = maximum(y, dims = 1)
      for j in axes(y,2), i in axes(y,1)
        y[i,j] = (y[i,j] - ymin[j])/(ymax[j] - ymin[j])
      end
    end
  end

  # prepare data
  X, p, fp, trios, ns, ned, pupd, phid, nnps, nps, dcp, dcfp, 
    pardic, k, h, ny, model, af!, assign_hidfacs!, abts, E0 = 
        prepare_data(cov_mod, tv, x, y, ed, el, E0, h, constraints) 

  printstyled("Data successfully prepared \n", color = :green)

  # make likelihood function
  if occursin(r"^[f|F][A-za-z]*", algorithm) 

    # prepare likelihood
    Gt, Et, lbts, nets, λevent!, rootll = 
      prepare_ll(p, bts, E0, k, h, ny, ns, ned, model, Eδt, ti, abts, af!)

    # make likelihood function
    llf = make_loglik(Gt, Et, X, trios, lbts, bts, ns, ned, nets, 
                      λevent!, rootll)

  elseif occursin(r"^[p|P][A-za-z]*", algorithm)

    # prepare likelihood
    X, ode_solve, λevent!, rootll, abts1, abts2 = 
      prepare_ll(X, p, E0, ns, k, h, ny, model, abts ,af!)

    # make likelihood function
    llf = make_loglik(X, abts1, abts2, trios, ode_solve, 
      λevent!, rootll, k, h, ns, ned)

  else
    error("No matching likelihood algorithm")

  end

  # create prior function
  lpf = make_lpf(pupd, phid, 
    λpriors, μpriors, gpriors, lpriors, qpriors, βpriors, hpriors, 
    k, h, ny, model)

  # create posterior functions
  lhf = make_lhf(llf, lpf, assign_hidfacs!, dcp, dcfp)

  # run slice sampler
  R = slice_sampler(lhf, p, fp, nnps, nps, phid, length(pardic), 
                    niter, nthin, nburn, ntakew, winit, optimal_w, screen_print)

  write_ssr(R, pardic, out_file)

  return R
end





"""
    read_data_esse(states_file ::String, 
                   tree_file   ::String, 
                   envdata_file::String)

Process tree and state and environmental data file to run ESSE.
"""
function read_data_esse(states_file ::String, 
                        tree_file   ::String, 
                        envdata_file::String)

  # read tree in postorder and assign to objects
  tree, bts = read_tree(tree_file, order = "postorder", branching_times = true)
  ntip = tree.nnod + 1
  ed   = tree.ed
  el   = tree.el
  tlab = tree.tlab

  # assign tip labels to edge numbers
  tip_labels = Dict{String,Integer}()
  ii = 0
  for i in Base.OneTo(size(ed,1))
    if ed[i,2] <= ntip
      ii += 1
      tip_labels[tlab[ii]] = ed[i,2]
    end
  end

  # read states text file
  data = DelimitedFiles.readdlm(states_file)

  if size(data,1) != ntip
    data = DelimitedFiles.readdlm(states_file, '\t', '\r')
  end

  if size(data,1) != ntip
    data = DelimitedFiles.readdlm(states_file, '\t', '\n')
  end

  if size(data,1) != ntip 
    error("Data file cannot be made of the right dimensions.\n Make sure the data file has the same number of rows as tips in the tree")
  end

  data_tlab    = convert(Array{String,1}, data[:,1])
  data_states  = convert(Array{Float64,2},  data[:,2:end])

  # create dictionary
  tip_states = Dict(tip_labels[val] => data_states[i,:] 
                   for (i,val) = enumerate(data_tlab))

  # process environmental data file
  envdata = DelimitedFiles.readdlm(envdata_file)

  x = envdata[:,1]
  y = envdata[:,2:end]

  return tip_states, ed, el, bts, x, y
end





"""
  write_ssr(R       ::Array{Float64,2}, 
            pardic  ::Dict{String,Int64},
            out_file::String)

Write the samples from an MCMC data frame given a Dictionary of parameters.
"""
function write_ssr(R       ::Array{Float64,2}, 
                   pardic  ::Dict{String,Int64},
                   out_file::String)

  # column names
  col_nam = ["Iteration", "Posterior"]

  for (k,v) in sort!(collect(pardic), by = x -> x[2])
    push!(col_nam, k)
  end

  R = vcat(reshape(col_nam, 1, lastindex(col_nam)), R)

  writedlm(out_file*".log", R)
end





