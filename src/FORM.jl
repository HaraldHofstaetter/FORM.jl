module FORM

export call_form, compile_f, compile_fg, compile_fj
export call_form_to_c, compile_f_to_c, compile_fg_to_c, compile_fj_to_c 


function call_form(input::String; threads=1, keep_files::Bool=false)
    path = joinpath(dirname(@__FILE__), "../deps/bin")
    tdir = tempdir()
    tmp = tempname()
    input_file = string(tmp, ".frm")
    output_file = string(tmp, ".out")
    open(input_file, "w") do f
        write(f, input)
    end
    run(pipeline(`$(path)/tform -w$(threads) -t $(tdir) -q $(input_file) `, stdout=output_file))
    output = join(readlines(output_file),'\n')
    if !keep_files
        rm(input_file) 
        rm(output_file) 
    end
    output
end    

    
function compile_f(fun, n::Integer; parameters::Bool=false, threads=1, opt::String="O2", keep_files::Bool=false)
    fun = string(fun)
    fun = replace(replace(fun,"[" => "("), "]" => ")")
    input = string("""
Off Statistics;
Format $(opt);
V x;
V p;
Local F = $(fun); 
#write <> "begin"
Print;
.sort;
#write <> "  return F"
#write <> "end"
.end
""")
    out = call_form(input, threads=threads)
    out = replace(replace(out,"(" => "["), ")" => "]")    
    if parameters
        eval(Meta.parse(string("(x,p)->",out)))
    else
        eval(Meta.parse(string("x->",out)))
    end
end

function compile_f(fun, vars::Vector; pars::Vector=[], threads=1, opt::String="O2", keep_files::Bool=false)
    fun = string(fun)
    n = length(vars)
    for j=1:n
        rep = string(vars[j])
        by  = string("x(",j,")")
        fun = replace(fun, rep => by)
    end
    for j=1:length(pars)
        rep = string(pars[j])
        by  = string("p(",j,")")
        fun = replace(fun, rep => by)
    end
    compile_f(fun, n,  parameters=length(pars)>0, threads=threads, opt=opt, keep_files=keep_files)
end


function compile_fg(fun, n::Integer; parameters::Bool=false, threads=1, opt::String="O2", keep_files::Bool=false)
    fun = string(fun)
    fun = replace(replace(fun,"[" => "("), "]" => ")")
    input = string("""
Off Statistics;
Format $(opt);
V x;
V p;
S u;
#define n "$(n)"
Local F = $(fun);
#write <> "begin"
#write <> "  if G==nothing"
Print;
.sort;
#write <> "    return F"
#write <> "  else"
I i;
S m, xx, u;
Hide F;
#do i=1,'n'
    Local G'i' = F;
    id x('i') = xx;
    id xx^m? = m*xx^(m-1);
    id xx = x('i');
    .sort
    Hide G'i';
#enddo
.sort;
I i;
Local H = u^0*F 
#do i=1,'n'
     +u^'i'*G'i'
#enddo     
;
B u;
.sort
#optimize H
B u;
.sort
Local FF = H[u^0];
#do i=1,'n'
    Local GG'i'   = H[u^'i'];
#enddo    
.sort
#write <> "%O"
#do i=1,'n'
#write <> "      G('i')=%e", GG'i'
#enddo    
#write <> "      return %e", FF
#write <> "  end"
#write <> "end"
.end
""")
    out = call_form(input, threads=threads, keep_files=keep_files)
    out = replace(replace(out,"(" => "["), ")" => "]")    
    if parameters
        eval(Meta.parse(string("(G,x,p)->",out)))
    else
        eval(Meta.parse(string("(G,x)->",out)))
    end
end    

function compile_fg(fun, vars::Vector; pars::Vector=[], threads=1, opt::String="O2", keep_files::Bool=false)
    fun = string(fun)
    n = length(vars)
    for j=1:n
        rep = string(vars[j])
        by  = string("x(",j,")")
        fun = replace(fun, rep => by)
    end
    for j=1:length(pars)
        rep = string(pars[j])
        by  = string("p(",j,")")
        fun = replace(fun, rep => by)
    end
    compile_fg(fun, n, parameters=length(pars)>0, threads=threads, opt=opt, keep_files=keep_files)
end


