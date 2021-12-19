# FORM.jl

This package provides functions for the automatic generation and compilation
of highly efficient code for the evaluation of multivariate polynomials
and their derivatives.
The code is generated by the symbolic manipulation system
[FORM](http://www.nikhef.nl/~form/),
for which a Julia interface is provided.

## Installation
```julia
using Pkg
Pkg.add(PackageSpec(url="https://github.com/HaraldHofstaetter/FORM.jl"))
```

## Usage
### `compile_f`: generate efficient code for a multivariate polynomial

```julia
julia> using FORM

#Compile polynomial, polynomial given as string,
#variables given as vector of strings;
julia> f = compile_f("x^2+3*y^2*x+1", ["x", "y"])
#37 (generic function with 1 method)

julia> f([2,3])
59

julia> f([2im,3-1im])
33 + 48im

#Polynomial with parameters:
julia> g = compile_f("x^2+3*y^2*x+a^2", ["x", "y"], pars=["a"])
#39 (generic function with 1 method)

julia> g([2,3],[4])
74

#Polynomials can also be specified using a package wich
#implements multivariate polynomials:
julia> import DynamicPolynomials: @polyvar

julia> @polyvar x y a
(x, y, a)

julia> g1 = compile_f(x^2+3y^2*x+a^2, [x, y], pars=[a])
#41 (generic function with 1 method)
```

### `compile_fg`: generate efficient code for a polynomial and its gradient
```julia
julia> fg = compile_fg("x^2+3*y^2*x+1", ["x", "y"])
#43 (generic function with 1 method)

#Allocate array for gradient:
julia> G = zeros(2);

julia> fg(G, [2.0, 3.0])
59.0

julia> G
2-element Vector{Float64}:
 31.0
 36.0
```
### `compile_fj`: generate efficient code for a polynomial system and its jacobian
```julia
julia> fj! = compile_fj(["x^2+y^2-3", "x+y-2"], ["x","y"])
#45 (generic function with 1 method)

julia> fj!(F, J, [2.0, 3.0]);

julia> F
2-element Vector{Float64}:
 10.0
 -9.0

julia> J
2×2 Matrix{Float64}:
 4.0   6.0
 1.0  -3.0
```

## Solving polynomial systems using [`NLSolve.jl`](https://github.com/JuliaNLSolvers/NLsolve.jl)
The function generated by `compile_fj`, having exactly the form as described in ["Providing only fj!"](https://github.com/JuliaNLSolvers/NLsolve.jl#providing-only-fj),
can directly be used by `NLsolve.jl`.
```julia
julia> using NLsolve

julia> X = rand(2)
2-element Vector{Float64}:
 0.13995340906069542
 0.24559382702772314

julia> sol = nlsolve(only_fj!(fj!), X)
Results of Nonlinear Solver Algorithm
 * Algorithm: Trust-region with dogleg and autoscaling
 * Starting Point: [0.13995340906069542, 0.24559382702772314]
 * Zero: [1.7297058540778356, -0.09009804864072146]
 * Inf-norm of residuals: 0.000000
 * Iterations: 6
 * Convergence: true
   * |x - x'| < 0.0e+00: false
   * |f(x)| < 1.0e-08: true
 * Function Calls (f): 7
 * Jacobian Calls (df/dx): 7


``` 

## Performance 
todo...
