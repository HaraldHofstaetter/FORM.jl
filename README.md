# FORM.jl

This package provides functions for the automatic generation and compilation
of highly efficient code for the evaluation of multivariate polynomials
and their derivatives.
The code is generated by the symbolic manipulation system
[FORM](https://github.com/vermaseren/form),
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
#variables given as vector of strings:
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

julia> g1([2,3],[4])
74
```

### `compile_fg`: generate efficient code for a polynomial and its gradient
```julia
julia> fg! = compile_fg("x^2+3*y^2*x+1", ["x", "y"])
#43 (generic function with 1 method)

#Allocate array for gradient:
julia> G = zeros(2);

julia> fg!(G, [2.0, 3.0])
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

julia> F = zeros(2);

julia> J = zeros(2,2);

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
can directly be used with `NLsolve.jl`.
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
Our real-world test problem is the polynomial system contained in the 
file [`cf8.txt`](https://github.com/HaraldHofstaetter/FORM.jl/blob/master/test/cf8.txt),
which was 
generated with [`Expocon.mpl`](https://github.com/HaraldHofstaetter/Expocon.mpl), a Maple package for the generation of order conditions for the construction of exponential integrators, see
>[1] [H. Hofstätter](http://www.harald-hofstaetter.at), [W. Auzinger](http://www.asc.tuwien.ac.at/~winfried), [O. Koch](http://othmar-koch.org), [An Algorithm for Computing Coefficients of Words in Expressions Involving Exponentials and its Application to the Construction of Exponential Integrators](https://arxiv.org/pdf/1912.01399), [Proceedings of CASC 2019](http://www.casc.cs.uni-bonn.de/2019/), [Lecture Notes in Computer Science 11661, pp. 197-214](https://doi.org/10.1007/978-3-030-26831-2_14).

There, the generation of the polynomial system [`cf8.txt`](https://github.com/HaraldHofstaetter/FORM.jl/blob/master/test/cf8.txt) is described in Section 4.3.
In the the sample Maple code of Section 4.3 it is defined in the variable `eqs12`.

```julia
julia> using FORM

#read polynomial system from file, store it as a vector of strings:
julia> cf8 = readlines(joinpath(dirname(dirname(pathof(FORM))), "test", "cf8.txt"))
8-element Vector{String}:
 "-5040+10080*f11+10080*f21+10080*f31+10080*f41"
 "5040*f11*f12+10080*f12*f21+1008" ⋯ 77 bytes ⋯ "+10080*f32*f41+5040*f41*f42+840"
 "126+2940*f21^3*f22+11760*f21^2" ⋯ 1203 bytes ⋯ "0*f12*f31*f41^2+6720*f12*f41^3"
 "1680*f11*f12^2+5040*f12^2*f21+5" ⋯ 265 bytes ⋯ "*f32*f41*f42+1680*f41*f42^2-84"
 "5+840*f11*f21^3*f41*f42+11760*" ⋯ 4316 bytes ⋯ "f31*f32+1680*f11*f21^3*f32*f41"
 "-12+5040*f11^2*f12*f32*f41+252" ⋯ 3193 bytes ⋯ "*f32*f41^3*f42+924*f41^3*f42^2"
 "-2-5040*f11*f21*f22*f31*f32-10" ⋯ 2457 bytes ⋯ "22^2*f41-840*f21^2*f22*f31*f32"
 "6+420*f11*f12^3+1680*f12^3*f21+" ⋯ 572 bytes ⋯ "80*f32*f41*f42^2+420*f41*f42^3"

#polynomial system and its jacobian is compiled directly from the vector of strings:
julia> @time cf8_fj! = compile_fj(cf8, ["f11", "f21", "f31", "f41", "f12", "f22", "f32", "f42"]);
  0.650734 seconds (46.70 k allocations: 2.468 MiB)

julia> using BenchmarkTools

julia> F=zeros(8); J=zeros(8,8); X=rand(8);

julia> @btime $cf8_fj!($F, $J, $X);
  434.742 ns (0 allocations: 0 bytes)
```

We compare the performance of `Form.jl` with that of [`StaticPolynomials.jl`](https://github.com/JuliaAlgebra/StaticPolynomials.jl),
which is another library for the fast evaluation of multivariate polynomial systems and its jacobians.

```julia
julia> using StaticPolynomials

julia> import DynamicPolynomials: @polyvar

julia> @polyvar x[1:8]
(DynamicPolynomials.PolyVar{true}[x₁, x₂, x₃, x₄, x₅, x₆, x₇, x₈],)

#generate a Julia function by parsing the strings containing the polynomial system:
julia> cf8_fun = Meta.eval(Meta.parse(string("(f11,f21,f31,f41,f12,f22,f32,f42)->[",join(cf8,","),"]")))

#generate the polynomial system as an DynamicPolynomials object (this takes a very long time!)
julia> cf8_dp = cf8_fun(x...);

#transform the DynamicalPolynomials object to a StaticPolynomials object:
julia> cf8_sp = PolynomialSystem(cf8_f_mp);

julia> @btime evaluate_and_jacobian!($F, $J, $cf8_sp, $X)
  783.476 ns (0 allocations: 0 bytes)
```