function compile_fj(funs::Vector, n::Integer;  parameters::Bool=false, threads=1, opt::String="O2", keep_files::Bool=false)
    m = length(funs)
    funs = [replace(replace(string(fun),"[" => "("), "]" => ")") for fun in funs]
    input = string("""
Off Statistics;
Format $(opt);
V x;
V p;
#define m "$(m)"
#define n "$(n)"
""",
join(["Local F$(j) = $(funs[j]);\n" for j=1:m]),
"""
#write <> "begin"
#write <> "  if J==nothing"
.sort;
I i, j;
S u, v;
Local H = 
#do i=1,'m'
    +u^'i'*F'i' 
#enddo
;
B u;
.sort
#optimize H
B u;
.sort
#do i=1,'m'
    Local FF'i'   = H[u^'i'];
#enddo
.sort
#write <> "%O"
#do i=1,'m'
#write <> "      F('i')=%e", FF'i'
#enddo
#write <> "  else"
.sort;
S k, xx;
#do i=1,'m'
Hide F'i';
#enddo
#do i=1,'m'
#do j=1,'n'
    Local J'i'J'j' = F'i';
    id x('j') = xx;
    id xx^k? = k*xx^(k-1);
    id xx = x('j');
    .sort
    Hide J'i'J'j';
#enddo
#enddo
.sort
Local H = 
#do i=1,'m'
    +u^'i'*v^0*F'i' 
#do j=1,'n'
    +u^'i'*v^'j'*J'i'J'j'
#enddo
#enddo
;
B u, v;
.sort
#optimize H
B u,v;
.sort
#do i=1,'m'
    Local FF'i'   = H[u^'i'*v^0];
#do j=1,'n'
    Local JJ'i'J'j' = H[u^'i'*v^'j'];
#enddo
#enddo
.sort
#write <> "%O"
#write <> "    if F!=nothing"
#do i=1,'m'
#write <> "      F('i')=%e", FF'i'
#enddo
#write <> "    end"
#do i=1,'m'
#do j=1,'n'
#write <> "      J('i','j')=%e", JJ'i'J'j'
#enddo
#enddo
#write <> "  end"
#write <> "end"
.end
""")
    out = call_form(input, threads=threads, keep_files=keep_files)
    out = replace(replace(out,"(" => "["), ")" => "]")    
    if parameters
        eval(Meta.parse(string("(F,J,x,p)->",out)))
    else
        eval(Meta.parse(string("(F,J,x)->",out)))
    end
end    


function compile_fj(funs::Vector, vars::Vector; pars::Vector=[], threads=1, opt::String="O2", keep_files::Bool=false)
    m = length(funs)
    n = length(vars)
    funs=[string(fun) for fun in funs]
    for j=1:n
        rep = string(vars[j])
        by  = string("x(",j,")")
        for i=1:m
            funs[i] = replace(funs[i], rep => by)
        end
    end
    for j=1:length(pars)
        rep = string(pars[j])
        by  = string("p(",j,")")
        for i=1:m
            funs[i] = replace(funs[i], rep => by)
        end
    end
    compile_fj(funs, n, parameters=length(pars)>0, threads=threads, opt=opt, keep_files=keep_files)
end


########################################################################################


function call_form_to_c(input::String, output_file::String; threads=1, 
                        keep_files::Bool=false, sed_cmd::String="")
    path = joinpath(dirname(@__FILE__), "../deps/bin")
    tdir = tempdir()
    tmp = tempname()
    input_file = string(tmp, ".frm")
    open(input_file, "w") do f
        write(f, input)
    end
    # with "Format C",  assignments of type =x[..] or =p[..] are not correctly
    # handled, we use sed to correct the output of form.
    sed_cmd = string(raw"s/=\([x|p]\)(\([0-9]*\))/=\1[\2-1]/;", sed_cmd)
    run(pipeline(`$(path)/tform -w$(threads) -t $(tdir) -q $(input_file)`, 
                 `sed $(sed_cmd)`, 
                 output_file))
    if !keep_files
        rm(input_file) 
    end
end    


_default_opening = """
#if defined(COMPLEX)                
#  define __number_type__ double complex
#elif defined(FLOAT128)
#  define __number_type__ __float128 
#elif defined(COMPLEX128)
#  define __number_type__ __complex128 
#else
#  define __number_type__ double 
#endif

static __number_type__ pow(__number_type__ base, int exp)
{
    __number_type__ result = 1.0;
    for (;;)
    {
        if (exp & 1)
            result *= base;
        exp >>= 1;
        if (!exp)
            break;
        base *= base;
    }
    return result;
}
"""


