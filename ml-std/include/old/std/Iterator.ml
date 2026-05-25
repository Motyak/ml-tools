"=== mlp: BEGIN ./std/cond.mlp ================================================"

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

"=== mlp: END ./std/cond.mlp (finally back to std/Iterator.mlp) ==============="
"=== mlp: BEGIN ./std/loops.mlp ==============================================="

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

"=== mlp: END ./std/loops.mlp (finally back to std/Iterator.mlp) =============="

"=== mlp: BEGIN ./std/Optional.mlp ============================================"


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

"=== mlp: END ./std/Optional.mlp (finally back to std/Iterator.mlp) ==========="
"=== mlp: BEGIN ./std/LazyList.mlp ============================================"


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

"=== mlp: END ./std/LazyList.mlp (finally back to std/Iterator.mlp) ==========="

var Some (x):{
    Optional($true, x)
}

var Iterator (subscriptable):{
    var Iterator (container):{
        container
        var nth 1
        var next (peek?):{
            tern(nth > len(container), END, {
                var res container[#nth]
                peek? || {nth += 1}
                Some(res)
            })
        }
        next
    }

    var Iterator::fromStream (stream):{
        stream
        var next (peek?):{
            tern(none?(stream), END, {
                var res left(some(stream))
                peek? || {
                    stream := right(some(stream))
                }
                Some(res)
            })
        }
        next
    }

    var lambda? (x):{
        $type(x) == 'Lambda
    }
    
    var next {
        !tern(lambda?(subscriptable), Iterator(subscriptable), {
            Iterator::fromStream(subscriptable)
        })
    }

    var dispatcher (op):{
        tern(op == 'next, ():{next(0)}, {
            tern(op == 'peek, ():{next(1)}, {
                die("unknown iterator operation: `" + op + "`")
            })
        })
    }
    dispatcher
}

var ArgIterator (args...):{
    Iterator(LazyList(args...))
}

var SeqIterator (init, stop?, update):{
    var curr init

    var peek ():{
        Some(curr)
    }

    var next _
    next := ():{
        peek := ():{
            tern(stop?(curr), END, Some(curr))
        }
        next := ():{
            update(&curr)
            tern(stop?(curr), END, Some(curr))
        }
        Some(curr)
    }

    var dispatcher (op):{
        tern(op == 'peek, peek, {
            tern(op == 'next, next, {
                die("unknown SeqIterator operation: `" + op + "`")
            })
        })
    }
    dispatcher
}

var RangeIterator<= (from, to):{
    {
        "accepts as input Int, Char or Str"
        var str? (x):{
            $type(x) == 'Str
        }
        var charInputs? {
            var charInputs? $true
            charInputs? &&= str?(from) && len(from) == 1
            charInputs? &&= str?(to) && len(to) == 1
            charInputs?
        }
        from := tern(charInputs?, Char, Int)(from)
        to := tern(charInputs?, Char, Int)(to)
    }
    var >= (a, b):{
        a > b || a == b
    }
    var RangeIterator<= {
        var i from
        var stop? (i):{i > to}
        var update (i):{i += 1}
        SeqIterator(i, stop?, update)
    }
    RangeIterator<=
}

var peek (iterator):{
    iterator('peek)()
}

var next (iterator):{
    iterator('next)()
}

-- augment foreach() from loops.mlp
{
    var Container::foreach foreach

    foreach := (OUT iterable, fn):{
        var Iterator::foreach (iterator, fn):{
            var curr next(iterator)
            until(():{none?(curr)}, ():{
                fn(some(curr))
                curr := next(iterator)
            })
        }

        var lambda? (x):{
            $type(x) == 'Lambda
        }
        tern(lambda?(iterable), Iterator::foreach(iterable, fn), {
            Container::foreach(&iterable, fn)
        })
    }
}

"package main"

print("Iterator.mlp")
