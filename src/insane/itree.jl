#=

insane tree structure

Ignacio Quintero Mächler

t(-_-t)

Created 25 06 2020
=#



"""
    itree

A Composite recursive type representing a binary phylogenetic tree 
for `insane` use, with the following fields:

  d1: daughter tree 1
  d2: daughter tree 2
  pe: pendant edge
  at: absolute node time
  iμ: is an extinction node

    itree()

Constructs an empty `itree` object.

    itree(pe::Float64)

Constructs an empty `itree` object with pendant edge `pe`.

    itree(d1::itree, d2::itree, pe::Float64)

Constructs an `itree` object with two `itree` daughters and pendant edge `pe`.

    itree(d1::itree, d2::itree, pe::Float64, at::Float64)

Constructs an `itree` object with two `itree` daughters, pendant edge `pe` at absolute time `at`.
"""
mutable struct itree
  d1::Union{itree, Nothing}
  d2::Union{itree, Nothing}
  pe::Float64
  at::Float64
  iμ::Bool

  # constructors
  itree() = new(nothing, nothing, 0.0, 0.0, false)
  itree(pe::Float64) = new(nothing, nothing, pe, 0.0, false)
  itree(pe::Float64, iμ::Bool) = 
    new(nothing, nothing, pe, 0.0, isμ)
  itree(d1::itree, d2::itree, pe::Float64, isμ::Bool) = 
    new(d1, d2, pe, 0.0, isμ)
  itree(d1::itree, d2::itree, pe::Float64) = new(d1, d2, pe, 0.0, false)
  itree(d1::itree, d2::itree, pe::Float64, at::Float64) = 
    new(d1, d2, pe, at, false)
  itree(d1::itree, d2::itree, pe::Float64, at::Float64, 
        isλ::Bool, isμ::Bool, ist::Bool) = 
    new(d1, d2, pe, at, isμ)
end