function compile_f_to_c(fun, n::Integer, output_file::String; 
                        fun_name::String="eval_form", number_type::String="double",
                        opening::String="#include<math.h>",
                        parameters::Bool=false, sed_cmd::String="",
                        threads=1, opt::String="O2", keep_files::Bool=false)
    fun = string(fun)
    fun = replace(replace(fun,"[" => "("), "]" => ")")
    input = string("""
Off Statistics;
Format $(opt);
Format C;
V x;
V p;
Local F = $(fun); 
.sort
#optimize F
Format C;
""",
join(["#write <> \"$(l)\"\n" for l in split(opening,'\n')]),
"""
#write <> "$(number_type) $(fun_name)($(number_type) x[], $(number_type) p[])"
#write <> "{"
#do i=1,'optimmaxvar_'
#write<> "    $(number_type) Z'i'_;"
#enddo
#write <> "%O"
#write <> "    return %e", F
#write <> "}"
.end
    """)
    call_form_to_c(input, output_file, threads=threads, keep_files=keep_files, sed_cmd=sed_cmd)
end


function compile_f_to_c(fun, vars::Vector, output_file::String; pars::Vector=[], 
                         fun_name::String="eval_form",
                         threads=1, opt::String="O2", keep_files::Bool=false)
    n = length(vars)
    fun = string(fun)
    for j=1:n
        rep = string(vars[j])
        by  = string("x(",j,")")
        fun = replace(fun, rep => by)
    end
    for j=1:length(pars)
        rep = string(pars[j])
        by  = string("p(",j,")")
        fun = replace(fun, rep => by)
    end

    compile_f_to_c(fun, n, output_file, parameters=length(pars)>0, 
                   fun_name=fun_name, threads=threads, opt=opt, keep_files=keep_files,
                   number_type="__number_type__",
                   sed_cmd=raw"s/\([0-9]*\)\.\/\([0-9]*\)\./\1.q\/\2.q/g;s/pow(/ipow(/g",
                   opening=_default_opening)
end


function compile_fg_to_c(fun, n::Integer, output_file::String; 
                        fun_name::String="eval_form", number_type::String="double",
                        opening::String="#include<math.h>",
                        parameters::Bool=false, sed_cmd::String="",
                        threads=1, opt::String="O2", keep_files::Bool=false)
    fun = string(fun)
    fun = replace(replace(fun,"[" => "("), "]" => ")")
    input = string("""
Off Statistics;
Format $(opt);
Format C;
V x;
V p;
S u;
#define n "$(n)"
Local F = $(fun);
.sort;
I i;
S m, xx, u;
Hide F;
#do i=1,'n'
    Local G'i' = F;
    id x('i') = xx;
    id xx^m? = m*xx^(m-1);
    id xx = x('i');
    .sort
    Hide G'i';
#enddo
.sort;
I i;
Local H = u^0*F 
#do i=1,'n'
     +u^'i'*G'i'
#enddo     
;
B u;
.sort
#optimize H
B u;
.sort
Local FF = H[u^0];
#do i=1,'n'
    Local GG'i'   = H[u^'i'];
#enddo    
.sort
Format C;
""",

join(["#write <> \"$(l)\"\n" for l in split(opening,'\n')]),
"""
#write <> "$(number_type) $(fun_name)($(number_type) G['n'],"
#write <> "                           $(number_type) x['n'], $(number_type) p[])"
#write <> "{"
#do i=1,'optimmaxvar_'
#write <> "   $(number_type) Z'i'_;"
#enddo
#write <> "%O"
#write <> "   if (G!=0) {"
#do i=1,'n'
#write <> "       G['i'-1]=%e", GG'i'
#enddo    
#write <> "   }"
#write <> "   return %e", FF
#write <> "}"
.end
""")
    call_form_to_c(input, output_file, threads=threads, keep_files=keep_files, sed_cmd=sed_cmd)
end


