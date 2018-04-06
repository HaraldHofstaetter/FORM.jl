using FORM

# 1. double ###############################################

compile_fj_to_c(["1/3*x1+x2^7-p1", "2*x1+2*x2-p2"], ["x1", "x2"], 
                "test_form_double.c", pars=["p1", "p2"])
run(`gcc -O1 -fPIC -shared -o test_form_double.so test_form_double.c`)
x=[2.0, 3.0]
p=[-1.0,4.0]
F=zeros(2)
J=zeros(2,2)

H0 = Libdl.dlopen(string("test_form_double.", Libdl.dlext))
H = Libdl.dlsym(H0, "eval_form")
fj! = (F,J,x,p) -> ccall(H, Void, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble},Ptr{Cdouble}), F, J, x, p)

fj!(F,J,x,p)

println("F=",F)
println("J=",J)

F1= [ 1/3*x[1]+x[2]^7-p[1], 2*x[1]+2*x[2]-p[2] ]
println("F1=",F1)


# 2. double complex ########################################

compile_fj_to_c(["1/3*x1+x2^7-p1", "2*x1+2*x2-p2"], ["x1", "x2"], 
                "test_form_complex.c", pars=["p1", "p2"],
                number_type="double complex",
                opening="#include<complex.h>\n#define pow cpow")
run(`gcc -O1 -fPIC -shared -o test_form_complex.so test_form_complex.c -lm`)

x=[2.0+1im, 3.0-2im]
p=[-1.0+3im,4.0-1im]
F=zeros(Complex{Float64}, 2)
J=zeros(Complex{Float64}, 2,2)

H0 = Libdl.dlopen(string("test_form_complex.", Libdl.dlext))
H = Libdl.dlsym(H0, "eval_form")
fj! = (F,J,x,p) -> ccall(H, Void, (Ptr{Complex{Cdouble}}, Ptr{Complex{Cdouble}}, 
                                   Ptr{Complex{Cdouble}}, Ptr{Complex{Cdouble}}), F, J, x, p)
fj!(F,J,x,p)

println("F=",F)
println("J=",J)

F1= [ 1/3*x[1]+x[2]^7-p[1], 2*x[1]+2*x[2]-p[2] ]
println("F1=",F1)


# 3. __float128 ############################################

compile_fj_to_c(["1/3*x1+x2^7-p1", "2*x1+2*x2-p2"], ["x1", "x2"], 
                "test_form_float128.c", pars=["p1", "p2"],
                number_type="__float128",
                opening="#include<quadmath.h>\n#define pow powq",
                sed_cmd=raw"s/\([0-9]*\)\.\/\([0-9]*\)\./\1.q\/\2.q/"
               )
run(`gcc -O1 -fPIC -shared -o test_form_float128.so test_form_float128.c -lquadmath`)

using Quadmath


x=Float128[2, 3]
p=Float128[-1,4]
F=zeros(Float128,2)
J=zeros(Float128,2,2)

H0 = Libdl.dlopen(string("test_form_float128.", Libdl.dlext))
H = Libdl.dlsym(H0, "eval_form")
fj! = (F,J,x,p) -> ccall(H, Void, (Ptr{Float128}, Ptr{Float128}, Ptr{Float128},Ptr{Float128}), F, J, x, p)
fj!(F,J,x,p)

println("F=",F)
println("J=",J)

F1= [ 1//3*x[1]+x[2]^7-p[1], 2*x[1]+2*x[2]-p[2] ]
println("F1=",F1)


# 4. __complex128 ############################################

compile_fj_to_c(["1/3*x1+x2^7-p1", "2*x1+2*x2-p2"], ["x1", "x2"], 
                "test_form_complex128.c", pars=["p1", "p2"],
                number_type="__complex128",
                opening="#include<quadmath.h>\n#define pow cpowq",
                sed_cmd=raw"s/\([0-9]*\)\.\/\([0-9]*\)\./\1.q\/\2.q/"
               )
run(`gcc -O1 -fPIC -shared -o test_form_complex128.so test_form_complex128.c -lquadmath`)

using Quadmath

x=Complex{Float128}[2+1im, 3-2im]
p=Complex{Float128}[-1+3im,4-1im]
F=zeros(Complex{Float128}, 2)
J=zeros(Complex{Float128}, 2,2)

H0 = Libdl.dlopen(string("test_form_complex128.", Libdl.dlext))
H = Libdl.dlsym(H0, "eval_form")
fj! = (F,J,x,p) -> ccall(H, Void, (Ptr{Complex{Float128}}, Ptr{Complex{Float128}}, 
                                   Ptr{Complex{Float128}}, Ptr{Complex{Float128}}), F, J, x, p)
fj!(F,J,x,p)

println("F=",F)
println("J=",J)

F1= [ 1//3*x[1]+x[2]^7-p[1], 2*x[1]+2*x[2]-p[2] ]
println("F1=",F1)


