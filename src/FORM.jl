module FORM

export call_form, compile_f, compile_fg 

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
#write <> "  if length(g)==0"
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
    out = replace(out,"length[g]", "length(g)")
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


end # module FORM
