#=

insane tree data gatherers

Ignacio Quintero Mächler

t(-_-t)

Created 25 06 2020
=#



"""
    isfix(tree::iTree)

Return if is either an extant or extinct tip node.
"""
isfix(tree::iTree) = getproperty(tree,:fx)

isfix(::Nothing) = true




"""
    istip(tree::iTree)

Return if is either an extant or extinct tip node.
"""
istip(tree::iTree) = isnothing(tree.d1) && isnothing(tree.d2)

istip(::Nothing) = false




"""
    isλ(tree::iTree)

Return if is an extinction node.
"""
isextinct(tree::iTree) = getproperty(tree,:iμ)

isextinct(::Nothing) = false




"""
    pe(tree::iTree)

Return pendant edge.
"""
pe(tree::iTree) = getproperty(tree,:pe)

"""
    pe(tree::iTree)

Return pendant edge.
"""
pe(::Nothing) = 0.0




"""
    treelength(tree::iTree)

Return the branch length sum of `tree`.
"""
treelength(tree::iTree) = treelength(tree.d1) + treelength(tree.d2) + pe(tree)

"""
    treelength(::Nothing)

Return the branch length sum of `tree`.
"""
treelength(::Nothing) = 0.0




"""
    treeheight(tree::iTree)

Return the tree height of `tree`.
"""
function treeheight(tree::iTree)
  th1 = treeheight(tree.d1)
  th2 = treeheight(tree.d2)
  (th1 > th2 ? th1 : th2) + pe(tree)
end

"""
    treeheight(tree::iTree)

Return the tree height of `tree`.
"""
treeheight(::Nothing) = 0.0




"""
    snn(tree::iTree)

Return the number of descendant nodes for `tree`.
"""
snn(tree::iTree) = snn(tree.d1) + snn(tree.d2) + 1

"""
    snn(::Nothing)

Return the number of descendant nodes for `tree`.
"""
snn(::Nothing) = 0




"""
    snin(tree::iTree)

Return the number of internal nodes for `tree`.
"""
function snin(tree::iTree)
    if istip(tree)
      return 0
    else
      return snin(tree.d1) + snin(tree.d2) + 1
    end
end

"""
    snin(::Nothing)

Return the number of internal nodes for `tree`.
"""
snin(::Nothing) = 0





"""
    sntn(tree::iTree)

Return the number of tip nodes for `tree`.
"""
function sntn(tree::iTree)
    if istip(tree)
      return 1
    else
      return sntn(tree.d1) + sntn(tree.d2)
    end
end


"""
    sntn(::Nothing)

Return the number of tip nodes for `tree`.
"""
sntn(::Nothing) = 0




"""
    snen(tree::iTree)

Return the number of extinct tip nodes for `tree`.
"""
function snen(tree::iTree)
    if isextinct(tree)
      return 1
    else
      return snen(tree.d1) + snen(tree.d2)
    end
end


"""
    snen(::Nothing)

Return the number of extinct tip nodes for `tree`.
"""
snen(::Nothing) = 0





"""
    stree_ll_cbd(tree::iTree,
                 ll  ::Float64, 
                 λc  ::Float64, 
                 μc  ::Float64,
                 dri ::BitArray{1}, 
                 ldr ::Int64,
                 wpr ::Int64,
                 ix  ::Int64, 
                 px  ::Int64)

Return the Log-likelihood under constant birth-death 
of a grafted subtree determined by `dri`. 
"""
function streeheight(tree::iTree,
                     h   ::Float64, 
                     th  ::Float64,
                     dri ::BitArray{1}, 
                     ldr ::Int64,
                     wpr ::Int64,
                     ix  ::Int64, 
                     px  ::Int64)

  if ix == ldr
    if px == wpr
      if isfix(tree.d1)
        return h - pe(tree), treeheight(tree.d2)
      elseif isfix(tree.d2)
        return h - pe(tree), treeheight(tree.d1)
      end
    else
      px += 1
      if isfix(tree.d1)
        h, th = 
          streeheight(tree.d1, h - pe(tree), th, dri, ldr, wpr, ix, px)
      else
        h, th =
          streeheight(tree.d2, h - pe(tree), th, dri, ldr, wpr, ix, px)
      end
    end
  elseif ix < ldr
    ifx1 = isfix(tree.d1)
    if ifx1 && isfix(tree.d2)
      ix += 1
      if dri[ix]
        h, th = 
          streeheight(tree.d1, h - pe(tree), th, dri, ldr, wpr, ix, px)
      else
        h, th = 
          streeheight(tree.d2, h - pe(tree), th, dri, ldr, wpr, ix, px)
      end
    elseif ifx1
      h, th = 
        streeheight(tree.d1, h - pe(tree), th, dri, ldr, wpr, ix, px)
    else
      h, th =
        streeheight(tree.d2, h - pe(tree), th, dri, ldr, wpr, ix, px)
    end
  end
end