function compile_fg_to_c(fun, vars::Vector, output_file::String; pars::Vector=[], 
                         fun_name::String="eval_form",
                         threads=1, opt::String="O2", keep_files::Bool=false)
    n = length(vars)
    fun = string(fun)
    for j=1:n
        rep = string(vars[j])
        by  = string("x(",j,")")
        fun = replace(fun, rep => by)
    end
    for j=1:length(pars)
        rep = string(pars[j])
        by  = string("p(",j,")")
        fun = replace(fun, rep => by)
    end

    compile_fg_to_c(fun, n, output_file, parameters=length(pars)>0, 
                    fun_name=fun_name, threads=threads, opt=opt, keep_files=keep_files,
                    number_type="__number_type__",
                    sed_cmd=raw"s/\([0-9]*\)\.\/\([0-9]*\)\./\1.q\/\2.q/g;s/pow(/ipow(/g",
                    opening=_default_opening)
end


function compile_fj_to_c(funs::Vector, n::Integer, output_file::String; 
                         fun_name::String="eval_form", number_type::String="double",
                         opening::String="#include<math.h>",
                         parameters::Bool=false, sed_cmd::String="",
                         threads=1, opt::String="O2", keep_files::Bool=false)
    m = length(funs)
    funs = [replace(replace(string(fun),"[" => "("), "]" => ")") for fun in funs]
    input = string("""
Off Statistics;
Format $(opt);
Format C;
V x;
V p;
#define m "$(m)"
#define n "$(n)"
""",
join(["Local F$(j) = $(funs[j]);\n" for j=1:m]),
"""
.sort;
I i, j;
S u, v;
S k, xx;
#do i=1,'m'
Hide F'i';
#enddo
#do i=1,'m'
#do j=1,'n'
    Local J'i'J'j' = F'i';
    id x('j') = xx;
    id xx^k? = k*xx^(k-1);
    id xx = x('j');
    .sort
    Hide J'i'J'j';
#enddo
#enddo
.sort
Local H = 
#do i=1,'m'
    +u^'i'*v^0*F'i' 
#do j=1,'n'
    +u^'i'*v^'j'*J'i'J'j'
#enddo
#enddo
;
B u, v;
.sort
#optimize H
B u,v;
.sort
#do i=1,'m'
    Local FF'i'   = H[u^'i'*v^0];
#do j=1,'n'
    Local JJ'i'J'j' = H[u^'i'*v^'j'];
#enddo
#enddo
.sort
Format C;
""",
join(["#write <> \"$(l)\"\n" for l in split(opening,'\n')]),
"""
#write <> "void $(fun_name)($(number_type) F['m'], $(number_type) J['n']['m'],"
#write <> "                 $(number_type) x['n'], $(number_type) p[])"
#write <> "{"
#do i=1,'optimmaxvar_'
#write<> "    $(number_type) Z'i'_;"
#enddo
#write <> "%O"
#write <> "   if (F!=0) {"
#do i=1,'m'
#write <> "       F[{'i'-1}]=%e", FF'i'
#enddo
#write <> "   }"
#write <> "   if (J!=0) {"
#do i=1,'m'
#do j=1,'n'
#write <> "       J[{'j'-1}][{'i'-1}]=%e", JJ'i'J'j'
#enddo
#enddo
#write <> "   }"
#write <> "}"
.end
    """)
    call_form_to_c(input, output_file, threads=threads, keep_files=keep_files, sed_cmd=sed_cmd)
end


function compile_fj_to_c(funs::Vector, vars::Vector, output_file::String; pars::Vector=[], 
                         fun_name::String="eval_form",
                         threads=1, opt::String="O2", keep_files::Bool=false)
    m = length(funs)
    n = length(vars)
    funs=[string(fun) for fun in funs]
    for j=1:n
        rep = string(vars[j])
        by  = string("x(",j,")")
        for i=1:m
            funs[i] = replace(funs[i], rep => by)
        end
    end
    for j=1:length(pars)
        rep = string(pars[j])
        by  = string("p(",j,")")
        for i=1:m
            funs[i] = replace(funs[i], rep => by)
        end
    end

    compile_fj_to_c(funs, n, output_file, parameters=length(pars)>0, 
                    fun_name=fun_name, threads=threads, opt=opt, keep_files=keep_files,
                    number_type="__number_type__",
                    sed_cmd=raw"s/\([0-9]*\)\.\/\([0-9]*\)\./\1.q\/\2.q/g;s/pow(/ipow(/g",
                    opening=_default_opening)
end


end # module FORM
