"=== mlp: BEGIN ../std/loops.mlp =============================================="

var while (cond, do):{
    var loop _
    loop := ():{
        cond() && {
            do()
            _ := loop()
        }
        ;
    }
    loop()
}

var until (cond, do):{
    var loop _
    loop := ():{
        cond() || {
            do()
            _ := loop()
        }
        ;
    }
    loop()
}

var do_while (do, cond):{
    do()
    while(cond, do)
}

var do_until (do, cond):{
    do()
    until(cond, do)
}

var foreach (OUT container, fn):{
    var nth 1
    until(():{nth > len(container)}, ():{
        fn(&container[#nth])
        nth += 1
    })
    container
}

"=== mlp: END ../std/loops.mlp (finally back to io.mlp) ======================="

var putline (x):{
    print(x)
}

var getlines ():{
    var lines []
    var line getline()
    until(():{line == $nil}, ():{
        lines += [line]
        line := getline()
    })
    lines
}

var stdin ():{
    slurpfile("/dev/stdin")
}

var stdout print

"package main"

print("io.mlp")
