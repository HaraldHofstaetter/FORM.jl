using FORM
using Libdl

compile_fj_to_c(["1/3*x1+x2^7-p1", "2*x1+2*x2-p2"], ["x1", "x2"], 
                "test_form.c", pars=["p1", "p2"])

# 1. double ###############################################

run(`gcc -O1 -fPIC -shared -o test_form_double.so test_form.c -lm`)

x=[2.0, 3.0]
p=[-1.0,4.0]
F=zeros(2)
J=zeros(2,2)

H0 = dlopen(string("./test_form_double.", dlext))
H = dlsym(H0, "eval_form")
fj! = (F,J,x,p) -> ccall(H, Nothing, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble},Ptr{Cdouble}), F, J, x, p)

fj!(F,J,x,p)

println("F=",F)
println("J=",J)

F1= [ 1/3*x[1]+x[2]^7-p[1], 2*x[1]+2*x[2]-p[2] ]
println("F1=",F1)


# 2. double complex ########################################

run(`gcc -O1 -fPIC -shared -DCOMPLEX -o test_form_complex.so test_form.c -lm`)

x=[2.0+1im, 3.0-2im]
p=[-1.0+3im,4.0-1im]
F=zeros(Complex{Float64}, 2)
J=zeros(Complex{Float64}, 2,2)

H0 = dlopen(string("./test_form_complex.", dlext))
H = dlsym(H0, "eval_form")
fj! = (F,J,x,p) -> ccall(H, Nothing, (Ptr{Complex{Cdouble}}, Ptr{Complex{Cdouble}}, 
                         Ptr{Complex{Cdouble}}, Ptr{Complex{Cdouble}}), F, J, x, p)

fj!(F,J,x,p)

println("F=",F)
println("J=",J)

F1= [ 1/3*x[1]+x[2]^7-p[1], 2*x[1]+2*x[2]-p[2] ]
println("F1=",F1)


# 3. __float128 ############################################

run(`gcc -O1 -fPIC -shared -DFLOAT128 -o test_form_float128.so test_form.c -lquadmath`)

using Quadmath

x=Float128[2, 3]
p=Float128[-1,4]
F=zeros(Float128,2)
J=zeros(Float128,2,2)

H0 = dlopen(string("./test_form_float128.", dlext))
H = dlsym(H0, "eval_form")
fj! = (F,J,x,p) -> ccall(H, Nothing, (Ptr{Float128}, Ptr{Float128}, Ptr{Float128}, Ptr{Float128}), F, J, x, p)

fj!(F,J,x,p)

println("F=",F)
println("J=",J)

F1= [ 1//3*x[1]+x[2]^7-p[1], 2*x[1]+2*x[2]-p[2] ]
println("F1=",F1)


# 4. __complex128 ############################################

run(`gcc -O1 -fPIC -shared -DCOMPLEX128 -o test_form_complex128.so test_form.c -lquadmath`)

using Quadmath

x=Complex{Float128}[2+1im, 3-2im]
p=Complex{Float128}[-1+3im,4-1im]
F=zeros(Complex{Float128}, 2)
J=zeros(Complex{Float128}, 2,2)

H0 = dlopen(string("./test_form_complex128.", dlext))
H = dlsym(H0, "eval_form")
fj! = (F,J,x,p) -> ccall(H, Nothing, (Ptr{Complex{Float128}}, Ptr{Complex{Float128}}, 
                                   Ptr{Complex{Float128}}, Ptr{Complex{Float128}}), F, J, x, p)

fj!(F,J,x,p)

println("F=",F)
println("J=",J)

F1= [ 1//3*x[1]+x[2]^7-p[1], 2*x[1]+2*x[2]-p[2] ]
println("F1=",F1)


