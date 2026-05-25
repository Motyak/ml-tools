"=== mlp: BEGIN ../std/cond.mlp ==============================================="

var tern (cond, if_true, if_false):{
    var res _
    cond && {res := if_true}
    cond || {res := if_false}
    res
}

var !tern (cond, if_false, if_true):{
    tern(cond, if_true, if_false)
}

var not (bool):{
    tern(bool, $false, $true)
}

```
    tern should ALWAYS be considered before
    deciding to use a CaseAnalysis,
    as tern is easier to read and suits most situtations.

    On the other hand, CaseAnalysis is very powerful but
    require you to define an additional variable
    (two of them if you need to store a result)
```
var CaseAnalysis ():{
    var end $false
    var fn (cond, do):{
        end == $nil && {
            die("additional case succeeding a fallthrough case")
        }
        end ||= cond && {
            _ := do
            $true
        }
        "NOTE: don't eval cond if end"
        end == $false && cond == $nil && {
            _ := do
            end := $nil
        }
        ;
    }
    fn
}

"=== mlp: END ../std/cond.mlp (finally back to LazyList.mlp) =================="
"=== mlp: BEGIN ../std/Optional.mlp ==========================================="


var Optional (some?, val):{
    var none? ():{
        not(some?)
    }

    var some ():{
        some? || {
            die("calling some() on empty Optional")
        }
        val
    }

    var dispatcher (op):{
        tern(op == 'none?, none?, {
            tern(op == 'some, some, {
                die("unknown Optional operation: `" + op + "`")
            })
        })
    }
    dispatcher
}

var none? (opt):{
    opt('none?)()
}

var some (opt):{
    opt('some)()
}

"=== mlp: END ../std/Optional.mlp (finally back to LazyList.mlp) =============="

"=== PAIR ============================="

var Pair (left, right):{
    var selector (op):{
        tern(op == 'left, left, {
            tern(op == 'right, right, {
                die("unknown Pair operation: `" + op + "`")
            })
        })
    }
    selector
}

var left (pair):{
    pair('left)
}

var right (pair):{
    pair('right)
}

"=== LAZYLIST ========================="

var Pair? (left, right):{
    Optional($true, Pair(left, right))
}

var END {
    Optional($false, _)
}

var LazyList {
    var LazyList-1+ _

    var LazyList (xs...):{
        tern($#varargs == 0, END, {
            LazyList-1+(xs...)
        })
    }

    LazyList-1+ := (x, xs...):{
        Pair?(x, LazyList(xs...))
    }

    LazyList
}

"package main"

print("LazyList.mlp")
