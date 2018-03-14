module FORM

export call_form, compile_f, compile_fg, compile_fj

function call_form(input::String; threads=1)
    attempts = 0
    FORM_PID=0
    path = joinpath(dirname(@__FILE__), "../deps/bin")
    out = "Error initializing preset external channels\n"
    while out == "Error initializing preset external channels\n" 
        (so,si,pr) = readandwrite(`$path/tform -w$(threads) -t /tmp -M  -q -pipe 0,1 $path/pipe.frm`)
        FORM_PID = readuntil(so,'\n')[1:end-1];
        print(si, FORM_PID,',',getpid(),"\n\n", input,"\n\n")
        close(si)
        out = readstring(so)
        close(si)
        close(so)
        close(pr)
        attempts +=1
    end
    println(STDERR, "# of attemps to call form = ",attempts)
    try 
        rm("/tmp/xform$FORM_PID.str") # delete generated temporary file
    end    
    out
end


function compile_f(fun, n::Integer; threads=1)
    fun = string(fun)
    fun = replace(replace(fun,"[", "("), "]", ")")
    input = string("""
Off Statistics;
V x;
""","Local f0 = ",
    fun,
    ";\n",
"""
#write <> "begin"
Print;
Format O3;
Format maple;
.sort;
#write <> "  return f0"
#write <> "end"
.end
""")
    out = call_form(input, threads=threads)
    out = replace(replace(out,"(", "["), ")", "]")    
    eval(parse(string("x->",out)))
end

function compile_f(fun, vars::Vector; threads=1)
    fun = string(fun)
    n = length(vars)
    for j=1:n
        rep = string(vars[j])
        by  = string("x(",j,")")
        fun = replace(fun, rep, by)
    end
    compile_f(fun, n, threads=threads)
end


function compile_fg(fun, n::Integer; threads=1)
    fun = string(fun)
    fun = replace(replace(fun,"[", "("), "]", ")")
    input = string("""
Off Statistics;
V x;
S u;
""","Local f0 = ",
    fun,
    ";\n",
"""
#write <> "begin"
#write <> "  if g==nothing"
Print;
Format O3;
Format maple;
.sort;
#write <> "    return f0"
#write <> "  else"
I i;
S m, xx, u;
Hide f0;
#do i=1,$(n)
    Local f'i' = f0;
    id x('i') = xx;
    id xx^m? = m*xx^(m-1);
    id xx = x('i');
    .sort
    Hide f'i';
#enddo
.sort;
""","Local H = ",
    join(["u^$(j+1)*f$(j)" for j=0:n],:+),
    ";\n",
"""
B u;
.sort
#optimize H
B u;
.sort
""",
    join(["Local F$(j) = H[u^$(j+1)];\n" for j=0:n], ""),
"""
.sort
#write <> "%4O",
""", "#write <> \"\n   f=%e   ",
join(["g($(j))=%e" for j=1:n],"    "),
"\", ",
join(["F$(j)" for j=0:n],","),"\n",
"""
#write <> "    return f"
#write <> "  end"
#write <> "end"
.end
""")
    out = call_form(input, threads=threads)
    out = replace(replace(out,"(", "["), ")", "]")    
    eval(parse(string("(x,g)->",out)))
end    

function compile_fg(fun, vars::Vector; threads=1)
    fun = string(fun)
    n = length(vars)
    for j=1:n
        rep = string(vars[j])
        by  = string("x(",j,")")
        fun = replace(fun, rep, by)
    end
    compile_fg(fun, n, threads=threads)
end


function compile_fj(funs::Vector, n::Integer; threads=1, opt::String="O2")
    m = length(funs)
    funs = [replace(replace(string(fun),"[", "("), "]", ")") for fun in funs]
    input = string("""
Off Statistics;
Format $(opt);
V x;
#define m "$(m)"
#define n "$(n)"
""",
join(["Local f$(j) = $(funs[j]);\n" for j=1:m]),
"""
#write <> "begin"
#write <> "  if J==nothing"
.sort;
I i, j;
S u, v;
Local H = 
#do i=1,'m'
    +u^'i'*f'i' 
#enddo
;
B u;
.sort
#optimize H
B u;
.sort
#do i=1,'m'
    Local F'i'   = H[u^'i'];
#enddo
.sort
#write <> "%O"
#do i=1,'m'
#write <> "      F('i')=%e", F'i'
#enddo
#write <> "  else"
.sort;
S k, xx;
#do i=1,'m'
Hide f'i';
#enddo
#do i=1,'m'
#do j=1,'n'
    Local j'i'j'j' = f'i';
    id x('j') = xx;
    id xx^k? = k*xx^(k-1);
    id xx = x('j');
    .sort
    Hide j'i'j'j';
#enddo
#enddo
.sort
Local H = 
#do i=1,'m'
    +u^'i'*v^0*f'i' 
#do j=1,'n'
    +u^'i'*v^'j'*j'i'j'j'
#enddo
#enddo
;
B u, v;
.sort
#optimize H
B u,v;
.sort
#do i=1,'m'
    Local F'i'   = H[u^'i'*v^0];
#do j=1,'n'
    Local J'i'J'j' = H[u^'i'*v^'j'];
#enddo
#enddo
.sort
#write <> "%O"
#write <> "    if F!=nothing"
#do i=1,'m'
#write <> "      F('i')=%e", F'i'
#enddo
#write <> "    end"
#do i=1,'m'
#do j=1,'n'
#write <> "      J('i','j')=%e", J'i'J'j'
#enddo
#enddo
#write <> "  end"
#write <> "end"
.end
""")
    out = call_form(input, threads=threads)
    out = replace(replace(out,"(", "["), ")", "]")    
    eval(parse(string("(F,J,x)->",out)))
end    


function compile_fj(funs::Vector, vars::Vector; threads=1, opt::String="O2")
    m = length(funs)
    n = length(vars)
    funs=[string(fun) for fun in funs]
    for j=1:n
        rep = string(vars[j])
        by  = string("x(",j,")")
        for i=1:m
            funs[i] = replace(funs[i], rep, by)
        end
    end
    compile_fj(funs, n, threads=threads, opt=opt)
end


end # module FORM
